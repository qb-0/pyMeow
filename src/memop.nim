import 
  encodings, strutils, 
  nimraylib_now/raylib,
  nimpy, nimpy/raw_buffers, 
  nimpy/py_types, memcore

pyExportModule("pyMeow")

proc pointerChain32(process: Process, base: ByteAddress, offsets: openArray[int]): int32 {.exportpy: "pointer_chain_32".} =
  result = process.read(base, int32)
  for offset in offsets[0..^2]:
    result = process.read(result + offset, int32)
  result = result + offsets[^1].int32

proc pointerChain64(process: Process, base: ByteAddress, offsets: openArray[int]): int64 {.exportpy: "pointer_chain_64".} =
  result = process.read(base, int64)
  for offset in offsets[0..^2]:
    result = process.read((result + offset).ByteAddress, int64)
  result = result + offsets[^1]

proc pointerChain(process: Process, baseAddr: ByteAddress, offsets: openArray[int], size: int = 8): ByteAddress {.exportpy: "pointer_chain".} =
  result = if size == 8: process.read(baseAddr, ByteAddress) else: process.read(baseAddr, int32) 
  for o in offsets[0..^2]:
    result = if size == 8: process.read(result + o, ByteAddress) else: process.read(result + o, int32)
  result = result + offsets[^1]

proc readString(process: Process, address: ByteAddress, size: int = 30): string {.exportpy: "r_string".} =
  let s = process.readSeq(address, size, char)
  $cast[cstring](s[0].unsafeAddr)

proc bytesToString(process: Process, address: ByteAddress, size: int): string {.exportpy: "bytes_to_string".} =
  let s = process.readSeq(address, size, char)
  s.join("").convert("utf-8", "utf-16").strip()

proc readInt(process: Process, address: ByteAddress): int32 {.exportpy: "r_int".} = 
  process.read(address, int32)

proc readInts(process: Process, address: ByteAddress, size: int32): seq[int32] {.exportpy: "r_ints".} = 
  process.readSeq(address, size, int32)

proc readInt16(process: Process, address: ByteAddress): int16 {.exportpy: "r_int16".} = 
  process.read(address, int16)

proc readInts16(process: Process, address: ByteAddress, size: int32): seq[int16] {.exportpy: "r_ints16".} = 
  process.readSeq(address, size, int16)

proc readInt64(process: Process, address: ByteAddress): int64 {.exportpy: "r_int64".} = 
  process.read(address, int64)

proc readInts64(process: Process, address: ByteAddress, size: int32): seq[int64] {.exportpy: "r_ints64".} = 
  process.readSeq(address, size, int64)

proc readUInt(process: Process, address: ByteAddress): uint32 {.exportpy: "r_uint".} = 
  process.read(address, uint32)

proc readUInts(process: Process, address: ByteAddress, size: int32): seq[uint32] {.exportpy: "r_uints".} = 
  process.readSeq(address, size, uint32)

proc readUInt64(process: Process, address: ByteAddress): uint64 {.exportpy: "r_uint64".} = 
  process.read(address, uint64)

proc readUInts64(process: Process, address: ByteAddress, size: int32): seq[uint64] {.exportpy: "r_uints64".} = 
  process.readSeq(address, size, uint64)

proc readFloat(process: Process, address: ByteAddress): float32 {.exportpy: "r_float".} = 
  process.read(address, float32)

proc readFloats(process: Process, address: ByteAddress, size: int32): seq[float32] {.exportpy: "r_floats".} = 
  process.readSeq(address, size, float32)

proc readFloat64(process: Process, address: ByteAddress): float64 {.exportpy: "r_float64".} = 
  process.read(address, float64)

proc readFloats64(process: Process, address: ByteAddress, size: int32): seq[float64] {.exportpy: "r_floats64".} = 
  process.readSeq(address, size, float64)

proc readByte(process: Process, address: ByteAddress): byte {.exportpy: "r_byte".} = 
  process.read(address, byte)

proc readBytes(process: Process, address: ByteAddress, size: int32): seq[byte] {.exportpy: "r_bytes".} = 
  process.readSeq(address, size, byte)

proc readVec2(process: Process, address: ByteAddress): Vector2 {.exportpy: "r_vec2".} = 
  process.read(address, Vector2)

proc readVec3(process: Process, address: ByteAddress): Vector3 {.exportpy: "r_vec3".} = 
  process.read(address, Vector3)

proc readBool(process: Process, address: ByteAddress): bool {.exportpy: "r_bool".} = 
  process.read(address, byte).bool

