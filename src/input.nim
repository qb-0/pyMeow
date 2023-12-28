import
  os, nimpy, nimraylib_now

pyExportModule("pyMeow")

when defined(linux):
  import x11/[x, xlib, xtst]

  const 
    buttonMask = [Button1Mask.cuint, Button2Mask, Button3Mask]

  var
    display = XOpenDisplay(nil)
    root = XRootWindow(display, 0)

  proc keyPressed*(key: int): bool {.exportpy: "key_pressed".} =
    var keys: array[0..31, char]
    discard XQueryKeymap(display, keys)
    let keycode = XKeysymToKeycode(display, key.culong)
    (ord(keys[keycode.int div 8]) and (1 shl (keycode.int mod 8))) != 0

  proc mousePressed*(button: string = "left"): bool {.exportpy: "mouse_pressed".} =
    var
      qRoot, qChild: Window
      qRootX, qRootY: cint
      qChildX, qChildY: cint
      qMask: cuint
      key: int = case button:
        of "left": 0
        of "middle": 1
        of "right": 2
        else: 0

    discard XQueryPointer(display, root, qRoot.addr, qChild.addr, qRootX.addr, qRootY.addr, qChildX.addr, qChildY.addr, qMask.addr)
    (qMask and buttonMask[key]).bool

  proc pressKey(key: int, hold: bool = false) {.exportpy: "press_key".} =
    let keycode = XKeysymToKeycode(display, key.KeySym)
    discard XTestFakeKeyEvent(display, keycode.cuint, 1, CurrentTime)
    if not hold:
      discard XTestFakeKeyEvent(display, keycode.cuint, 0, CurrentTime)

  proc mouseMove(x, y: cint, relative: bool = false) {.exportpy: "mouse_move".} =
    if relative:
      discard XTestFakeRelativeMotionEvent(display, x, y, CurrentTime)
    else:
      discard XTestFakeMotionEvent(display, -1, x, y, CurrentTime)
    discard XFlush(display)

  proc mouseDown(button: string = "left") {.exportpy: "mouse_down".} =
    var key: cuint = case button:
      of "left": 1
      of "middle": 2
      of "right": 3
      else: 1
    discard XTestFakeButtonEvent(display, key, 1, 0)
    discard XFlush(display)

  proc mouseUp(button: string = "left") {.exportpy: "mouse_up".} =
    var key: cuint = case button:
      of "left": 1
      of "middle": 2
      of "right": 3
      else: 1
    discard XTestFakeButtonEvent(display, key, 0, 0)
    discard XFlush(display)

  proc mouseClick(button: string = "left") {.exportpy: "mouse_click"} =
    mouseDown(button)
    sleep(3)
    mouseUp(button)

  proc mousePosition*: Vector2 {.exportpy: "mouse_position".} =
    var
      qRoot, qChild: Window
      qRootX, qRootY, qChildX, qChildY: cint
      qMask: cuint
    discard XQueryPointer(display, root, qRoot.addr, qChild.addr, qRootX.addr, qRootY.addr, qChildX.addr, qChildY.addr, qMask.addr)
    result.x = qRootX.cfloat
    result.y = qRootY.cfloat

elif defined(windows):
  import winim

  proc keyPressed*(vKey: int32): bool {.exportpy: "key_pressed".} =
    GetAsyncKeyState(vKey) < 0

  proc mousePressed*(button: string = "left"): bool {.exportpy: "mouse_pressed".} =
    var key: int32 = case button:
      of "left": 1
      of "middle": 4
      of "right": 2
      else: 1
    keyPressed(key)

  proc pressKey(vKey: int) {.exportpy: "press_key".} =
    var input: INPUT
    input.`type` = INPUT_KEYBOARD
    input.ki.wVk = vKey.uint16
    SendInput(1, input.addr, sizeof(input).int32)

  proc mouseMove(x, y: int, relative: bool = false) {.exportpy: "mouse_move".} =
    var
      xm = x
      ym = y
    if relative:
      var p: POINT
      discard GetCursorPos(p.addr)
      xm = x + p.x
      ym = y + p.y
    SetCursorPos(xm.int32, ym.int32)

  proc mouseDown(button: string = "left") {.exportpy: "mouse_down".} =
    var
      down: INPUT
      key = case button:
        of "left": MOUSEEVENTF_LEFTDOWN
        of "middle": MOUSEEVENTF_MIDDLEDOWN
        of "right": MOUSEEVENTF_RIGHTDOWN
        else: MOUSEEVENTF_LEFTDOWN
    down.mi = MOUSE_INPUT(dwFlags: key)
    SendInput(1, down.addr, sizeof(down))

  proc mouseUp(button: string = "left") {.exportpy: "mouse_up".} =
    var
      release: INPUT
      key = case button:
        of "left": MOUSEEVENTF_LEFTUP
        of "middle": MOUSEEVENTF_MIDDLEUP
        of "right": MOUSEEVENTF_RIGHTUP
        else: MOUSEEVENTF_LEFTUP
    release.mi = MOUSE_INPUT(dwFlags: key)
    SendInput(1, release.addr, sizeof(release))

  proc mouseClick(button: string = "left") {.exportpy: "mouse_click".} =
    mouseDown(button)
    sleep(3)
    mouseUp(button)

  proc mousePosition*: Vector2 {.exportpy: "mouse_position".} =
    var point: POINT
    discard GetCursorPos(point.addr)
    result.x = point.x.cfloat
    result.y = point.y.cfloat
