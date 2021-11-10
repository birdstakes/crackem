package require Tk
package require app

wm withdraw .
toplevel .window
wm protocol .window WM_DELETE_WINDOW {destroy .}
::app::App app .window
