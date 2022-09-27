import
  nimpy,
  nimraylib_now as rl,
  input

when defined(linux):
  const exitKey = 0xFF57
  import x11/xlib
elif defined(windows):
  const exitKey = 0x23
  import winim/inc/winuser

pyExportModule("pyMeow")

proc getScreenResolution: (int, int) =
  when defined(linux):
    let
      disp = XOpenDisplay(nil)
      scrn = DefaultScreenOfDisplay(disp)

    (scrn.width.int, scrn.height.int)
  elif defined(windows):
    (GetSystemMetrics(SM_CXSCREEN).int, GetSystemMetrics(SM_CYSCREEN).int)

proc initOverlay(width, height, fps: int = 0, title: string = "PyMeow", logLevel: cint = 5) {.exportpy: "overlay_init"} =
  var w, h: int
  if width == 0 and height == 0:
    var res = getScreenResolution()
    w = res[0] - 1
    h = res[1] - 1
  else:
    w = width
    h = height

  setTraceLogLevel(logLevel)
  setTargetFPS(fps.cint)
  setConfigFlags(WINDOW_UNDECORATED)
  setConfigFlags(WINDOW_MOUSE_PASSTHROUGH)
  setConfigFlags(WINDOW_TRANSPARENT)
  setConfigFlags(WINDOW_TOPMOST)
  initWindow(w, h, title)

proc overlayLoop: bool {.exportpy: "overlay_loop".} =
  clearBackground(Blank)
  if keyPressed(exitKey):
    rl.closeWindow()
  not windowShouldClose()

proc beginDrawing {.exportpy: "begin_drawing".} =
  rl.beginDrawing()

proc endDrawing {.exportpy: "end_drawing".} =
  rl.endDrawing()

proc getFPS: int {.exportpy: "get_fps".} =
  rl.getFPS()

proc setFPS(fps: int) {.exportpy: "set_fps".} =
  rl.setTargetFPS(fps)

proc getScreenHeight: int {.exportpy: "get_screen_height".} =
  rl.getScreenHeight()

proc getScreenWidth: int {.exportpy: "get_screen_width".} =
  rl.getScreenWidth()

proc takeScreenshot(fileName: string) {.exportpy: "take_screenshot".} =
  rl.takeScreenshot(fileName)

proc overlayClose {.exportpy: "overlay_close".} =
  rl.closeWindow()

proc toggleMouse {.exportpy: "toggle_mouse".} =
  if isWindowState(WINDOW_MOUSE_PASSTHROUGH):
    clearWindowState(WINDOW_MOUSE_PASSTHROUGH)
  else:
    setWindowState(WINDOW_MOUSE_PASSTHROUGH)