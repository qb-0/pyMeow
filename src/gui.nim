import
  tables,
  nimpy,
  nimraylib_now/raylib,
  nimraylib_now/raygui as rg

pyExportModule("pyMeow")

type
  DropDownBox = object
    rec: Rectangle
    text: string
    active: cint
    editMode: bool

  TextBox = object
    rec: Rectangle
    text: string
    editMode: bool

  ColorPicker = object
    rec: Rectangle
    color: Color

  Spinner = object
    rec: Rectangle
    value: cint
    editMode: bool

var
  dropDownTable: Table[int, DropDownBox]
  textBoxTable: Table[int, TextBox]
  colorPickerTable: Table[int, ColorPicker]
  spinnerTable: Table[int, Spinner]

converter toCint(x: float|int): cint = x.cint

template getRec: Rectangle =
  Rectangle(
    x: posX,
    y: posY,
    width: width,
    height: height
  )

proc fade(alpha: float) {.exportpy: "gui_fade".} =
  rg.fade(alpha)

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
  rg.comboBox(getRec, text, active)

proc dropdownBox(posX, posY, width, height: float, text: string, id: int, active: int = 0): int {.exportpy: "gui_dropdown_box".} =
  if id notin dropDownTable:
    dropDownTable[id] = DropDownBox(
      rec: getRec,
      text: text,
      active: active,
    )
  if rg.dropdownBox(getRec, dropDownTable[id].text.cstring, dropDownTable[id].active.addr, dropDownTable[id].editMode):
    dropDownTable[id].editMode = not dropDownTable[id].editMode
    if dropDownTable[id].editMode:
      rg.lock()
    else:
      rg.unlock()
  dropDownTable[id].active

proc textBox(posX, posY, width, height: float, text: string, id: int): string {.exportpy: "gui_text_box".} =
  if id notin textBoxTable:
    textBoxTable[id] = TextBox(
      rec: getRec,
      text: text & newString(width.int),
    )
  if rg.textBox(getRec, textBoxTable[id].text.cstring, 250, textBoxTable[id].editMode):
    textBoxTable[id].editMode = not textBoxTable[id].editMode
  $textBoxTable[id].text.cstring

proc progressBar(posX, posY, width, height: float, textLeft, textRight: string, value, minValue, maxValue: float): float {.exportpy: "gui_progress_bar".} =
  rg.progressBar(getRec, textLeft, textRight, value, minValue, maxValue)

proc statusBar(posX, posY, width, height: float, text: string) {.exportpy: "gui_status_bar".} =
  rg.statusBar(getRec, text)

proc messageBox(posX, posY, width, height: float, title, message, buttons: string): int {.exportpy: "gui_message_box".} =
  rg.messageBox(getRec, title, message, buttons)

proc colorPicker(posX, posY, width, height: float, id: int): Color {.exportpy: "gui_color_picker".} =
  if id notin colorPickerTable:
    colorPickerTable[id] = ColorPicker(
      rec: getRec,
      color: Raywhite
    )
  colorPickerTable[id].color = rg.colorPicker(getRec, colorPickerTable[id].color)
  colorPickerTable[id].color

proc colorBarAlpha(posX, posY, width, height: float, alpha: float): float {.exportpy: "gui_color_bar_alpha".} =
  rg.colorBarAlpha(getRec, alpha)

proc colorBarHue(posX, posY, width, height: float, value: float): float {.exportpy: "gui_color_bar_hue".} =
  rg.colorBarHue(getRec, value)

proc scrollBar(posX, posY, width, height: float, value, minValue, maxValue: int): int {.exportpy: "gui_scroll_bar"} =
  rg.scrollBar(getRec, value, minValue, maxValue)

proc spinner(posX, posY, width, height: float, text: string, value, minValue, maxValue, id: int): int {.exportpy: "gui_spinner".} =
  if id notin spinnerTable:
    spinnerTable[id] = Spinner(
      rec: getRec,
      value: value
    )
  if rg.spinner(getRec, text, spinnerTable[id].value.addr, minValue, maxValue, spinnerTable[id].editMode):
    spinnerTable[id].editMode = not spinnerTable[id].editMode
  spinnerTable[id].value

proc slider(posX, posY, width, height: float, textLeft, textRight: string, value, minValue, maxValue: float): float {.exportpy: "gui_slider".} =
  rg.slider(getRec, textLeft, textRight, value, minValue, maxValue)

proc sliderBar(posX, posY, width, height: float, textLeft, textRight: string, value, minValue, maxValue: float): float {.exportpy: "gui_slider_bar".} =
  rg.sliderBar(getRec, textLeft, textRight, value, minValue, maxValue)

proc loadStyle(fileName: string) {.exportpy: "gui_load_style".} =
  rg.loadStyle(fileName)

proc setState(state: int) {.exportpy: "gui_set_state".} =
  rg.setState(state)
