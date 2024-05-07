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
    base: uint
    when defined(windows):
      handle: HANDLE

  Module = object
    name: string
    base: uint
    `end`: uint
    size: uint

  Page = object
    start: uint
    `end`: uint
    size: uint

template checkRoot =
  when defined(linux):
    if getuid() != 0:
      raise newException(IOError, "Root access required!")

proc getOSError: tuple[code: int, error: string] {.exportpy: "get_os_error".} =
  when defined(linux):
    (errno.int, $strerror(errno))
  elif defined(windows):
    var errMsg = osErrorMsg(osLastError())
    stripLineEnd(errMsg)
    (osLastError().int, errMsg)

proc getErrorStr: string =
  let err = getOSError()
  result = fmt"[Error: {err.code} - {err.error}]"

proc memoryErr(m: string, address: uint) {.inline.} =
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
  for process in enumProcesses():
    if process.name in processName:
      return process.pid
  raise newException(Exception, fmt"Process '{processName}' not found")

proc getProcessName(pid: int): string {.exportpy: "get_process_name".} =
  for process in enumProcesses():
    if process.pid == pid:
      return process.name
  raise newException(Exception, fmt"Process '{pid}' not found")

proc getProcessPath(process: Process): string {.exportpy: "get_process_path".} =
  const maxPath = 4096
  when defined(linux):
    var path = newString(maxPath)
    discard readlink(fmt"/proc/{process.pid}/exe".cstring, path.cstring, maxPath)
    path.strip()
  elif defined(windows):
    var path: array[maxPath + 1, WCHAR]
    let size = (toInt(sizeof(path) / sizeof(path[0]))).int32
    discard QueryFullProcessImageNameW(process.handle, 0, path[0].addr, size.addr)
    nullTerminated($$path)

iterator enumModules(process: Process): Module {.exportpy: "enum_modules"} =
  when defined(linux):
    var modTable: Table[string, Module]
    for l in lines(fmt"/proc/{process.pid}/maps"):
      let s = l.split("/")
      if s.len > 1:
        var
          pageStart, pageEnd: int
          modName = s[^1]
        discard scanf(l, "$h-$h", pageStart, pageEnd)
        if modName notin modTable:
          modTable[modName] = Module(name: modName)
          modTable[modName].base = pageStart.uint
          modTable[modName].size = pageEnd.uint - modTable[modName].base
        else:
          modTable[modName].size = pageEnd.uint - modTable[modName].base

    for name, module in modTable:
      modTable[name].`end` = module.base + module.size
      yield modTable[name]

  elif defined(windows):
    template yieldModule =
      module.name = nullTerminated($$mEntry.szModule)
      module.base = cast[uint](mEntry.modBaseAddr)
      module.size = mEntry.modBaseSize.uint
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

proc moduleExists(process: Process, moduleName: string): bool {.exportpy: "module_exists".} =
  moduleName in mapIt(toSeq(enumModules(process)), it.name)

proc getModule(process: Process, moduleName: string): Module {.exportpy: "get_module".} =
  for module in enumModules(process):
    if moduleName == module.name:
      return module
  raise newException(Exception, fmt"Module '{moduleName}' not found")

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

  result.debug = debug
  result.pid = sPid
  result.name = getProcessName(sPid)
  result.base = getModule(result, result.name).base

  when defined(windows):
    result.handle = OpenProcess(PROCESS_ALL_ACCESS, FALSE, sPid.DWORD)
    if result.handle == FALSE:
      raise newException(Exception, fmt"Unable to open Process [Pid: {sPid}] {getErrorStr()}")

proc closeProcess(process: Process) {.exportpy: "close_process".} =
  when defined(windows):
    CloseHandle(process.handle)

