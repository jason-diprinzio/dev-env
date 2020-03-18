import XMonad
import XMonad.Hooks.SetWMName
import XMonad.Util.EZConfig
import qualified XMonad.StackSet as W

main = xmonad $ def { 
    startupHook = setWMName "LG3D"
    , terminal  = "gnome-terminal" 
    }
    `additionalKeysP`
    [ ("M-<Esc>", spawn "gnome-screensaver-command -l")
    , ("M-x f" , spawn "firefox")
    , ("M-x s" , spawn "slack")
    ] 
    `additionalMouseBindings`
    [
    ]
