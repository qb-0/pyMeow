import
  nimpy, nimraylib_now, nimraylib_now/raymath as rm

pyExportModule("pyMeow")

proc vec2(x, y: float): Vector2 {.exportpy: "vec2".} =
  Vector2(x: x, y: y)
proc vec3(x, y, z: float): Vector3 {.exportpy: "vec3".} =
  Vector3(x: x, y: y, z: z)

proc vec2Add(v1, v2: Vector2): Vector2 {.exportpy: "vec2_add".} =
  rm.add(v1, v2)
proc vec2AddValue(v: Vector2, value: float): Vector2 {.exportpy: "vec2_add_value".} =
  rm.addValue(v, value)
proc vec3Add(v1, v2: Vector3): Vector3 {.exportpy: "vec3_add".} =
  rm.add(v1, v2)
proc vec3AddValue(v: Vector3, value: float): Vector3 {.exportpy: "vec3_add_value".} =
  rm.addValue(v, value)

proc vec2Subtract(v1, v2: Vector2): Vector2 {.exportpy: "vec2_subtract".} =
  rm.subtract(v1, v2)
proc vec2SubtractValue(v: Vector2, value: float): Vector2 {.exportpy: "vec2_subtract_value".} =
  rm.subtractValue(v, value)
proc vec3Subtract(v1, v2: Vector3): Vector3 {.exportpy: "vec3_subtract".} =
  rm.subtract(v1, v2)
proc vec3SubtractValue(v: Vector3, value: float): Vector3 {.exportpy: "vec3_subtract_value".} =
  rm.subtractValue(v, value)

proc vec2Multiply(v1, v2: Vector2): Vector2 {.exportpy: "vec2_multiply".} =
  rm.multiply(v1, v2)
proc vec2MultiplyValue(v: Vector2, value: float): Vector2 {.exportpy: "vec2_multiply_value".} =
  rm.scale(v, value)
proc vec3Multiply(v1, v2: Vector3): Vector3 {.exportpy: "vec3_multiply".} =
  rm.multiply(v1, v2)
proc vec3MultiplyValue(v: Vector3, value: float): Vector3 {.exportpy: "vec3_multiply_value".} =
  rm.scale(v, value)

proc vec2Divide(v1, v2: Vector2): Vector2 {.exportpy: "vec2_divide".} =
  rm.divide(v1, v2)
proc vec3Divide(v1, v2: Vector3): Vector3 {.exportpy: "vec3_divide".} =
  rm.divide(v1, v2)

proc vec2Length(v: Vector2): float {.exportpy: "vec2_length".} =
  rm.length(v)
proc vec3Length(v: Vector3): float {.exportpy: "vec3_length".} =
  rm.length(v)

proc vec2LengthSqr(v: Vector2): float {.exportpy: "vec2_length_sqr".} =
  rm.lengthSqr(v)
proc vec3LengthSqr(v: Vector3): float {.exportpy: "vec3_length_sqr".} =
  rm.lengthSqr(v)

proc vec2Distance(v1, v2: Vector2): float {.exportpy: "vec2_distance".} =
  rm.distance(v1, v2)
proc vec3Distance(v1, v2: Vector3): float {.exportpy: "vec3_distance".} =
  rm.distance(v1, v2)

proc vec2Closest(v: Vector2, vectorList: varargs[Vector2]): Vector2 {.exportpy: "vec2_closest".} =
  var closestValue = float32.high
  for vec in vectorList:
    let dist = v.vec2Distance(vec)
    if dist < closestValue:
      result = vec
      closestValue = dist
proc vec3Closest(v: Vector3, vectorList: varargs[Vector3]): Vector3 {.exportpy: "vec3_closest".} =
  var closestValue = float32.high
  for vec in vectorList:
    let dist = v.vec3Distance(vec)
    if dist < closestValue:
      result = vec
      closestValue = dist