iterator enumMemoryRegions(process: Process, module: Module): Page {.exportpy: "enum_memory_regions".} =
  var result: Page
  when defined(linux):
    var pageStart, pageEnd: int
    for l in lines(fmt"/proc/{process.pid}/maps"):
      if module.name in l and scanf(l, "$h-$h", pageStart, pageEnd):
        result.start = pageStart.uint
        result.`end` = pageEnd.uint
        result.size = (pageEnd - pageStart).uint
        yield result
  elif defined(windows):
    var
      mbi = MEMORY_BASIC_INFORMATION()
      curAddr = module.base
    while VirtualQueryEx(process.handle, cast[LPCVOID](curAddr), mbi.addr, sizeof(mbi).SIZE_T) != 0 and curAddr != module.`end`:
      result.start = curAddr
      result.`end` = result.start + mbi.RegionSize.uint
      result.size = mbi.RegionSize.uint
      curAddr += result.size
      yield result

proc readPointer*(process: Process, address: uint, dst: pointer, size: int) =
  when defined(linux):
    checkRoot()
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

proc read*(process: Process, address: uint, t: typedesc): t =
  when defined(linux):
    checkRoot()
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

proc writePointer*(process: Process, address: uint, data: pointer, size: int) =
  when defined(linux):
    checkRoot()
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

proc readSeq*(process: Process, address, size: uint, t: typedesc = byte): seq[t] =
  result = newSeq[t](size)
  when defined(linux):
    checkRoot()
    var
      ioSrc, ioDst: IOVec
      bsize = size * sizeof(t).uint

    ioDst.iov_base = result[0].addr
    ioDst.iov_len = bsize
    ioSrc.iov_base = cast[pointer](address)
    ioSrc.iov_len = bsize
    if process_vm_readv(process.pid, ioDst.addr, 1, ioSrc.addr, 1, 0) == -1:
      memoryErr("readSeq", address)
  elif defined(windows):
    if ReadProcessMemory(
      process.handle, cast[pointer](address), result[0].addr, size.int * sizeof(t), nil
    ) == FALSE:
      memoryErr("readSeq", address)

  if process.debug:
    echo "[R] [", type(result), "] 0x", address.toHex(), " -> ", result

proc write*(process: Process, address: uint, data: auto) =
  when defined(linux):
    checkRoot()
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

proc writeArray*[T](process: Process, address: uint, data: openArray[T]): int {.discardable.} =
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

proc aob1(pattern: string, byteBuffer: seq[byte], single: bool): seq[uint] =
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
      if pattern.len > 2:
        let middleIndex = (pattern.len div 2) - 1
        var midHexByteIndex, lastHexByteIndex: int

        for i, hb in pattern:
          if hb != doubleWildCard:
            if not (wildCard in hb):
              if i <= middleIndex or midHexByteIndex == 0:
                midHexByteIndex = i
              lastHexByteIndex = i
            result.add(i)

        if lastHexByteIndex == 0:
          lastHexByteIndex = result[^1]
          discard result.pop()
        else:
          result.delete(result.find(lastHexByteIndex))

        result.delete(result.find(midHexByteIndex))
        result.insert(midHexByteIndex, 1)
        result.insert(lastHexByteIndex, 0)
      else:
        for i, hb in pattern:
          if hb != doubleWildCard:
            result.add(i)

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
      result.add(i.uint)
      if single:
        return

proc aob2(pattern: string, byteBuffer: seq[byte], single: bool): seq[uint] =
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
        result.add(curIndex.uint)
        if single:
          return
        break

proc aobScanModule(process: Process, moduleName, pattern: string, relative: bool = false, single: bool = true, algorithm: int = 0): seq[uint] {.exportpy: "aob_scan_module".} =
  let
    module = getModule(process, moduleName)
    # TODO: Reading a whole module is a bad idea. Read pages instead.
    byteBuffer = process.readSeq(module.base, module.size)

  result = if algorithm == 0: aob1(pattern, byteBuffer, single) else: aob2(pattern, byteBuffer, single)
  if result.len != 0:
    if not relative:
      for i, a in result:
        result[i] += module.base

proc aobScanRange(process: Process, pattern: string, rangeStart, rangeEnd: uint, relative: bool = false, single: bool = true, algorithm: int = 0): seq[uint] {.exportpy: "aob_scan_range".} =
  if rangeStart >= rangeEnd:
    raise newException(Exception, "Invalid range (rangeStart > rangeEnd)")

  let byteBuffer = process.readSeq(rangeStart, rangeEnd - rangeStart)

  result = if algorithm == 0: aob1(pattern, byteBuffer, single) else: aob2(pattern, byteBuffer, single)
  if result.len != 0:
    if not relative:
      for i, a in result:
        result[i] += rangeStart

