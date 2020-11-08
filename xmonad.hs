import XMonad
import XMonad.Hooks.SetWMName
import XMonad.Util.EZConfig
import Graphics.X11.ExtraTypes.XF86
import qualified XMonad.StackSet as W

main = xmonad $ def { 
    startupHook = setWMName "LG3D"
    , terminal  = "gnome-terminal" 
    , borderWidth = 3
    , normalBorderColor = "#cccccc"
    , focusedBorderColor = "#4488cc"
    }
    `additionalKeysP`
    [ ("M-x f" , spawn "firefox")
    , ("M-x s" , spawn "slack")
    ] 
    `additionalKeys`
    [((mod4Mask .|. shiftMask, xK_z), spawn "gnome-screensaver-command --lock")
    , ((0 , xF86XK_Sleep), spawn "gnome-screensaver-command --lock")
    , ((0 , xF86XK_Standby), spawn "gnome-screensaver-command --lock")
    , ((0 , xF86XK_Suspend), spawn "gnome-screensaver-command --lock")
    , ((0 , xF86XK_PowerDown), spawn "gnome-screensaver-command --lock")
    , ((0 , xF86XK_PowerOff), spawn "gnome-screensaver-command --lock")
    , ((0 , xF86XK_WakeUp), spawn "gnome-screensaver-command --lock")
    , ((0 , 0x1005ff70), spawn "gnome-terminal")
    , ((0 , xF86XK_AudioRaiseVolume), spawn "set-volume +5%")
    , ((0 , xF86XK_AudioLowerVolume), spawn "set-volume -5%")
    , ((0 , xF86XK_AudioMute), spawn "toggle-mute")
   ]
    `additionalMouseBindings`
    [
    ]
