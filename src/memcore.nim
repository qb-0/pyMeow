import 
  os, strformat, sequtils,
  strutils, nimpy

pyExportModule("pyMeow")

when defined(windows):
  import winim
elif defined(linux):
  import 
    posix, strscans, tables,
    ptrace

  proc process_vm_readv(
    pid: int, 
    localIov: ptr IOVec, 
    liovcnt: culong, 
    remoteIov: ptr IOVec, 
    riovcnt: culong, 
    flags: culong
  ): cint {.importc, header: "<sys/uio.h>", discardable.}

  proc process_vm_writev(
      pid: int, 
      localIov: ptr IOVec, 
      liovcnt: culong, 
      remoteIov: ptr IOVec, 
      riovcnt: culong, 
      flags: culong
  ): cint {.importc, header: "<sys/uio.h>", discardable.}

type
  Process* = object
    name: string
    pid: int
    debug: bool
    when defined(windows):
      handle: HANDLE

  Module = object
    name: string
    base: ByteAddress
    `end`: ByteAddress
    size: int

  Page = object
    start: ByteAddress
    `end`: ByteAddress
    size: int

proc checkRoot =
  when defined(linux):
    if getuid() != 0:
      raise newException(IOError, "Root access required!")

proc getErrorStr: string =
  when defined(linux):
    let
      errCode = errno
      errMsg = strerror(errCode)
  elif defined(windows):
    var 
      errCode = osLastError()
      errMsg = osErrorMsg(errCode)
    stripLineEnd(errMsg)
  result = fmt"[Error: {errCode} - {errMsg}]"

proc memoryErr(m: string, address: ByteAddress) {.inline.} =
  raise newException(
    AccessViolationDefect,
    fmt"{m} failed [Address: 0x{address.toHex()}] {getErrorStr()}"
  )

proc is64bit(process: Process): bool {.exportpy: "is_64_bit".} =
  when defined(linux):
    var buffer = newSeq[byte](5)
    let exe = open(fmt"/proc/{process.pid}/exe", fmRead)
    discard exe.readBytes(buffer, 0, 5)
    result = buffer[4] == 2
    close(exe)
  elif defined(windows):
    var wow64: BOOL
    discard IsWow64Process(process.handle, wow64.addr)
    result = wow64 != TRUE

iterator enumProcesses: Process {.exportpy: "enum_processes".} =
  var p: Process
  when defined(linux):
    checkRoot()
    let allFiles = toSeq(walkDir("/proc", relative = true))
    for pid in mapIt(filterIt(allFiles, isDigit(it.path[0])), parseInt(it.path)):
        p.pid = pid
        p.name = readFile(fmt"/proc/{pid}/comm").strip()
        yield p
  elif defined(windows):
    var 
      pe: PROCESSENTRY32
      hResult: WINBOOL
    let hSnapShot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    defer: CloseHandle(hSnapShot)
    pe.dwSize = sizeof(PROCESSENTRY32).DWORD
    hResult = Process32First(hSnapShot, pe.addr)
    while hResult:
      p.name = nullTerminated($$pe.szExeFile)
      p.pid = pe.th32ProcessID
      yield p
      hResult = Process32Next(hSnapShot, pe.addr)

proc pidExists(pid: int): bool {.exportpy: "pid_exists".} =
  pid in mapIt(toSeq(enumProcesses()), it.pid)

proc processExists(processName: string): bool {.exportpy: "process_exists".} =
  processName in mapIt(toSeq(enumProcesses()), it.name)

proc processRunning(process: Process): bool {.exportpy: "process_running".} =
  when defined(linux):
    return kill(process.pid.cint, 0) == 0
  elif defined(windows):
    var exitCode: DWORD
    GetExitCodeProcess(process.handle, exitCode.addr)
    return exitCode == STILL_ACTIVE

proc getProcessId(processName: string): int {.exportpy: "get_process_id".} =
  checkRoot()
  for process in enumProcesses():
    if process.name in processName:
      return process.pid
  raise newException(Exception, fmt"Process '{processName}' not found")

proc getProcessName(pid: int): string {.exportpy: "get_process_name".} =
  checkRoot()
  for process in enumProcesses():
    if process.pid == pid:
      return process.name
  raise newException(Exception, fmt"Process '{pid}' not found")

