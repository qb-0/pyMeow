import 
  nimpy, 
  nimraylib_now/raylib,
  nimraylib_now/raygui as rg

pyExportModule("pyMeow")

template getRec: Rectangle =
  Rectangle(
    x: posX,
    y: posY,
    width: width,
    height: height
  )

proc windowBox(posX, posY, width, height: float, title: string): bool {.exportpy: "gui_window_box".} =
  rg.windowBox(getRec, title)

proc groupBox(posX, posY, width, height: float, text: string) {.exportpy: "gui_group_box".} =
  rg.groupBox(getRec, text)

proc line(posX, posY, width, height: float, text: string) {.exportpy: "gui_line".} =
  rg.line(getRec, text)

proc panel(posX, posY, width, height: float) {.exportpy: "gui_panel".} =
  rg.panel(getRec)

proc label(posX, posY, width, height: float, text: string) {.exportpy: "gui_label".} =
  rg.label(getRec, text)

proc button(posX, posY, width, height: float, text: string): bool {.exportpy: "gui_button"} =
  rg.button(getRec, text)

proc labelButton(posX, posY, width, height: float, text: string): bool {.exportpy: "gui_label_button".} =
  rg.labelButton(getRec, text)

proc checkBox(posX, posY, width, height: float, text: string, checked: bool): bool {.exportpy: "gui_check_box".} =
  rg.checkBox(getRec, text, checked)

proc comboBox(posX, posY, width, height: float, text: string, active: int = 0): int {.exportpy: "gui_combo_box".} =
  rg.comboBox(getRec, text, active.cint)

proc dropdownBox(posX, posY, width, height: float, text: string): int {.exportpy: "gui_dropdown_box".} =
  var 
    active {.global.}: cint
    open {.global.}: bool

  if rg.dropdownBox(getRec, text, active.addr, open):
    open = not open
  active

proc textBox(posX, posY, width, height: float, editMode: bool = true): string {.exportpy: "gui_text_box".} =
  var textBuf = newString(64)
  discard rg.textBox(getRec, textBuf.cstring, 64, editMode)
  textBuf

proc progressBar(posX, posY, width, height: float, textLeft, textRight: string, value, minValue, maxValue: float): float {.exportpy: "gui_progress_bar".} =
  rg.progressBar(getRec, textLeft, textRight, value, minValue, maxValue)

proc statusBar(posX, posY, width, height: float, text: string) {.exportpy: "gui_status_bar".} =
  rg.statusBar(getRec, text)

proc messageBox(posX, posY, width, height: float, title, message, buttons: string): int {.exportpy: "gui_message_box".} =
  rg.messageBox(getRec, title, message, buttons)

var pickedColor = Raywhite
proc colorPicker(posX, posY, width, height: float): Color {.exportpy: "gui_color_picker".} =
  pickedColor = rg.colorPicker(getRec, pickedColor)
  pickedColor

proc loadStyle(fileName: string) {.exportpy: "gui_load_style".} =
  rg.loadStyle(fileName)