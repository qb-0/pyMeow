import 
  encodings, strutils, 
  nimraylib_now/raylib,
  nimpy, memcore

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