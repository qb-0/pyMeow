import 
  colors, nimpy, 
  nimraylib_now/raylib as rl

pyExportModule("pyMeow")

proc newColor(r, g, b, a: uint8): rl.Color {.exportpy: "new_color".} =
  rl.Color(r: r, g: g, b: b, a: a)

proc getColor(colorName: string): rl.Color {.exportpy: "get_color".} =
  try:
    let c = parseColor(colorName).extractRGB()
    rl.Color(
      r: c.r.uint8,
      g: c.g.uint8,
      b: c.b.uint8,
      a: 255,
    )
  except ValueError:
    rl.Color(
      r: 0,
      g: 0,
      b: 0,
      a: 0,
    )

proc measureText(text: string, fontSize: cint): int {.exportpy: "measure_text".} =
  rl.measureText(text, fontSize)

proc runTime: float64 {.exportpy: "run_time".} =
  rl.getTime()

proc colorSetAlpha(color: rl.Color, alpha: uint8): rl.Color {.exportpy: "color_set_alpha".} =
  var c = color
  c.a = alpha
  c

proc wtsOgl(matrix: array[0..15, float32], pos: Vector3): Vector2 {.exportpy: "wts_ogl".} =
  var 
    clip: Vector3
    ndc: Vector2

  # z = w
  clip.z = pos.x * matrix[3] + pos.y * matrix[7] + pos.z * matrix[11] + matrix[15]
  if clip.z < 0.2:
    raise newException(Exception, "WTS")

  clip.x = pos.x * matrix[0] + pos.y * matrix[4] + pos.z * matrix[8] + matrix[12]
  clip.y = pos.x * matrix[1] + pos.y * matrix[5] + pos.z * matrix[9] + matrix[13]

  ndc.x = clip.x / clip.z
  ndc.y = clip.y / clip.z

  result.x = (getScreenWidth() / 2 * ndc.x) + (ndc.x + getScreenWidth() / 2)
  result.y = -(getScreenHeight() / 2 * ndc.y) + (ndc.y + getScreenHeight() / 2)

proc wtsDx(matrix: array[0..15, float32], pos: Vector3): Vector2 {.exportpy: "wts_dx".} =
  var 
    clip: Vector3
    ndc: Vector2

  # z = w
  clip.z = pos.x * matrix[12] + pos.y * matrix[13] + pos.z * matrix[14] + matrix[15]
  if clip.z < 0.2:
    raise newException(Exception, "WTS")

  clip.x = pos.x * matrix[0] + pos.y * matrix[1] + pos.z * matrix[2] + matrix[3]
  clip.y = pos.x * matrix[4] + pos.y * matrix[5] + pos.z * matrix[6] + matrix[7]

  ndc.x = clip.x / clip.z
  ndc.y = clip.y / clip.z

  result.x = (getScreenWidth() / 2 * ndc.x) + (ndc.x + getScreenWidth() / 2)
  result.y = -(getScreenHeight() / 2 * ndc.y) + (ndc.y + getScreenHeight() / 2)