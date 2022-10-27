import
  strformat,
  nimpy,
  nimraylib_now as rl,
  input

pyExportModule("pyMeow")

# exitKey: 'END'
when defined(linux):
  var globalExitKey = 0xFF57
  import x11/xlib, strutils, osproc
elif defined(windows):
  var globalExitKey = 0x23
  import winim

proc getScreenResolution: (int, int) =
  when defined(linux):
    let
      disp = XOpenDisplay(nil)
      scrn = DefaultScreenOfDisplay(disp)

    (scrn.width.int, scrn.height.int)
  elif defined(windows):
    (GetSystemMetrics(SM_CXSCREEN).int, GetSystemMetrics(SM_CYSCREEN).int)

proc getWindowInfo(name: string): tuple[x, y, width, height: int] =
  when defined(linux):
    let 
      p = startProcess("xwininfo", "", ["-name", name], options={poUsePath, poStdErrToStdOut})
      (lines, exitCode) = p.readLines()

    template parseI: int32 = parseInt(i.split()[^1])

    if exitCode != 1:
      for i in lines:
        if "error" in i:
          raise newException(Exception, fmt"Window ({name}) not found")
        if "te upper-left X:" in i:
          result.x = parseI
        elif "te upper-left Y:" in i:
          result.y = parseI
        elif "Width:" in i:
          result.width = parseI
        elif "Height:" in i:
          result.height = parseI
    else:
      raise newException(Exception, "XWinInfo failed (installed 'xwininfo'?)")
  elif defined(windows):
    var 
      rect: RECT
      winInfo: WINDOWINFO
    let hwnd = FindWindowA(nil, name)
    if hwnd == 0:
      raise newException(Exception, fmt"Window ({name}) not found")
    discard GetClientRect(hwnd, rect.addr)
    discard GetWindowInfo(hwnd, winInfo.addr)
    result.x = winInfo.rcClient.left
    result.y = winInfo.rcClient.top
    result.width = rect.right
    result.height = rect.bottom

proc overlayInit(target: string = "Full", fps: int = 0, title: string = "PyMeow", logLevel: int = 5, exitKey: int = -1) {.exportpy: "overlay_init"} =
  let res = getScreenResolution()
  setTraceLogLevel(logLevel)
  setTargetFPS(fps.cint)
  setConfigFlags(WINDOW_UNDECORATED)
  setConfigFlags(WINDOW_MOUSE_PASSTHROUGH)
  setConfigFlags(WINDOW_TRANSPARENT)
  setConfigFlags(WINDOW_TOPMOST)
  when defined(windows): 
    # Multisample seems to void the transparent framebuffer on most linux distro's.
    # Needs more tests
    setConfigFlags(MSAA_4X_HINT)
  initWindow(res[0] - 1, res[1] - 1, title)

  if target != "Full":
    let winInfo = getWindowInfo(target)
    setWindowSize(winInfo.width, winInfo.height)
    setWindowPosition(winInfo.x, winInfo.y)

  if exitKey != -1:
    globalExitKey = exitKey
  setExitKey(KeyboardKey.NULL)

proc overlayLoop: bool {.exportpy: "overlay_loop".} =
  clearBackground(Blank)
  if keyPressed(globalExitKey):
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

proc setWindowPosition(x, y: int) {.exportpy: "set_window_position".} =
  rl.setWindowPosition(x, y)

proc getWindowPosition: Vector2 {.exportpy: "get_window_position".} =
  rl.getWindowPosition()

proc setWindowSize(width, height: int) {.exportpy: "set_window_size".} =
  rl.setWindowSize(width, height)

proc takeScreenshot(fileName: string) {.exportpy: "take_screenshot".} =
  rl.takeScreenshot(fileName)

proc overlayClose {.exportpy: "overlay_close".} =
  rl.closeWindow()

proc toggleMouse {.exportpy: "toggle_mouse".} =
  if isWindowState(WINDOW_MOUSE_PASSTHROUGH):
    clearWindowState(WINDOW_MOUSE_PASSTHROUGH)
  else:
    setWindowState(WINDOW_MOUSE_PASSTHROUGH)