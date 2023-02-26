import 
  os, nimpy, nimraylib_now

pyExportModule("pyMeow")

when defined(linux):
  import x11/[x, xlib, xtst]

  var 
    display = XOpenDisplay(nil)
    root = XRootWindow(display, 0)

  proc keyPressed*(key: int): bool {.exportpy: "key_pressed".} =
    var keys: array[0..31, char]
    discard XQueryKeymap(display, keys)
    let keycode = XKeysymToKeycode(display, key.culong)
    (ord(keys[keycode.int div 8]) and (1 shl (keycode.int mod 8))) != 0

  proc pressKey*(key: int, hold: bool = false) {.exportpy: "press_key".} =
    let keycode = XKeysymToKeycode(display, key.KeySym)
    discard XTestFakeKeyEvent(display, keycode.cuint, 1, CurrentTime)
    if not hold:
      discard XTestFakeKeyEvent(display, keycode.cuint, 0, CurrentTime)

  proc mouseMove*(x, y: cint, relative: bool = false) {.exportpy: "mouse_move".} =
    if relative:
      discard XTestFakeRelativeMotionEvent(display, x, y, CurrentTime)
    else:
      discard XTestFakeMotionEvent(display, -1, x, y, CurrentTime)
    discard XFlush(display)

  proc mouseClick* {.exportpy: "mouse_click"} =
    discard XTestFakeButtonEvent(display, 1, 1, 0)
    discard XFlush(display)
    sleep(2)
    discard XTestFakeButtonEvent(display, 1, 0, 0)
    discard XFlush(display)

  proc mousePosition*: Vector2 {.exportpy: "mouse_position".} =
    var 
      qRoot, qChild: Window
      qRootX, qRootY, qChildX, qChildY: cint
      qMask: cuint

    discard XQueryPointer(display, root, qRoot.addr, qChild.addr, qRootX.addr, qRootY.addr, qChildX.addr, qChildY.addr, qMask.addr)
    result.x = qRootX.cfloat
    result.y = qRootY.cfloat

elif defined(windows):
  import winim, nimraylib_now/raylib

  proc keyPressed*(vKey: int32): bool {.exportpy: "key_pressed".} =
    GetAsyncKeyState(vKey).bool

  proc pressKey(vKey: int) {.exportpy: "press_key".} =
    var input: INPUT
    input.`type` = INPUT_KEYBOARD
    input.ki.wScan = 0
    input.ki.time = 0
    input.ki.dwExtraInfo = 0
    input.ki.wVk = vKey.uint16
    input.ki.dwFlags = 0
    SendInput(1, input.addr, sizeof(input).int32)

  proc mouseMove(x, y: int32) {.exportpy: "mouse_move".} =
    var input: INPUT
    input.mi = MOUSE_INPUT(
      dwFlags: MOUSEEVENTF_MOVE, 
      dx: x.int32,
      dy: y.int32,
    )
    SendInput(1, input.addr, sizeof(input).int32)

  proc mouseClick {.exportpy: "mouse_click".} =
    var 
      down: INPUT
      release: INPUT
    down.mi = MOUSE_INPUT(dwFlags: MOUSEEVENTF_LEFTDOWN)
    release.mi = MOUSE_INPUT(dwFlags: MOUSEEVENTF_LEFTUP)
    SendInput(1, down.addr, sizeof(down).int32)
    sleep(3)
    SendInput(1, release.addr, sizeof(release).int32)

  proc mousePosition*: Vector2 {.exportpy: "mouse_position".} =
    var point: POINT
    discard GetCursorPos(point.addr)
    result.x = point.x.cfloat
    result.y = point.y.cfloat