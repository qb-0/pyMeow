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
  var disp: PDisplay
elif defined(windows):
  import winim

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
    var
      hdc = GetDC(0)
      hDest = CreateCompatibleDC(hdc)

    var hbDesktop = CreateCompatibleBitmap(hdc, width.int, height.int)
    SelectObject(hDest, hbDesktop)
    BitBlt(hDest, 0, 0, width.int, height.int, hdc, x.int, y.int, SRCCOPY)

    var
      size = (width * height * 4).int
      pBits = newSeq[uint8](size)

    GetBitmapBits(hbDesktop, size, cast[LPVOID](pBits[0].addr))
    DeleteObject(hbDesktop)
    DeleteDC(hDest)
    ReleaseDC(0, hdc)
    for y in 0..<height.int:
      for x in 0..<width.int:
        var i = (y * width.int + x) * 4
        yield Pixel(
            x: x,
            y: y,
            color: rl.Color(
              a: 255,
              b: pBits[i],
              g: pBits[i + 1],
              r: pBits[i + 2],
            )
          )

iterator pixelEnumScreen: Pixel {.exportpy: "pixel_enum_screen".} =
  let res = getDisplayResolution()
  for p in pixelEnumRegion(0, 0, res[0].float, res[1].float):
    yield p

proc pixelAtMouse: Pixel {.exportpy: "pixel_at_mouse".} =
  let pos = mousePosition()
  result = pixelEnumRegion(pos.x, pos.y, 1, 1).toSeq()[0]
  result.x = pos.x.int
  result.y = pos.y.int

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