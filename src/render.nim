import
  nimraylib_now as rl,
  nimpy, tables

pyExportModule("pyMeow")

type
  FontObj = object
    id: int
    font: Font

var
  fontTable: Table[int, FontObj]

converter toCint(x: float|int): cint = x.cint

proc drawFPS(posX, posY: float) {.exportpy: "draw_fps".} =
  rl.drawFPS(posX, posY)

proc drawText(text: string, posX, posY, fontSize: float, color: Color) {.exportpy: "draw_text".} =
  rl.drawText(text, posX, posY, fontSize, color)

proc drawPixel(posX, posY: float, color: Color) {.exportpy: "draw_pixel".} =
  rl.drawPixel(posX, posY, color)

proc drawLine(startPosX, startPosY, endPosX, endPosY: float, color: Color, thick: float = 1.0) {.exportpy: "draw_line".} =
  rl.drawLineEx(Vector2(x: startPosX, y: startPosY), Vector2(x: endPosX, y: endPosY), thick, color)

proc drawCircle(centerX, centerY, radius: float, color: Color) {.exportpy: "draw_circle".} =
  rl.drawCircle(centerX, centerY, radius, color)

proc drawCircleLines(centerX, centerY, radius: float, color: Color) {.exportpy: "draw_circle_lines".} =
  rl.drawCircleLines(centerX, centerY, radius, color)

proc drawCircleSector(centerX, centerY, radius, startAngle, endAngle: float, segments: int, color: Color) {.exportpy: "draw_circle_sector".} =
  rl.drawCircleSector(Vector2(x: centerX, y: centerY), radius, startAngle, endAngle, segments, color)

proc drawCircleSectorLines(centerX, centerY, radius, startAngle, endAngle: float, segments: int, color: Color) {.exportpy: "draw_circle_sector_lines".} =
  rl.drawCircleSectorLines(Vector2(x: centerX, y: centerY), radius, startAngle, endAngle, segments, color)

proc drawRing(centerX, centerY, segments, innerRadius, outerRadius, startAngle, endAngle: float, color: Color) {.exportpy: "draw_ring".} =
  rl.drawRing(Vector2(x: centerX, y: centerY), innerRadius, outerRadius, startAngle, endAngle, segments, color)

proc drawRingLines(centerX, centerY, segments, innerRadius, outerRadius, startAngle, endAngle: float, color: Color) {.exportpy: "draw_ring_lines".} =
  rl.drawRingLines(Vector2(x: centerX, y: centerY), innerRadius, outerRadius, startAngle, endAngle, segments, color)

proc drawEllipse(centerX, centerY, radiusH, radiusV: float, color: Color) {.exportpy: "draw_ellipse".} =
  rl.drawEllipse(centerX, centerY, radiusH, radiusV, color)

proc drawEllipseLines(centerX, centerY, radiusH, radiusV: float, color: Color) {.exportpy: "draw_ellipse_lines".} =
  rl.drawEllipseLines(centerX, centerY, radiusH, radiusV, color)

proc drawRectangle(posX, posY, width, height: float, color: Color): Rectangle {.exportpy: "draw_rectangle".} =
  result.x = posX
  result.y = posY
  result.width = width
  result.height = height
  rl.drawRectangle(posX, posY, width, height, color)

proc drawRectangleLines(posX, posY, width, height: float, color: Color, lineThick: float = 1.0): Rectangle {.exportpy: "draw_rectangle_lines".} =
  result.x = posX
  result.y = posY
  result.width = width
  result.height = height
  rl.drawRectangleLinesEx(result, lineThick, color)

proc drawRectangleRounded(posX, posY, width, height, roundness: float, segments: int, color: Color): Rectangle {.exportpy: "draw_rectangle_rounded".} =
  result.x = posX
  result.y = posY
  result.width = width
  result.height = height
  rl.drawRectangleRounded(result, roundness, segments, color)

proc drawRectangleRoundedLines(posX, posY, width, height, roundness: float, segments: int, color: Color, lineThick: float = 1.0): Rectangle {.exportpy: "draw_rectangle_rounded_lines".} =
  result.x = posX
  result.y = posY
  result.width = width
  result.height = height
  rl.drawRectangleRoundedLines(result, roundness, segments, lineThick, color)

proc drawTriangle(pos1X, pos1Y, pos2X, pos2Y, pos3X, pos3Y: float, color: Color) {.exportpy: "draw_triangle".} =
  rl.drawTriangle(
    Vector2(x: pos1X, y: pos1Y),
    Vector2(x: pos2X, y: pos2Y),
    Vector2(x: pos3X, y: pos3Y),
    color
  )

proc drawTriangleLines(pos1X, pos1Y, pos2X, pos2Y, pos3X, pos3Y: float, color: Color) {.exportpy: "draw_triangle_lines".} =
  rl.drawTriangleLines(
    Vector2(x: pos1X, y: pos1Y),
    Vector2(x: pos2X, y: pos2Y),
    Vector2(x: pos3X, y: pos3Y),
    color
  )

proc drawPoly(posX, posY: float, sides: int, radius, rotation: float, color: Color) {.exportpy: "draw_poly"} =
  rl.drawPoly(Vector2(x: posX, y: posY), sides, radius, rotation, color)

proc drawPolyLines(posX, posY: float, sides: int, radius, rotation, lineThick: float, color: Color) {.exportpy: "draw_poly_lines".} =
  rl.drawPolyLinesEx(Vector2(x: posX, y: posY), sides, radius, rotation, lineThick, color)

proc loadTexture(fileName: string): Texture2D {.exportpy: "load_texture".} =
  rl.loadTexture(fileName)

proc loadTextureBytes(fileType: string, data: openArray[uint8]): Texture2D {.exportpy: "load_texture_bytes".} =
  rl.loadTextureFromImage(rl.loadImageFromMemory(fileType, data[0].unsafeAddr, data.len))

proc drawTexture(texture: Texture2D, posX, posY: float, tint: Color, rotation, scale: float) {.exportpy: "draw_texture".} =
  rl.drawTextureEx(texture, Vector2(x: posX, y: posY), rotation, scale, tint)

proc unloadTexture(texture: Texture2D) {.exportpy: "unload_texture".} =
  rl.unloadTexture(texture)

proc loadFont(fileName: string, fontId: int) {.exportpy: "load_font".} =
  fontTable[fontId] = FontObj(
    id: fontId,
    font: rl.loadFont(fileName)
  )

proc drawFont(fontId: int, text: string, posX, posY, fontSize, spacing: float, tint: Color) {.exportpy: "draw_font".} =
  if fontId notin fontTable:
    raise newException(Exception, "Unknown Font ID")
  rl.drawTextEx(fontTable[fontId].font, text, Vector2(x: posX, y: posY), fontSize, spacing, tint)

proc measureFont(fontId: int, text: string, fontSize, spacing: float): Vector2 {.exportpy: "measure_font".} =
  if fontId notin fontTable:
    raise newException(Exception, "Unknown Font ID")
  rl.measureTextEx(fontTable[fontId].font, text, fontSize, spacing)