proc openProcess(process: PyObject, debug: bool = false): Process {.exportpy: "open_process".} =
  let 
    pyMod = pyBuiltinsModule()
    pyInt = pyMod.getAttr("int")
    pyStr = pyMod.str
    objT = pyMod.type(process)

  var sPid: int
  if objT == pyInt:
    sPid = process.to(int)
    if not pidExists(sPid):
      raise newException(Exception, fmt"Process ID '{sPid} does not exist")
  elif objT == pyStr:
    let processName = process.to(string)
    for p in enumProcesses():
      if processName in p.name:
        sPid = p.pid
        break
    if sPid == 0:
      raise newException(Exception, fmt"Process '{processName}' not found")
  else:
    raise newException(Exception, "Process ID or Process Name required")

  checkRoot()
  result.debug = debug
  result.pid = sPid
  result.name = getProcessName(sPid)

  when defined(windows):
    result.handle = OpenProcess(PROCESS_ALL_ACCESS, FALSE, sPid.DWORD)
    if result.handle == FALSE:
      raise newException(Exception, fmt"Unable to open Process [Pid: {sPid}] {getErrorStr()}")
  
proc closeProcess(process: Process) {.exportpy: "close_process".} =
  when defined(windows):
    CloseHandle(process.handle)

iterator enumModules(process: Process): Module {.exportpy: "enum_modules"} =
  when defined(linux):
    checkRoot()
    var modTable: Table[string, Module]
    for l in lines(fmt"/proc/{process.pid}/maps"):
      let s = l.split("/")
      if s.len > 1:
        var 
          pageStart, pageEnd: ByteAddress
          modName = s[^1]
        discard scanf(l, "$h-$h", pageStart, pageEnd)
        if modName notin modTable:
          modTable[modName] = Module(name: modName)
          modTable[modName].base = pageStart
          modTable[modName].size = pageEnd - modTable[modName].base
        else:
          modTable[modName].size = pageEnd - modTable[modName].base
    
    for name, module in modTable:
      modTable[name].`end` = module.base + module.size
      yield modTable[name]

  elif defined(windows):
    template yieldModule =
      module.name = nullTerminated($$mEntry.szModule)
      module.base = cast[ByteAddress](mEntry.modBaseAddr)
      module.size = mEntry.modBaseSize
      module.`end` = module.base + module.size
      yield module

    var
      hSnapShot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE or TH32CS_SNAPMODULE32, process.pid.DWORD)
      mEntry = MODULEENTRY32(dwSize: sizeof(MODULEENTRY32).cint)
      module: Module

    defer: CloseHandle(hSnapShot)
    if Module32First(hSnapShot, mEntry.addr) == TRUE:
      yieldModule()
      while Module32Next(hSnapShot, mEntry.addr) != FALSE:
        yieldModule()

proc getModule(process: Process, moduleName: string): Module {.exportpy: "get_module".} =
  checkRoot()
  for module in enumModules(process):
    if moduleName == module.name:
      return module
  raise newException(Exception, fmt"Module '{moduleName}' not found")

iterator enumMemoryRegions(process: Process, module: Module): Page {.exportpy: "enum_memory_regions".} =
  var result: Page
  when defined(linux):
    checkRoot()
    var pageStart, pageEnd: ByteAddress
    for l in lines(fmt"/proc/{process.pid}/maps"):
      if module.name in l and scanf(l, "$h-$h", result.start, result.`end`):
        result.size = pageEnd - pageStart
        yield result
  elif defined(windows):
    var
      mbi = MEMORY_BASIC_INFORMATION()
      curAddr = module.base
    while VirtualQueryEx(process.handle, cast[LPCVOID](curAddr), mbi.addr, sizeof(mbi).SIZE_T) != 0 and curAddr != module.`end`:
      result.start = curAddr
      result.`end` = result.start + mbi.RegionSize.int
      result.size = mbi.RegionSize.int
      curAddr += result.size
      yield result

proc readPointer*(process: Process, address: ByteAddress, dst: pointer, size: int) =
  when defined(linux):
    var ioSrc, ioDst: IOVec

    ioDst.iov_base = dst
    ioDst.iov_len = size.uint
    ioSrc.iov_base = cast[pointer](address)
    ioSrc.iov_len = size.uint
    if process_vm_readv(process.pid, ioDst.addr, 1, ioSrc.addr, 1, 0) == -1:
      memoryErr("Read", address)
  elif defined(windows):
    if ReadProcessMemory(
      process.handle, cast[pointer](address), dst, size, nil
    ) == FALSE:
      memoryErr("Read", address)

    if process.debug:
      var buf = newSeq[byte](size)
      copyMem(buf[0].addr, dst, size)
      echo "[R] [seq[byte]] 0x", address.toHex(), " -> ", $buf

proc read*(process: Process, address: ByteAddress, t: typedesc): t =
  when defined(linux):
    var
      ioSrc, ioDst: IOVec
      size = sizeof(t).uint

    ioDst.iov_base = result.addr
    ioDst.iov_len = size
    ioSrc.iov_base = cast[pointer](address)
    ioSrc.iov_len = size
    if process_vm_readv(process.pid, ioDst.addr, 1, ioSrc.addr, 1, 0) == -1:
      memoryErr("Read", address)
  elif defined(windows):
    if ReadProcessMemory(
      process.handle, cast[pointer](address), result.addr, sizeof(t), nil
    ) == FALSE:
      memoryErr("Read", address)

  if process.debug:
    echo "[R] [", type(result), "] 0x", address.toHex(), " -> ", result