proc readCType(process: Process, address: ByteAddress, ctype: PyObject): PPyObject {.exportpy: "r_ctype".} =
  var pyBuf: RawPyBuffer
  ctype.getBuffer(pyBuf, PyBUF_SIMPLE)
  var memBuf = process.readSeq(address, pyBuf.len, byte)
  moveMem(pyBuf.buf, memBuf[0].addr, memBuf.len)
  result = pyBuf.obj

proc read(process: Process, address: ByteAddress, `type`: string, size: int = 1): PPyObject {.exportpy: "r".} =
  let 
    o = size == 1
    tl = `type`.toLower()

  template r(t: typedesc) =
    if o:
      return nimValueToPy(process.read(address, t))
    return nimValueToPy(process.readSeq(address, size, t))

  case tl:
    of "int", "int32": r(int32)
    of "int16": r(int16)
    of "int64": r(int64)
    of "uint", "uint32": r(uint32)
    of "uint64": r(uint64)
    of "float": r(float32)
    of "float64": r(float64)
    of "byte": r(byte)
    of "vec2": r(Vector2)
    of "vec3": r(Vector3)
    of "bool": r(bool)
    of "str", "string":
      return nimValueToPy(process.readString(address, if size == 1: 30 else: size))
    else:
      raise newException(IOError, "Unknown data type: " & tl)

proc writeString(process: Process, address: ByteAddress, data: string) {.exportpy: "w_string".} =
  process.writeArray(address, data.cstring.toOpenArrayByte(0, data.high))

template writeData = 
  process.write(address, data)

template writeDatas = 
  process.writeArray(address, data)

proc writeInt(process: Process, address: ByteAddress, data: int32) {.exportpy: "w_int".} = 
  writeData

proc writeInts(process: Process, address: ByteAddress, data: openArray[int32]) {.exportpy: "w_ints".} = 
  writeDatas

proc writeInt16(process: Process, address: ByteAddress, data: int16) {.exportpy: "w_int16".} = 
  writeData

proc writeInts16(process: Process, address: ByteAddress, data: openArray[int16]) {.exportpy: "w_ints16".} = 
  writeDatas

proc writeInt64(process: Process, address: ByteAddress, data: int64) {.exportpy: "w_int64".} = 
  writeData

proc writeInts64(process: Process, address: ByteAddress, data: openArray[int64]) {.exportpy: "w_ints64".} = 
  writeDatas

proc writeUInt(process: Process, address: ByteAddress, data: uint32) {.exportpy: "w_uint".} = 
  writeData

proc writeUInts(process: Process, address: ByteAddress, data: openArray[uint32]) {.exportpy: "w_uints".} = 
  writeDatas

proc writeUInt64(process: Process, address: ByteAddress, data: uint64) {.exportpy: "w_uint64".} = 
  writeData

proc writeUInts64(process: Process, address: ByteAddress, data: openArray[uint64]) {.exportpy: "w_uints64".} = 
  writeDatas

proc writeFloat(process: Process, address: ByteAddress, data: float32) {.exportpy: "w_float".} = 
  writeData

proc writeFloats(process: Process, address: ByteAddress, data: openArray[float32]) {.exportpy: "w_floats".} = 
  writeDatas

proc writeFloat64(process: Process, address: ByteAddress, data: float64) {.exportpy: "w_float64".} = 
  writeData

proc writeFloats64(process: Process, address: ByteAddress, data: openArray[float64]) {.exportpy: "w_floats64".} = 
  writeDatas

proc writeByte(process: Process, address: ByteAddress, data: byte) {.exportpy: "w_byte".} = 
  writeData

proc writeBytes(process: Process, address: ByteAddress, data: openArray[byte]) {.exportpy: "w_bytes".} = 
  writeDatas

proc writeVec2(process: Process, address: ByteAddress, data: Vector2) {.exportpy: "w_vec2".} = 
  writeData

proc writeVec3(process: Process, address: ByteAddress, data: Vector3) {.exportpy: "w_vec3".} = 
  writeData

proc writeBool(process: Process, address: ByteAddress, data: bool) {.exportpy: "w_bool".} = 
  process.write(address, data.byte)

proc writeCType(process: Process, address: ByteAddress, data: PyObject) {.exportpy: "w_ctype".} =
  var pyBuf: RawPyBuffer
  data.getBuffer(pyBuf, PyBUF_SIMPLE)
  var memBuf = newSeq[byte](pyBuf.len)
  copyMem(memBuf[0].addr, pyBuf.buf, pyBuf.len)
  process.writeArray(address, memBuf)

proc write(process: Process, address: ByteAddress, data: PPyObject, `type`: string) {.exportpy: "w".} =
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
    of "int16": w(int16)
    of "int64": w(int64)
    of "uint", "uint32": w(uint32)
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