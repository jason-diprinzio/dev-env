import XMonad
import XMonad.Hooks.SetWMName
import XMonad.Util.EZConfig
import Graphics.X11.ExtraTypes.XF86
import qualified XMonad.StackSet as W

main = xmonad $ def { 
    startupHook = setWMName "LG3D"
    , terminal  = "gnome-terminal" 
    }
    `additionalKeysP`
    [ ("M-x f" , spawn "firefox")
    , ("M-x s" , spawn "slack")
    ] 
    `additionalKeys`
    [((mod4Mask .|. shiftMask, xK_z), spawn "xscreensaver-command -lock")
    , ((0 , xF86XK_AudioRaiseVolume), spawn "set-volume +5%")
    , ((0 , xF86XK_AudioLowerVolume), spawn "set-volume -5%")
    , ((0 , xF86XK_AudioMute), spawn "pactl set-sink-mute 32 toggle")
    , ((0 , xF86XK_Sleep), spawn "gnome-screensaver-command -l")
    , ((0 , xF86XK_PowerDown), spawn "gnome-screensaver-command -l")
    ]
    `additionalMouseBindings`
    [
    ]
