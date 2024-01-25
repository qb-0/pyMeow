import
  encodings, strutils,
  nimraylib_now/raylib,
  nimpy, nimpy/raw_buffers,
  nimpy/py_types, memcore

pyExportModule("pyMeow")

proc pointerChain32(process: Process, base: uint, offsets: openArray[uint]): uint32 {.exportpy: "pointer_chain_32".} =
  result = process.read(base, uint32)
  for offset in offsets[0..^2]:
    result = process.read(result + offset, uint32)
  result = (result + offsets[^1]).uint32

proc pointerChain64(process: Process, base: uint, offsets: openArray[uint]): uint64 {.exportpy: "pointer_chain_64".} =
  result = process.read(base, uint64)
  for offset in offsets[0..^2]:
    result = process.read(result + offset, uint64)
  result = result + offsets[^1]

proc readString(process: Process, address: uint, size: uint = 30): string {.exportpy: "r_string".} =
  let s = process.readSeq(address, size, char)
  $cast[cstring](s[0].unsafeAddr)

proc bytesToString(process: Process, address: uint, size: uint): string {.exportpy: "bytes_to_string".} =
  let s = process.readSeq(address, size, char)
  s.join("").convert("utf-8", "utf-16").strip()

proc readInt(process: Process, address: uint): int32 {.exportpy: "r_int".} =
  process.read(address, int32)

proc readInts(process: Process, address, size: uint): seq[int32] {.exportpy: "r_ints".} =
  process.readSeq(address, size, int32)

proc readInt8(process: Process, address: uint): int8 {.exportpy: "r_int8".} =
  process.read(address, int8)

proc readInts8(process: Process, address, size: uint): seq[int8] {.exportpy: "r_ints8".} =
  process.readSeq(address, size, int8)

proc readInt16(process: Process, address: uint): int16 {.exportpy: "r_int16".} =
  process.read(address, int16)

proc readInts16(process: Process, address, size: uint): seq[int16] {.exportpy: "r_ints16".} =
  process.readSeq(address, size, int16)

proc readInt64(process: Process, address: uint): int64 {.exportpy: "r_int64".} =
  process.read(address, int64)

proc readInts64(process: Process, address, size: uint): seq[int64] {.exportpy: "r_ints64".} =
  process.readSeq(address, size, int64)

proc readUInt(process: Process, address: uint): uint32 {.exportpy: "r_uint".} =
  process.read(address, uint32)

proc readUInts(process: Process, address, size: uint): seq[uint32] {.exportpy: "r_uints".} =
  process.readSeq(address, size, uint32)

proc readUInt16(process: Process, address: uint): uint16 {.exportpy: "r_uint16".} =
  process.read(address, uint16)

proc readUInts16(process: Process, address, size: uint): seq[uint16] {.exportpy: "r_uints16".} =
  process.readSeq(address, size, uint16)

proc readUInt64(process: Process, address: uint): uint64 {.exportpy: "r_uint64".} =
  process.read(address, uint64)

proc readUInts64(process: Process, address, size: uint): seq[uint64] {.exportpy: "r_uints64".} =
  process.readSeq(address, size, uint64)

proc readFloat(process: Process, address: uint): float32 {.exportpy: "r_float".} =
  process.read(address, float32)

proc readFloats(process: Process, address, size: uint): seq[float32] {.exportpy: "r_floats".} =
  process.readSeq(address, size, float32)

proc readFloat64(process: Process, address: uint): float64 {.exportpy: "r_float64".} =
  process.read(address, float64)

proc readFloats64(process: Process, address, size: uint): seq[float64] {.exportpy: "r_floats64".} =
  process.readSeq(address, size, float64)

proc readByte(process: Process, address: uint): byte {.exportpy: "r_byte".} =
  process.read(address, byte)

proc readBytes(process: Process, address, size: uint): seq[byte] {.exportpy: "r_bytes".} =
  process.readSeq(address, size)

proc readVec2(process: Process, address: uint): Vector2 {.exportpy: "r_vec2".} =
  process.read(address, Vector2)

proc readVec3(process: Process, address: uint): Vector3 {.exportpy: "r_vec3".} =
  process.read(address, Vector3)

proc readBool(process: Process, address: uint): bool {.exportpy: "r_bool".} =
  process.read(address, byte).bool

proc readCType(process: Process, address: uint, ctype: PyObject): PPyObject {.exportpy: "r_ctype".} =
  var pyBuf: RawPyBuffer
  ctype.getBuffer(pyBuf, PyBUF_SIMPLE)
  process.readPointer(address, pyBuf.buf, pyBuf.len)
  pyBuf.obj

