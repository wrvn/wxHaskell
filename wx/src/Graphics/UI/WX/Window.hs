{-# OPTIONS -fglasgow-exts #-}
--------------------------------------------------------------------------------
{-| Module      :  Window
    Copyright   :  (c) Daan Leijen 2003
    License     :  wxWindows

    Maintainer  :  daan@cs.uu.nl
    Stability   :  provisional
    Portability :  portable

    Exports default instances for generic windows.
-}
--------------------------------------------------------------------------------
module Graphics.UI.WX.Window
        ( -- * Window
          Window 
          -- * ScrolledWindow
        , ScrolledWindow, scrolledWindow, scrollRate
        ) where

-- import selectively to circumvent bug in haddock
-- import Graphics.UI.WXCore
import Graphics.UI.WXCore.WxcClasses
import Graphics.UI.WXCore.WxcClassTypes
import Graphics.UI.WXCore.WxcDefs
import Graphics.UI.WXCore.Draw
import Graphics.UI.WXCore.Events

import Graphics.UI.WX.Types
import Graphics.UI.WX.Attributes
import Graphics.UI.WX.Layout
import Graphics.UI.WX.Classes
import Graphics.UI.WX.Events

{--------------------------------------------------------------------------------
  ScrolledWindow
--------------------------------------------------------------------------------}
-- | A scrollable window. Use 'virtualSize' and 'scrollRate' to set the scrollbar
-- behaviour.
scrolledWindow :: Window a -> [Prop (ScrolledWindow ())] -> IO (ScrolledWindow ())
scrolledWindow parent props
  = do sw <- scrolledWindowCreate parent idAny rectNull 
              (wxNO_FULL_REPAINT_ON_RESIZE .+. wxCLIP_CHILDREN)
       set sw props
       return sw


-- | The horizontal and vertical scroll rate of scrolled window. Use @0@ to disable 
-- scrolling in that direction.
scrollRate :: Attr (ScrolledWindow a) Size
scrollRate
  = newAttr "scrollRate" getter setter
  where
    getter sw
      = do p <- scrolledWindowGetScrollPixelsPerUnit sw
           return (sizeFromPoint p)
     
    setter sw size
      = scrolledWindowSetScrollRate sw (sizeW size) (sizeH size)

{--------------------------------------------------------------------------------
  Properties
--------------------------------------------------------------------------------}
instance Able (Window a) where
  enable
    = newAttr "enable" windowIsEnabled setter
    where
      setter w enable
        | enable    = unitIO $ windowEnable w
        | otherwise = unitIO $ windowDisable w


instance Textual (Window a) where
  text
    = newAttr "text" getter setter
    where
      getter w
        = fst (getset w)
      setter w x
        = snd (getset w) x

      getset w
        = ifInstanceOf w classComboBox
            (\cb -> (comboBoxGetValue cb, \s -> do comboBoxClear cb; comboBoxAppend cb s)) $
          ifInstanceOf w classTextCtrl
            (\tc -> (textCtrlGetValue tc, \s -> do textCtrlClear tc; textCtrlWriteText tc s)) $
            (windowGetLabel w,windowSetLabel w)

  appendText w s
    = ifInstanceOf w classComboBox
        (\cb -> comboBoxAppend cb s) $
      ifInstanceOf w classTextCtrl
        (\tc -> textCtrlAppendText tc s)
        (set w [text :~ (++s)])


instance Dimensions (Window a) where
  outerSize
    = newAttr "size" windowGetSize setSize
    where
      setSize w sz
        = windowSetSize w (rect (pt (-1) (-1)) sz) wxSIZE_USE_EXISTING

  area
    = newAttr "area" windowGetRect setArea
    where
      setArea w rect
        = windowSetSize w rect wxSIZE_USE_EXISTING

  bestSize
    = readAttr "bestSize" windowGetBestSize

  position
    = newAttr "position" windowGetPosition windowMove

  clientSize
    = newAttr "clientSize" windowGetClientSize windowSetClientSize

  virtualSize
    = newAttr "virtualSize" windowGetVirtualSize windowSetVirtualSize


instance Colored (Window a) where
  bgcolor
    = newAttr "bgcolor" windowGetBackgroundColour (\w x -> do{ windowSetBackgroundColour w x; return ()})

  color
    = newAttr "color" windowGetForegroundColour (\w x -> do windowSetForegroundColour w x; return ())


instance Literate (Window a) where
  font
    = newAttr "font" getter setter
    where
      getter w
        = ifInstanceOf w classTextCtrl
           (\textCtrl -> bracket (textCtrlGetDefaultStyle textCtrl)
                                 (textAttrDelete)
                                 (\attr -> do hasFont <- textAttrHasFont attr
                                              if (hasFont) 
                                                then getFont (textAttrGetFont attr) 
                                                else getFont (windowGetFont w)))
           (getFont (windowGetFont w))
        where
          getFont io
            = bracket io fontDelete fontGetFontStyle 

      setter w info
        = ifInstanceOf w classTextCtrl
           (\textCtrl -> bracket (textAttrCreateDefault)
                                 (textAttrDelete)
                                 (\attr -> withFontStyle info $ \fnt ->
                                           do textAttrSetFont attr fnt
                                              textCtrlSetDefaultStyle textCtrl attr
                                              return ()))
           (withFontStyle info $ \fnt ->
            do windowSetFont w fnt
               return ())

  textColor
    = newAttr "textcolor" getter setter
    where
      getter w
        = ifInstanceOf w classTextCtrl
           (\textCtrl -> bracket (textCtrlGetDefaultStyle textCtrl)
                                 (textAttrDelete)
                                 (\attr -> do hasColor <- textAttrHasTextColour attr
                                              if (hasColor) then textAttrGetTextColour attr
                                                            else get w color))
           (get w color)

      setter w c
        = ifInstanceOf w classTextCtrl
           (\textCtrl -> bracket (textAttrCreateDefault)
                                 (textAttrDelete)
                                 (\attr -> do textAttrSetTextColour attr c
                                              textCtrlSetDefaultStyle textCtrl attr
                                              return ()))
           (set w [color := c])

  textBgcolor
    = newAttr "textbgcolor" getter setter
    where
      getter w
        = ifInstanceOf w classTextCtrl
           (\textCtrl -> bracket (textCtrlGetDefaultStyle textCtrl)
                                 (textAttrDelete)
                                 (\attr -> do hasColor <- textAttrHasBackgroundColour attr
                                              if (hasColor) then textAttrGetBackgroundColour attr
                                                            else get w bgcolor))
           (get w bgcolor)

      setter w c
       = ifInstanceOf w classTextCtrl
           (\textCtrl -> bracket (textAttrCreateDefault)
                                 (textAttrDelete)
                                 (\attr -> do textAttrSetBackgroundColour attr c
                                              textCtrlSetDefaultStyle textCtrl attr
                                              return ()))
           (set w [bgcolor := c])

  

instance Visible (Window a) where
  visible
    = newAttr "visible" windowIsShown setVisible
    where
      setVisible w vis
        = if vis
           then do{ windowShow w; windowRaise w }
           else unitIO (windowHide w)

  refresh w
    = windowRefresh w False


instance Child (Window a) where
  parent
    = readAttr "parent" windowGetParent

instance Identity (Window a) where
  identity
    = newAttr "identity" windowGetId windowSetId

instance Styled (Window a) where
  style
    = newAttr "style" windowGetWindowStyleFlag windowSetWindowStyleFlag

instance Tipped (Window a) where
  tooltip
    = newAttr "tooltip" windowGetToolTip windowSetToolTip

{-
instance Help (Window a) where
  help
    = newAttr "help" windowSetHelpText windowGetHelpText
-}

{--------------------------------------------------------------------------------
  Events
--------------------------------------------------------------------------------}
instance Reactive (Window a) where
  mouse     = newEvent "mouse" windowGetOnMouse (\w h -> windowOnMouse w True h)
  keyboard  = newEvent "keyboard" windowGetOnKeyChar (windowOnKeyChar)
  closing   = newEvent "closing" windowGetOnClose windowOnClose
  idle      = newEvent "idle" windowGetOnIdle windowOnIdle
  resize    = newEvent "resize" windowGetOnSize windowOnSize
  focus     = newEvent "focus" windowGetOnFocus windowOnFocus
  activate  = newEvent "activate" windowGetOnActivate windowOnActivate

instance Paint (Window a) where
  paint     = newEvent "paint" windowGetOnPaint (\w h -> windowOnPaint w h)
  paintRaw  = newEvent "paintRaw" windowGetOnPaintRaw (\w h -> windowOnPaintRaw w h)
  repaint w = windowRefresh w False