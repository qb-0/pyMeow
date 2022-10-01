import 
  nimraylib_now as rl,
  nimpy, tables

type
  FontObj = object
    id: int
    font: Font
  
var
  FontTable: Table[int, FontObj]

pyExportModule("pyMeow")

converter toCint(x: float|int): cint = x.cint

proc drawFPS(posX, posY: float) {.exportpy: "draw_fps".} =
  rl.drawFPS(posX, posY)

proc drawText(text: string, posX, posY, fontSize: float, color: Color) {.exportpy: "draw_text".} =
  rl.drawText(text, posX, posY, fontSize, color)

proc drawPixel(posX, posY: float, color: Color) {.exportpy: "draw_pixel".} =
  rl.drawPixel(posX, posY, color)

proc drawLine(startPosX, startPosY, endPosX, endPosY: float, color: Color, thick: float = 1.0) {.exportpy: "draw_line".} =
  let
    startPos = Vector2(x: startPosX, y: startPosY)
    endPos = Vector2(x: endPosX, y: endPosY)
  rl.drawLineEx(startPos, endPos, thick, color)

proc drawCircle(centerX, centerY, radius: float, color: Color) {.exportpy: "draw_circle".} =
  rl.drawCircle(centerX, centerY, radius, color)

proc drawCircleLines(centerX, centerY, radius: float, color: Color) {.exportpy: "draw_circle_lines".} =
  rl.drawCircleLines(centerX, centerY, radius, color)

proc drawRing(centerX, centerY, segments, innerRadius, outerRadius, startAngle, endAngle: float, color: Color) {.exportpy: "draw_ring".} =
  rl.drawRing(Vector2(x: centerX, y: centerY), innerRadius, outerRadius, startAngle, endAngle, segments, color)

proc drawRingLines(centerX, centerY, segments, innerRadius, outerRadius, startAngle, endAngle: float, color: Color) {.exportpy: "draw_ring_lines".} =
  rl.drawRingLines(Vector2(x: centerX, y: centerY), innerRadius, outerRadius, startAngle, endAngle, segments, color)

proc drawEllipse(centerX, centerY, radiusH, radiusV: float, color: Color) {.exportpy: "draw_ellipse".} =
  rl.drawEllipse(centerX, centerY, radiusH, radiusV, color)

proc drawRectangle(posX, posY, width, height: float, color: Color) {.exportpy: "draw_rectangle".} =
  rl.drawRectangle(posX, posY, width, height, color)

proc drawRectangleLines(posX, posY, width, height: float, color: Color, lineThick: float = 1.0) {.exportpy: "draw_rectangle_lines".} =
  let r = Rectangle(
    x: posX,
    y: posY,
    width: width,
    height: height,
  )
  rl.drawRectangleLinesEx(r, lineThick, color)

proc drawRectangleRounded(posX, posY, width, height, roundness: float, segments: int, color: Color) {.exportpy: "draw_rectangle_rounded".} =
  let r = Rectangle(
    x: posX,
    y: posY,
    width: width,
    height: height,
  )
  rl.drawRectangleRounded(r, roundness, segments, color)

proc drawRectangleRoundedLines(posX, posY, width, height, roundness: float, segments: int, color: Color, lineThick: float = 1.0) {.exportpy: "draw_rectangle_rounded_lines".} =
  let r = Rectangle(
    x: posX,
    y: posY,
    width: width,
    height: height,
  )
  rl.drawRectangleRoundedLines(r, roundness, segments, lineThick, color)

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

proc loadTexture(fileName: string): Texture2D {.exportpy: "load_texture".} =
  rl.loadTexture(fileName)

proc drawTexture(texture: Texture2D, posX, posY: float, tint: Color, rotation, scale: float) {.exportpy: "draw_texture".} =
  rl.drawTextureEx(texture, Vector2(x: posX, y: posY), rotation, scale, tint)

proc loadFont(fileName: string, fontId: int) {.exportpy: "load_font".} =
  FontTable[fontId] = FontObj(
    id: fontId,
    font: rl.loadFont(fileName)
  )

proc drawFont(fontId: int, text: string, posX, posY, fontSize, spacing: float, tint: Color) {.exportpy: "draw_font".} =
  if fontId notin FontTable:
    raise newException(Exception, "Unknown Font ID")
  rl.drawTextEx(FontTable[fontId].font, text, Vector2(x: posX, y: posY), fontSize, spacing, tint)