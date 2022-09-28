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

var
  DropDownTable: Table[int, DropDownBox]
  TextBoxTable: Table[int, TextBox]
  ColorPickerTable: Table[int, ColorPicker]

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

proc dropdownBox(posX, posY, width, height: float, text: string, id: int): int {.exportpy: "gui_dropdown_box".} =
  if id notin DropDownTable:
    DropDownTable[id] = DropDownBox(
      rec: getRec,
      text: text,
    )
  if rg.dropdownBox(DropDownTable[id].rec, DropDownTable[id].text.cstring, DropDownTable[id].active.addr, DropDownTable[id].editMode):
    DropDownTable[id].editMode = not DropDownTable[id].editMode
  DropDownTable[id].active

proc textBox(posX, posY, width, height: float, id: int): string {.exportpy: "gui_text_box".} =
  if id notin TextBoxTable:
    TextBoxTable[id] = TextBox(
      rec: getRec,
      text: newString(250),
    )
  if rg.textBox(TextBoxTable[id].rec, TextBoxTable[id].text.cstring, TextBoxTable[id].text.len.cint, TextBoxTable[id].editMode):
    TextBoxTable[id].editMode = not TextBoxTable[id].editMode    
  TextBoxTable[id].text

proc progressBar(posX, posY, width, height: float, textLeft, textRight: string, value, minValue, maxValue: float): float {.exportpy: "gui_progress_bar".} =
  rg.progressBar(getRec, textLeft, textRight, value, minValue, maxValue)

proc statusBar(posX, posY, width, height: float, text: string) {.exportpy: "gui_status_bar".} =
  rg.statusBar(getRec, text)

proc messageBox(posX, posY, width, height: float, title, message, buttons: string): int {.exportpy: "gui_message_box".} =
  rg.messageBox(getRec, title, message, buttons)

proc colorPicker(posX, posY, width, height: float, id: int): Color {.exportpy: "gui_color_picker".} =
  if id notin ColorPickerTable:
    ColorPickerTable[id] = ColorPicker(
      rec: getRec,
      color: Raywhite
    )
  ColorPickerTable[id].color = rg.colorPicker(getRec, ColorPickerTable[id].color)
  ColorPickerTable[id].color

proc loadStyle(fileName: string) {.exportpy: "gui_load_style".} =
  rg.loadStyle(fileName)