proc writePointer*(process: Process, address: ByteAddress, data: pointer, size: int) =
  when defined(linux):
    var ioSrc, ioDst: IOVec

    ioSrc.iov_base = data
    ioSrc.iov_len = size.uint
    ioDst.iov_base = cast[pointer](address)
    ioDst.iov_len = size.uint
    if process_vm_writev(process.pid, ioSrc.addr, 1, ioDst.addr, 1, 0) == -1:
      memoryErr("Write", address)
  elif defined(windows):
    if WriteProcessMemory(
      process.handle, cast[pointer](address), data, size, nil
    ) == FALSE:
      memoryErr("Write", address)

  if process.debug:
    var buf = newSeq[byte](size)
    copyMem(buf[0].addr, data, size)
    echo "[W] [seq[byte]] 0x", address.toHex(), " -> ", $buf

proc readSeq*(process: Process, address: ByteAddress, size: int, t: typedesc = byte): seq[t] =
  result = newSeq[t](size)
  when defined(linux):
    var 
      ioSrc, ioDst: IOVec
      bsize = (size * sizeof(t)).uint

    ioDst.iov_base = result[0].addr
    ioDst.iov_len = bsize
    ioSrc.iov_base = cast[pointer](address)
    ioSrc.iov_len = bsize
    if process_vm_readv(process.pid, ioDst.addr, 1, ioSrc.addr, 1, 0) == -1:
      memoryErr("readSeq", address)
  elif defined(windows):
    if ReadProcessMemory(
      process.handle, cast[pointer](address), result[0].addr, size * sizeof(t), nil
    ) == FALSE:
      memoryErr("readSeq", address)

  if process.debug:
    echo "[R] [", type(result), "] 0x", address.toHex(), " -> ", result

proc write*(process: Process, address: ByteAddress, data: auto) =
  when defined(linux):
    var
      ioSrc, ioDst: IOVec
      size = sizeof(data).uint
      d = data

    ioSrc.iov_base = d.addr
    ioSrc.iov_len = size
    ioDst.iov_base = cast[pointer](address)
    ioDst.iov_len = size
    if process_vm_writev(process.pid, ioSrc.addr, 1, ioDst.addr, 1, 0) == -1:
      memoryErr("Write", address)
  elif defined(windows):
    if WriteProcessMemory(
      process.handle, cast[pointer](address), data.unsafeAddr, sizeof(data), nil
    ) == FALSE:
      memoryErr("Write", address)

  if process.debug:
    echo "[W] [", type(data), "] 0x", address.toHex(), " -> ", data

proc writeArray*[T](process: Process, address: ByteAddress, data: openArray[T]): int {.discardable.} =
  when defined(linux):
    var
      ioSrc, ioDst: IOVec
      size = (sizeof(T) * data.len).uint

    ioSrc.iov_base = data.unsafeAddr
    ioSrc.iov_len = size
    ioDst.iov_base = cast[pointer](address)
    ioDst.iov_len = size
    if process_vm_writev(process.pid, ioSrc.addr, 1, ioDst.addr, 1, 0) == -1:
      memoryErr("WriteArray", address)
  elif defined(windows):
    if WriteProcessMemory(
      process.handle, cast[pointer](address), data.unsafeAddr, sizeof(T) * data.len, nil
    ) == FALSE:
      memoryErr("WriteArray", address)
  
  if process.debug:
    echo "[W] [", type(data), "] 0x", address.toHex(), " -> ", data

