import
  sequtils, nimpy,
  nimraylib_now as rl

from utils import getDisplayResolution, compareColorPCT
from input import mousePosition

pyExportModule("pyMeow")

type Pixel = object
  x, y: int
  color: rl.Color

when defined(linux):
  import x11/[x, xlib, xutil]
  var
    disp: PDisplay
elif defined(windows):
  import winim
  var
    hdc, hDest: HDC

iterator pixelEnumRegion(x, y, width, height: float): Pixel {.exportpy: "pixel_enum_region".} =
  when defined(linux):
    if disp.isNil:
      disp = XOpenDisplay(nil)

    let 
      root = XRootWindow(disp, 0)
      shot = XGetImage(
        disp, root,
        x.int, y.int,
        width.cuint, height.cuint,
        AllPlanes, ZPixmap
      )
    defer: discard XDestroyImage(shot)

    var p: Pixel
    p.color.a = 255
    for x in 0..<width.int:
      for y in 0..<height.int:
        var xp = XGetPixel(shot, x, y)
        p.x = x
        p.y = y
        p.color.r = ((xp and shot.red_mask) shr 16).uint8
        p.color.g = ((xp and shot.green_mask) shr 8).uint8
        p.color.b = (xp and shot.blue_mask).uint8
        yield p

  elif defined(windows):
    if hdc == 0:
      hdc = GetDC(0)
      hDest = CreateCompatibleDC(hdc)

    var hbDesktop = CreateCompatibleBitmap(hdc, width.int, height.int)
    SelectObject(hDest, hbDesktop)
    BitBlt(hDest, 0, 0, width.int, height.int, hdc, x.int, y.int, SRCCOPY)  
    defer: DeleteObject(hbDesktop)

    var p: Pixel
    p.color.a = 255
    for x in 0..<width.int:
      for y in 0..<height.int:
        var xp = GetPixel(hDest, x, y)
        p.x = x
        p.y = y
        p.color.r = GetRValue(xp)
        p.color.g = GetGValue(xp)
        p.color.b = GetBValue(xp)
        yield p

iterator pixelEnumScreen: Pixel {.exportpy: "pixel_enum_screen".} =
  let res = getDisplayResolution()
  for p in pixelEnumRegion(0, 0, res[0].float, res[1].float):
    yield p

proc pixelAtMouse: Pixel {.exportpy: "pixel_at_mouse".} =
  let pos = mousePosition()
  result = pixelEnumRegion(pos.x, pos.y, 1, 1).toSeq()[0]

proc pixelAtPos(x, y: float): Pixel {.exportpy: "pixel_at_pos".} =
  result = pixelEnumRegion(x, y, 1, 1).toSeq()[0]

proc pixelSaveToFile(x, y, width, height: float, fileName: string): bool {.exportpy: "pixel_save_to_file".} =
  rl.setTraceLogLevel(5)
  var img = genImageColor(width.int, height.int, Blank)
  for p in pixelEnumRegion(x, y, width, height):
    imageDrawPixel(
      img.addr,
      p.x, p.y,
      rl.Color(r: p.color.r, g: p.color.g, b: p.color.b, a: 255)
    )
  exportImage(img, (fileName & ".png").cstring)

iterator pixelSearchColors(x, y, width, height: float, colors: openArray[rl.Color], similarity: float): Pixel {.exportpy: "pixel_search_colors".} =
  for p in pixelEnumRegion(x, y, width, height):
    for color in colors:
      if compareColorPCT(p.color, color) >= similarity:
        yield p
