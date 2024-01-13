import
  strformat, nimpy,
  nimraylib_now as rl,
  input

from utils import getDisplayResolution

pyExportModule("pyMeow")

when defined(linux):
  import strutils, osproc
elif defined(windows):
  import winim
  SetProcessDPIAware()

type OverlayOptions = object
  exitKey: int
  target: string
  trackTarget: bool
  targetX, targetY: int
  targetWidth, targetHeight: int

var overlayOpts: OverlayOptions

proc getWindowInfo(name: string): tuple[x, y, width, height: int] {.exportpy: "get_window_info".} =
  when defined(linux):
    # TODO: Use a X11 solution. `trackTarget` currently causes issues.
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

proc overlayInit(target: string = "Full", fps: int = 0, title: string = "PyMeow", logLevel: int = 5, exitKey: int = -1, trackTarget: bool = false) {.exportpy: "overlay_init"} =
  let res = getDisplayResolution()
  setTraceLogLevel(logLevel)
  setTargetFPS(fps.cint)
  setConfigFlags(WINDOW_UNDECORATED)
  setConfigFlags(WINDOW_MOUSE_PASSTHROUGH)
  setConfigFlags(WINDOW_TRANSPARENT)
  setConfigFlags(WINDOW_TOPMOST)
  when defined(windows):
    # Multisampling seems to void the transparent framebuffer on most linux distributions.
    setConfigFlags(MSAA_4X_HINT)
  initWindow(res[0] - 1, res[1] - 1, title)

  if target != "Full":
    let winInfo = getWindowInfo(target)
    overlayOpts.targetX = winInfo.x
    overlayOpts.targetY = winInfo.y
    overlayOpts.targetWidth = winInfo.width
    overlayOpts.targetHeight = winInfo.height
    setWindowSize(winInfo.width, winInfo.height)
    setWindowPosition(winInfo.x, winInfo.y)
  elif trackTarget:
    raise newException(Exception, "Target tracking is not supported in Fullscreen mode")
  overlayOpts.target = target
  overlayOpts.trackTarget = trackTarget

  if exitKey != -1:
    overlayOpts.exitKey = exitKey
  else:
    when defined(windows):
      overlayOpts.exitKey = 0x23
    elif defined(linux):
      overlayOpts.exitKey = 0xFF57
  setExitKey(KeyboardKey.NULL)

proc overlayLoop: bool {.exportpy: "overlay_loop".} =
  clearBackground(Blank)
  if keyPressed(overlayOpts.exitKey):
    rl.closeWindow()
  if overlayOpts.trackTarget:
    let winInfo = getWindowInfo(overlayOpts.target)
    if winInfo.x != overlayOpts.targetX or winInfo.y != overlayOpts.targetY:
      overlayOpts.targetX = winInfo.x
      overlayOpts.targetY = winInfo.y
      rl.setWindowPosition(winInfo.x, winInfo.y)
    if winInfo.width != overlayOpts.targetWidth or winInfo.height != overlayOpts.targetHeight:
      overlayOpts.targetWidth = winInfo.width
      overlayOpts.targetHeight = winInfo.height
      rl.setWindowSize(winInfo.width, winInfo.height)
  not windowShouldClose()

proc beginDrawing {.exportpy: "begin_drawing".} =
  rl.beginDrawing()

proc endDrawing {.exportpy: "end_drawing".} =
  rl.endDrawing()

proc getFPS: int {.exportpy: "get_fps".} =
  rl.getFPS()

proc getScreenHeight: int {.exportpy: "get_screen_height".} =
  rl.getScreenHeight()

proc getScreenWidth: int {.exportpy: "get_screen_width".} =
  rl.getScreenWidth()

proc getWindowPosition: Vector2 {.exportpy: "get_window_position".} =
  rl.getWindowPosition()

proc getWindowHandle(): int {.exportpy: "get_window_handle".} =
  cast[int](rl.getWindowHandle())

proc setFPS(fps: int) {.exportpy: "set_fps".} =
  rl.setTargetFPS(fps)

proc setWindowPosition(x, y: int) {.exportpy: "set_window_position".} =
  rl.setWindowPosition(x, y)

proc setWindowIcon(filePath: string) {.exportpy: "set_window_icon".} =
  rl.setWindowIcon(rl.loadImage(filePath))

proc setWindowFlag(flag: int) {.exportpy: "set_window_flag".} =
  let f = flag.cuint
  if rl.isWindowState(f):
    rl.clearWindowState(f)
    return
  rl.setWindowState(f)

proc setWindowSize(width, height: int) {.exportpy: "set_window_size".} =
  rl.setWindowSize(width, height)

proc setWindowTitle(title: string) {.exportpy: "set_window_title".} =
  rl.setWindowTitle(title)

proc setWindowMonitor(monitor: int) {.exportpy: "set_window_monitor".} =
  rl.setWindowMonitor(monitor)

proc setLogLevel(level: int) {.exportpy: "set_log_level".} =
  rl.setTraceLogLevel(level)

proc takeScreenshot(fileName: string) {.exportpy: "take_screenshot".} =
  rl.takeScreenshot(fileName)

proc overlayClose {.exportpy: "overlay_close".} =
  rl.closeWindow()

proc toggleMouse {.exportpy: "toggle_mouse".} =
  if isWindowState(WINDOW_MOUSE_PASSTHROUGH):
    clearWindowState(WINDOW_MOUSE_PASSTHROUGH)
    return
  setWindowState(WINDOW_MOUSE_PASSTHROUGH)