proc aob1(pattern: string, byteBuffer: seq[byte], single: bool): seq[ByteAddress] =
  # Credits to Iago Beuller
  const
    wildCard = '?'
    doubleWildCard = "??"
    wildCardIntL = 256
    wildCardIntR = 257
    doubleWildCardInt = 258

  proc splitPattern(pattern: string): seq[string] =
    var patt = pattern.replace(" ", "")
    try:
      for i in countup(0, patt.len-1, 2):
        result.add(patt[i..i+1])
    except CatchableError:
      raise newException(Exception, "Invalid pattern")

  proc patternToInts(pattern: seq[string]): seq[int] =
    for hex in pattern:
      if wildCard in hex:
        if hex == doubleWildCard:
          result.add(doubleWildCardInt)
        elif hex[0] == wildCard:
          result.add(wildCardIntL)
        else:
          result.add(wildCardIntR)
      else:
          result.add(parseHexInt(hex))

  proc getIndexMatchOrder(pattern: seq[string]): seq[int] =
    let middleIndex = (pattern.len div 2) - 1
    var midHexByteIndex, lastHexByteIndex: int

    for i, hb in pattern:
      if hb != doubleWildCard:
        if not (wildCard in hb):
          if i <= middleIndex or midHexByteIndex == 0:
            midHexByteIndex = i
          lastHexByteIndex = i
        result.add(i)

    discard result.pop()
    result.delete(result.find(midHexByteIndex))
    result.insert(midHexByteIndex, 1)
    result.insert(lastHexByteIndex, 0)

  let
    hexPattern = splitPattern(pattern)
    intsPattern = patternToInts(hexPattern)
    pIndexMatchOrder = getIndexMatchOrder(hexPattern)

  if pIndexMatchOrder.len == 0:
    return

  var
    found: bool
    b, p: int

  for i in 0..byteBuffer.len-hexPattern.len:
    found = true
    for pId in pIndexMatchOrder:
      b = byteBuffer[i+pId].int
      p = intsPattern[pId]

      if p != b:
        found = false

        if p == wildCardIntL:
          if b.toHex(1)[0] == hexPattern[pId][1]:
            found = true
          else:
            break
        elif p == wildCardIntR and b.toHex(2)[0] == hexPattern[pId][0]:
          found = true
        else:
          break

    if found:
      result.add(i)
      if single:
        return

proc aob2(pattern: string, byteBuffer: seq[byte], single: bool): seq[ByteAddress] =
  const
    wildCard = "??"
    wildCardByte = 200.byte # Not safe

  proc patternToBytes(pattern: string): seq[byte] =
    var patt = pattern.replace(" ", "")
    try:
      for i in countup(0, patt.len-1, 2):
        let hex = patt[i..i+1]
        if hex == wildCard:
          result.add(wildCardByte)
        else:
          result.add(parseHexInt(hex).byte)
    except CatchableError:
      raise newException(Exception, "Invalid pattern")

  let bytePattern = patternToBytes(pattern)
  for curIndex, _ in byteBuffer:
    for sigIndex, s in bytePattern:
      if byteBuffer[curIndex + sigIndex] != s and s != wildCardByte:
        break
      elif sigIndex == bytePattern.len-1:
        result.add(curIndex)
        if single:
          return
        break

proc aobScanModule(process: Process, moduleName, pattern: string, relative: bool = false, single: bool = true, algorithm: int = 0): seq[ByteAddress] {.exportpy: "aob_scan_module".} =
  let 
    module = getModule(process, moduleName)
    # TODO: Reading a whole module is a bad idea. Read pages instead.
    byteBuffer = process.readSeq(module.base, module.size)
  
  result = if algorithm == 0: aob1(pattern, byteBuffer, single) else: aob2(pattern, byteBuffer, single)
  if result.len != 0:
    if not relative:
      for i, a in result:
        result[i] += module.base

proc aobScanRange(process: Process, pattern: string, rangeStart, rangeEnd: ByteAddress, relative: bool = false, single: bool = true, algorithm: int = 0): seq[ByteAddress] {.exportpy: "aob_scan_range".} =
  if rangeStart >= rangeEnd:
    raise newException(Exception, "Invalid range (rangeStart > rangeEnd)")

  let byteBuffer = process.readSeq(rangeStart, rangeEnd - rangeStart)
  
  result = if algorithm == 0: aob1(pattern, byteBuffer, single) else: aob2(pattern, byteBuffer, single)
  if result.len != 0:
    if not relative:
      for i, a in result:
        result[i] += rangeStart

proc pageProtection(process: Process, address: ByteAddress, newProtection: int32): int32 {.exportpy: "page_protection".} =
  when defined(linux):
    ptrace.pageProtection(process.pid, address, newProtection)
  elif defined(windows):
    var mbi = MEMORY_BASIC_INFORMATION()
    discard VirtualQueryEx(process.handle, cast[LPCVOID](address), mbi.addr, sizeof(mbi).SIZE_T)
    discard VirtualProtectEx(process.handle, cast[LPCVOID](address), mbi.RegionSize, newProtection, result.addr)

proc allocateMemory(process: Process, size: int, protection: int32 = 0): ByteAddress {.exportpy: "allocate_memory".} =
  when defined(linux):
    var prot = PROT_READ or PROT_WRITE or PROT_EXEC
    if protection != 0:
      prot = protection
    ptrace.allocateMemory(process.pid, size, prot)
  elif defined(windows):
    var prot = PAGE_EXECUTE_READWRITE
    if protection != 0:
      prot = protection
    cast[ByteAddress](VirtualAllocEx(process.handle, nil, size, MEM_COMMIT or MEM_RESERVE, prot.int32))