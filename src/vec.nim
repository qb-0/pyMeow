import 
  math, nimpy, nimraylib_now

pyExportModule("pyMeow")

proc vec2(x, y: float = 0): Vector2 {.exportpy: "vec2".} =
  Vector2(x: x, y: y)
proc vec3(x, y, z: float = 0): Vector3 {.exportpy: "vec3".} =
  Vector3(x: x, y: y, z: z)

proc vec2Add(a, b: Vector2): Vector2 {.exportpy: "vec2_add".} =
  result.x = a.x + b.x
  result.y = a.y + b.y
proc vec3Add(a, b: Vector3): Vector3 {.exportpy: "vec3_add".} =
  result.x = a.x + b.x
  result.y = a.y + b.y
  result.z = a.z + b.z

proc vec2Sub(a, b: Vector2): Vector2 {.exportpy: "vec2_sub".} =
  result.x = a.x - b.x
  result.y = a.y - b.y
proc vec3Sub(a, b: Vector3): Vector3 {.exportpy: "vec3_sub".} =
  result.x = a.x - b.x
  result.y = a.y - b.y
  result.z = a.z - b.z

proc vec2Mult(a, b: Vector2): Vector2 {.exportpy: "vec2_mult".} =
  result.x = a.x * b.x
  result.y = a.y * b.y
proc vec3Mult(a, b: Vector3): Vector3 {.exportpy: "vec3_mult".} =
  result.x = a.x * b.x
  result.y = a.y * b.y
  result.z = a.z * b.z

proc vec2Div(a, b: Vector2): Vector2 {.exportpy: "vec2_div".} =
  result.x = a.x / b.x
  result.y = a.y / b.y
proc vec3Div(a, b: Vector3): Vector3 {.exportpy: "vec3_div".} =
  result.x = a.x / b.x
  result.y = a.y / b.y
  result.z = a.z / b.z

proc vec2MagSq(a: Vector2): float32 {.exportpy: "vec2_magSq".} =
  (a.x * a.x) + (a.y * a.y)
proc vec3MagSq(a: Vector3): float32 {.exportpy: "vec3_magSq".} =
  (a.x * a.x) + (a.y * a.y) + (a.z * a.z)

proc vec2Mag(a: Vector2): float32 {.exportpy: "vec2_mag".} =
  sqrt(a.vec2MagSq())
proc vec3Mag(a: Vector3): float32 {.exportpy: "vec3_mag".} =
  sqrt(a.vec3MagSq())

proc vec2Distance(a, b: Vector2): float32 {.exportpy: "vec2_distance".} =
  vec2Mag(vec2Sub(a, b))
proc vec3Distance(a, b: Vector3): float32 {.exportpy: "vec3_distance".} =
  vec3Mag(vec3Sub(a, b))

proc vec2Closest(a: Vector2, b: varargs[Vector2]): Vector2 {.exportpy: "vec2_closest".} =
  var closest_value = float32.high
  for v in b:
    let dist = a.vec2Distance(v)
    if dist < closest_value:
      result = v
      closest_value = dist
proc vec3Closest(a: Vector3, b: varargs[Vector3]): Vector3 {.exportpy: "vec3_closest".} =
  var closest_value = float32.high
  for v in b:
    let dist = a.vec3Distance(v)
    if a.vec3Distance(v) < closest_value:
      result = v
      closest_value = dist