proc aobScanBytes(pattern: string, byteBuffer: seq[byte], single: bool = true, algorithm: int = 0): seq[uint] {.exportpy: "aob_scan_bytes".} =
  result = if algorithm == 0: aob1(pattern, byteBuffer, single) else: aob2(pattern, byteBuffer, single)

proc pageProtection(process: Process, address: uint, newProtection: int32): int32 {.exportpy: "page_protection".} =
  when defined(linux):
    ptrace.pageProtection(process.pid, address.int, newProtection)
  elif defined(windows):
    var mbi = MEMORY_BASIC_INFORMATION()
    discard VirtualQueryEx(process.handle, cast[LPCVOID](address), mbi.addr, sizeof(mbi).SIZE_T)
    if VirtualProtectEx(process.handle, cast[LPCVOID](address), mbi.RegionSize, newProtection, result.addr) != TRUE:
      raise newException(Exception, fmt"page_protection failed: {getErrorStr()}")

proc allocateMemory(process: Process, size: int, protection: int32 = 0): uint {.exportpy: "allocate_memory".} =
  when defined(linux):
    var prot = PROT_READ or PROT_WRITE or PROT_EXEC
    if protection != 0:
      prot = protection
    ptrace.allocateMemory(process.pid, size, prot)
  elif defined(windows):
    var prot = PAGE_EXECUTE_READWRITE
    if protection != 0:
      prot = protection
    cast[uint](VirtualAllocEx(process.handle, nil, size, MEM_COMMIT or MEM_RESERVE, prot.int32))

proc freeMemory(process: Process, address: uint): bool {.exportpy: "free_memory".} =
  # only windows is currently supported
  when defined(linux):
    echo "[free_memory] only windows is currently supported"
  elif defined(windows):
    VirtualFreeEx(process.handle, cast[LPVOID](address), 0, MEM_RELEASE) == TRUE

proc getProcAddress(moduleName, functionName: string): uint {.exportpy: "get_proc_address".} =
  when defined(windows):
    cast[uint](GetProcAddress(GetModuleHandleA(moduleName.cstring), functionName.cstring))

proc createRemoteThread(process: Process, startAddress: uint, param: uint): bool {.exportpy: "create_remote_thread".} =
  when defined(windows):
    let hRemoteThread = CreateRemoteThread(
      process.handle,
      cast[LPSECURITY_ATTRIBUTES](NULL),
      0.SIZE_T,
      cast[LPTHREAD_START_ROUTINE](startAddress),
      cast[LPVOID](param),
      cast[DWORD](NULL),
      cast[LPDWORD](NULL)
      )
    defer: CloseHandle(hRemoteThread)
    if hRemoteThread != 0.HANDLE:
      result = true
      discard WaitForSingleObject(hRemoteThread, INFINITE)
    VirtualFreeEx(process.handle, startAddress.addr, 0, MEM_RELEASE)

proc inject_library(process: Process, dllPath: string): bool {.exportpy: "inject_library".} =
  when defined(windows):
    let allocaddr = allocateMemory(process, len(dllPath), PAGE_READWRITE)
    writePointer(process, cast[uint](allocaddr), dllPath[0].unsafeAddr, dllPath.len)
    createRemoteThread(process, getProcAddress("kernel32.dll", "LoadLibraryA"), cast[uint](allocaddr))

proc injectShellcode(process: Process, shellcode: string, params: uint =0): bool {.exportpy: "inject_shellcode".} =
  when defined(windows):
    let shellcodeAddr = allocateMemory(process, len(shellcode) + 1, PAGE_EXECUTE_READWRITE)
    writePointer(process, cast[uint](shellcodeAddr), shellcode.cstring, len(shellcode) + 1)
    createRemoteThread(process, cast[uint](shellcodeAddr), params)