proc read(process: Process, address: uint, `type`: string, size: uint = 1): PPyObject {.exportpy: "r".} =
  let
    o = size == 1
    tl = `type`.toLower()

  template r(t: typedesc) =
    if o:
      return nimValueToPy(process.read(address, t))
    return nimValueToPy(process.readSeq(address, size, t))

  case tl:
    of "int", "int32": r(int32)
    of "int8": r(int8)
    of "int16": r(int16)
    of "int64": r(int64)
    of "uint", "uint32": r(uint32)
    of "uint16": r(uint16)
    of "uint64": r(uint64)
    of "float": r(float32)
    of "float64": r(float64)
    of "byte": r(byte)
    of "vec2": r(Vector2)
    of "vec3": r(Vector3)
    of "bool": r(bool)
    of "str", "string":
      return nimValueToPy(process.readString(address, if o: 30 else: size.int))
    else:
      raise newException(IOError, "Unknown data type: " & tl)

proc writeString(process: Process, address: uint, data: string) {.exportpy: "w_string".} =
  process.writeArray(address, data.cstring.toOpenArrayByte(0, data.high))

template writeData =
  process.write(address, data)

template writeDatas =
  process.writeArray(address, data)

proc writeInt(process: Process, address: uint, data: int32) {.exportpy: "w_int".} =
  writeData

proc writeInts(process: Process, address: uint, data: openArray[int32]) {.exportpy: "w_ints".} =
  writeDatas

proc writeInt8(process: Process, address: uint, data: int8) {.exportpy: "w_int8".} =
  writeData

proc writeInts8(process: Process, address: uint, data: openArray[int8]) {.exportpy: "w_ints8".} =
  writeDatas

proc writeInt16(process: Process, address: uint, data: int16) {.exportpy: "w_int16".} =
  writeData

proc writeInts16(process: Process, address: uint, data: openArray[int16]) {.exportpy: "w_ints16".} =
  writeDatas

proc writeInt64(process: Process, address: uint, data: int64) {.exportpy: "w_int64".} =
  writeData

proc writeInts64(process: Process, address: uint, data: openArray[int64]) {.exportpy: "w_ints64".} =
  writeDatas

proc writeUInt(process: Process, address: uint, data: uint32) {.exportpy: "w_uint".} =
  writeData

proc writeUInts(process: Process, address: uint, data: openArray[uint32]) {.exportpy: "w_uints".} =
  writeDatas

proc writeUInt16(process: Process, address: uint, data: uint16) {.exportpy: "w_uint16".} =
  writeData

proc writeUInts16(process: Process, address: uint, data: openArray[uint16]) {.exportpy: "w_uints16".} =
  writeDatas

proc writeUInt64(process: Process, address: uint, data: uint64) {.exportpy: "w_uint64".} =
  writeData

proc writeUInts64(process: Process, address: uint, data: openArray[uint64]) {.exportpy: "w_uints64".} =
  writeDatas

proc writeFloat(process: Process, address: uint, data: float32) {.exportpy: "w_float".} =
  writeData

proc writeFloats(process: Process, address: uint, data: openArray[float32]) {.exportpy: "w_floats".} =
  writeDatas

proc writeFloat64(process: Process, address: uint, data: float64) {.exportpy: "w_float64".} =
  writeData

proc writeFloats64(process: Process, address: uint, data: openArray[float64]) {.exportpy: "w_floats64".} =
  writeDatas

proc writeByte(process: Process, address: uint, data: byte) {.exportpy: "w_byte".} =
  writeData

proc writeBytes(process: Process, address: uint, data: openArray[byte]) {.exportpy: "w_bytes".} =
  writeDatas

proc writeVec2(process: Process, address: uint, data: Vector2) {.exportpy: "w_vec2".} =
  writeData

proc writeVec3(process: Process, address: uint, data: Vector3) {.exportpy: "w_vec3".} =
  writeData

proc writeBool(process: Process, address: uint, data: bool) {.exportpy: "w_bool".} =
  process.write(address, data.byte)

proc writeCType(process: Process, address: uint, data: PyObject) {.exportpy: "w_ctype".} =
  var pyBuf: RawPyBuffer
  data.getBuffer(pyBuf, PyBUF_SIMPLE)
  process.writePointer(address, pyBuf.buf, pyBuf.len)

proc write(process: Process, address: uint, data: PPyObject, `type`: string) {.exportpy: "w".} =
  let
    pyMod = pyBuiltinsModule()
    l = pyMod.list == pyMod.type(data)
    tl = `type`.toLower()

  template w(t: typedesc) =
    if l:
      var buf: seq[t]
      pyValueToNim(data, buf)
      process.writeArray(address, buf)
    else:
      var buf: t
      pyValueToNim(data, buf)
      process.write(address, buf)

  case tl:
    of "int", "int32": w(int32)
    of "int8": w(int8)
    of "int16": w(int16)
    of "int64": w(int64)
    of "uint", "uint32": w(uint32)
    of "uint16": w(uint16)
    of "uint64": w(uint64)
    of "float": w(float32)
    of "float64": w(float64)
    of "byte": w(byte)
    of "vec2": w(Vector2)
    of "vec3": w(Vector3)
    of "bool": w(bool)
    of "str", "string":
      var buf: string
      pyValueToNim(data, buf)
      process.writeString(address, buf)
    else:
      raise newException(IOError, "Unknown data type: " & tl)