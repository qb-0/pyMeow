#[
  Credits to:
    - https://github.com/ba0f3/ptrace.nim
    - https://guidedhacking.com/members/obdr.128625/

  Currently just x64 processes are supported
]#

import
  posix, strformat,
  strscans, strutils

{.pragma: sys, importc, header: "sys/syscall.h".}

proc ptrace[T](request: cint, pid: int, a: pointer, data: T): pointer {.cdecl, importc, header: "sys/ptrace.h", discardable.}

const
  PTRACE_TRACEME* = 0
  PTRACE_PEEKTEXT* = 1
  PTRACE_PEEKDATA* = 2
  PTRACE_PEEKUSER* = 3
  PTRACE_POKETEXT* = 4
  PTRACE_POKEDATA* = 5
  PTRACE_POKEUSER* = 6
  PTRACE_CONT* = 7
  PTRACE_KILL* = 8
  PTRACE_SINGLESTEP* = 9
  PTRACE_GETREGS* = 12
  PTRACE_SETREGS* = 13
  PTRACE_ATTACH* = 16
  PTRACE_DETACH* = 17
  PTRACE_SYSCALL* = 24
  PTRACE_SETOPTIONS* = 0x4200
  PTRACE_GETEVENTMSG* = 0x4201
  PTRACE_GETSIGINFO* = 0x4202
  PTRACE_SETSIGINFO* = 0x4203
  PTRACE_SEIZE* = 0x4206
  PTRACE_INTERRUPT* = 0x4207
  PTRACE_LISTEN* = 0x4208

let
  SYS_llseek* {.sys, importc: "SYS__llseek".}: cint
  SYS_newselect* {.sys, importc: "SYS__newselect".}: cint
  SYS_sysctl* {.sys, importc: "SYS_sysctl".}: cint
  SYS_access* {.sys.}: cint
  SYS_acct* {.sys.}: cint
  SYS_add_key* {.sys.}: cint
  SYS_adjtimex* {.sys.}: cint
  SYS_afs_syscall* {.sys.}: cint
  SYS_alarm* {.sys.}: cint
  SYS_bdflush* {.sys.}: cint
  SYS_bpf* {.sys.}: cint
  SYS_break* {.sys.}: cint
  SYS_brk* {.sys.}: cint
  SYS_capget* {.sys.}: cint
  SYS_capset* {.sys.}: cint
  SYS_chdir* {.sys.}: cint
  SYS_chmod* {.sys.}: cint
  SYS_chown* {.sys.}: cint
  SYS_chown32* {.sys.}: cint
  SYS_chroot* {.sys.}: cint
  SYS_clock_adjtime* {.sys.}: cint
  SYS_clock_getres* {.sys.}: cint
  SYS_clock_gettime* {.sys.}: cint
  SYS_clock_nanosleep* {.sys.}: cint
  SYS_clock_settime* {.sys.}: cint
  SYS_clone* {.sys.}: cint
  SYS_close* {.sys.}: cint
  SYS_creat* {.sys.}: cint
  SYS_create_module* {.sys.}: cint
  SYS_delete_module* {.sys.}: cint
  SYS_dup* {.sys.}: cint
  SYS_dup2* {.sys.}: cint
  SYS_dup3* {.sys.}: cint
  SYS_epoll_create* {.sys.}: cint
  SYS_epoll_create1* {.sys.}: cint
  SYS_epoll_ctl* {.sys.}: cint
  SYS_epoll_pwait* {.sys.}: cint
  SYS_epoll_wait* {.sys.}: cint
  SYS_eventfd* {.sys.}: cint
  SYS_eventfd2* {.sys.}: cint
  SYS_execve* {.sys.}: cint
  SYS_execveat* {.sys.}: cint
  SYS_exit* {.sys.}: cint
  SYS_exit_group* {.sys.}: cint
  SYS_faccessat* {.sys.}: cint
  SYS_fadvise64* {.sys.}: cint
  SYS_fadvise64_64* {.sys.}: cint
  SYS_fallocate* {.sys.}: cint
  SYS_fanotify_init* {.sys.}: cint
  SYS_fanotify_mark* {.sys.}: cint
  SYS_fchdir* {.sys.}: cint
  SYS_fchmod* {.sys.}: cint
  SYS_fchmodat* {.sys.}: cint
  SYS_fchown* {.sys.}: cint
  SYS_fchown32* {.sys.}: cint
  SYS_fchownat* {.sys.}: cint
  SYS_fcntl* {.sys.}: cint
  SYS_fcntl64* {.sys.}: cint
  SYS_fdatasync* {.sys.}: cint
  SYS_fgetxattr* {.sys.}: cint
  SYS_finit_module* {.sys.}: cint
  SYS_flistxattr* {.sys.}: cint
  SYS_flock* {.sys.}: cint
  SYS_fork* {.sys.}: cint
  SYS_fremovexattr* {.sys.}: cint
  SYS_fsetxattr* {.sys.}: cint
  SYS_fstat* {.sys.}: cint
  SYS_fstat64* {.sys.}: cint
  SYS_fstatat64* {.sys.}: cint
  SYS_fstatfs* {.sys.}: cint
  SYS_fstatfs64* {.sys.}: cint
  SYS_fsync* {.sys.}: cint
  SYS_ftime* {.sys.}: cint
  SYS_ftruncate* {.sys.}: cint
  SYS_ftruncate64* {.sys.}: cint
  SYS_futex* {.sys.}: cint
  SYS_futimesat* {.sys.}: cint
  SYS_get_kernel_syms* {.sys.}: cint
  SYS_get_mempolicy* {.sys.}: cint
  SYS_get_robust_list* {.sys.}: cint
  SYS_get_thread_area* {.sys.}: cint
  SYS_getcpu* {.sys.}: cint
  SYS_getcwd* {.sys.}: cint
  SYS_getdents* {.sys.}: cint
  SYS_getdents64* {.sys.}: cint
  SYS_getegid* {.sys.}: cint
  SYS_getegid32* {.sys.}: cint
  SYS_geteuid* {.sys.}: cint
  SYS_geteuid32* {.sys.}: cint
  SYS_getgid* {.sys.}: cint
  SYS_getgid32* {.sys.}: cint
  SYS_getgroups* {.sys.}: cint
  SYS_getgroups32* {.sys.}: cint
  SYS_getitimer* {.sys.}: cint
  SYS_getpgid* {.sys.}: cint
  SYS_getpgrp* {.sys.}: cint
  SYS_getpid* {.sys.}: cint
  SYS_getpmsg* {.sys.}: cint
  SYS_getppid* {.sys.}: cint
  SYS_getpriority* {.sys.}: cint
  SYS_getrandom* {.sys.}: cint
  SYS_getresgid* {.sys.}: cint
  SYS_getresgid32* {.sys.}: cint
  SYS_getresuid* {.sys.}: cint
  SYS_getresuid32* {.sys.}: cint
  SYS_getrlimit* {.sys.}: cint
  SYS_getrusage* {.sys.}: cint
  SYS_getsid* {.sys.}: cint
  SYS_gettid* {.sys.}: cint
  SYS_gettimeofday* {.sys.}: cint
  SYS_getuid* {.sys.}: cint
  SYS_getuid32* {.sys.}: cint
  SYS_getxattr* {.sys.}: cint
  SYS_gtty* {.sys.}: cint
  SYS_idle* {.sys.}: cint
  SYS_init_module* {.sys.}: cint
  SYS_inotify_add_watch* {.sys.}: cint
  SYS_inotify_init* {.sys.}: cint
  SYS_inotify_init1* {.sys.}: cint
  SYS_inotify_rm_watch* {.sys.}: cint
  SYS_io_cancel* {.sys.}: cint
  SYS_io_destroy* {.sys.}: cint
  SYS_io_getevents* {.sys.}: cint
  SYS_io_setup* {.sys.}: cint
  SYS_io_submit* {.sys.}: cint
  SYS_ioctl* {.sys.}: cint
  SYS_ioperm* {.sys.}: cint
  SYS_iopl* {.sys.}: cint
  SYS_ioprio_get* {.sys.}: cint
  SYS_ioprio_set* {.sys.}: cint
  SYS_ipc* {.sys.}: cint
  SYS_kcmp* {.sys.}: cint
  SYS_kexec_load* {.sys.}: cint
  SYS_keyctl* {.sys.}: cint
  SYS_kill* {.sys.}: cint
  SYS_lchown* {.sys.}: cint
  SYS_lchown32* {.sys.}: cint
  SYS_lgetxattr* {.sys.}: cint
  SYS_link* {.sys.}: cint
  SYS_linkat* {.sys.}: cint
  SYS_listxattr* {.sys.}: cint
  SYS_llistxattr* {.sys.}: cint
  SYS_lock* {.sys.}: cint
  SYS_lookup_dcookie* {.sys.}: cint
  SYS_lremovexattr* {.sys.}: cint
  SYS_lseek* {.sys.}: cint
  SYS_lsetxattr* {.sys.}: cint
  SYS_lstat* {.sys.}: cint
  SYS_lstat64* {.sys.}: cint
  SYS_madvise* {.sys.}: cint
  SYS_mbind* {.sys.}: cint
  SYS_memfd_create* {.sys.}: cint
  SYS_migrate_pages* {.sys.}: cint
  SYS_mincore* {.sys.}: cint
  SYS_mkdir* {.sys.}: cint
  SYS_mkdirat* {.sys.}: cint
  SYS_mknod* {.sys.}: cint
  SYS_mknodat* {.sys.}: cint
  SYS_mlock* {.sys.}: cint
  SYS_mlockall* {.sys.}: cint
  SYS_mmap* {.sys.}: cint
  SYS_mmap2* {.sys.}: cint
  SYS_modify_ldt* {.sys.}: cint
  SYS_mount* {.sys.}: cint
  SYS_move_pages* {.sys.}: cint
  SYS_mprotect* {.sys.}: cint
  SYS_mpx* {.sys.}: cint
  SYS_mq_getsetattr* {.sys.}: cint
  SYS_mq_notify* {.sys.}: cint
  SYS_mq_open* {.sys.}: cint
  SYS_mq_timedreceive* {.sys.}: cint
  SYS_mq_timedsend* {.sys.}: cint
  SYS_mq_unlink* {.sys.}: cint
  SYS_mremap* {.sys.}: cint
  SYS_msync* {.sys.}: cint
  SYS_munlock* {.sys.}: cint
  SYS_munlockall* {.sys.}: cint
  SYS_munmap* {.sys.}: cint
  SYS_name_to_handle_at* {.sys.}: cint
  SYS_nanosleep* {.sys.}: cint
  SYS_nfsservctl* {.sys.}: cint
  SYS_nice* {.sys.}: cint
  SYS_oldfstat* {.sys.}: cint
  SYS_oldlstat* {.sys.}: cint
  SYS_oldolduname* {.sys.}: cint
  SYS_oldstat* {.sys.}: cint
  SYS_olduname* {.sys.}: cint
  SYS_open* {.sys.}: cint
  SYS_open_by_handle_at* {.sys.}: cint
  SYS_openat* {.sys.}: cint
  SYS_pause* {.sys.}: cint
  SYS_perf_event_open* {.sys.}: cint
  SYS_personality* {.sys.}: cint
  SYS_pipe* {.sys.}: cint
  SYS_pipe2* {.sys.}: cint
  SYS_pivot_root* {.sys.}: cint
  SYS_poll* {.sys.}: cint
  SYS_ppoll* {.sys.}: cint
  SYS_prctl* {.sys.}: cint
  SYS_pread64* {.sys.}: cint
  SYS_preadv* {.sys.}: cint
  SYS_prlimit64* {.sys.}: cint
  SYS_process_vm_readv* {.sys.}: cint
  SYS_process_vm_writev* {.sys.}: cint
  SYS_prof* {.sys.}: cint
  SYS_profil* {.sys.}: cint
  SYS_pselect6* {.sys.}: cint
  SYS_ptrace* {.sys.}: cint
  SYS_putpmsg* {.sys.}: cint
  SYS_pwrite64* {.sys.}: cint
  SYS_pwritev* {.sys.}: cint
  SYS_query_module* {.sys.}: cint
  SYS_quotactl* {.sys.}: cint
  SYS_read* {.sys.}: cint
  SYS_readahead* {.sys.}: cint
  SYS_readdir* {.sys.}: cint
  SYS_readlink* {.sys.}: cint
  SYS_readlinkat* {.sys.}: cint
  SYS_readv* {.sys.}: cint
  SYS_reboot* {.sys.}: cint
  SYS_recvmmsg* {.sys.}: cint
  SYS_remap_file_pages* {.sys.}: cint
  SYS_removexattr* {.sys.}: cint
  SYS_rename* {.sys.}: cint
  SYS_renameat* {.sys.}: cint
  SYS_renameat2* {.sys.}: cint
  SYS_request_key* {.sys.}: cint
  SYS_restart_syscall* {.sys.}: cint
  SYS_rmdir* {.sys.}: cint
  SYS_rt_sigaction* {.sys.}: cint
  SYS_rt_sigpending* {.sys.}: cint
  SYS_rt_sigprocmask* {.sys.}: cint
  SYS_rt_sigqueueinfo* {.sys.}: cint
  SYS_rt_sigreturn* {.sys.}: cint
  SYS_rt_sigsuspend* {.sys.}: cint
  SYS_rt_sigtimedwait* {.sys.}: cint
  SYS_rt_tgsigqueueinfo* {.sys.}: cint
  SYS_sched_get_priority_max* {.sys.}: cint
  SYS_sched_get_priority_min* {.sys.}: cint
  SYS_sched_getaffinity* {.sys.}: cint
  SYS_sched_getattr* {.sys.}: cint
  SYS_sched_getparam* {.sys.}: cint
  SYS_sched_getscheduler* {.sys.}: cint
  SYS_sched_rr_get_interval* {.sys.}: cint
  SYS_sched_setaffinity* {.sys.}: cint
  SYS_sched_setattr* {.sys.}: cint
  SYS_sched_setparam* {.sys.}: cint
  SYS_sched_setscheduler* {.sys.}: cint
  SYS_sched_yield* {.sys.}: cint
  SYS_seccomp* {.sys.}: cint
  SYS_select* {.sys.}: cint
  SYS_sendfile* {.sys.}: cint
  SYS_sendfile64* {.sys.}: cint
  SYS_sendmmsg* {.sys.}: cint
  SYS_set_mempolicy* {.sys.}: cint
  SYS_set_robust_list* {.sys.}: cint
  SYS_set_thread_area* {.sys.}: cint
  SYS_set_tid_address* {.sys.}: cint
  SYS_setdomainname* {.sys.}: cint
  SYS_setfsgid* {.sys.}: cint
  SYS_setfsgid32* {.sys.}: cint
  SYS_setfsuid* {.sys.}: cint
  SYS_setfsuid32* {.sys.}: cint
  SYS_setgid* {.sys.}: cint
  SYS_setgid32* {.sys.}: cint
  SYS_setgroups* {.sys.}: cint
  SYS_setgroups32* {.sys.}: cint
  SYS_sethostname* {.sys.}: cint
  SYS_setitimer* {.sys.}: cint
  SYS_setns* {.sys.}: cint
  SYS_setpgid* {.sys.}: cint
  SYS_setpriority* {.sys.}: cint
  SYS_setregid* {.sys.}: cint
  SYS_setregid32* {.sys.}: cint
  SYS_setresgid* {.sys.}: cint
  SYS_setresgid32* {.sys.}: cint
  SYS_setresuid* {.sys.}: cint
  SYS_setresuid32* {.sys.}: cint
  SYS_setreuid* {.sys.}: cint
  SYS_setreuid32* {.sys.}: cint
  SYS_setrlimit* {.sys.}: cint
  SYS_setsid* {.sys.}: cint
  SYS_settimeofday* {.sys.}: cint
  SYS_setuid* {.sys.}: cint
  SYS_setuid32* {.sys.}: cint
  SYS_setxattr* {.sys.}: cint
  SYS_sgetmask* {.sys.}: cint
  SYS_sigaction* {.sys.}: cint
  SYS_sigaltstack* {.sys.}: cint
  SYS_signal* {.sys.}: cint
  SYS_signalfd* {.sys.}: cint
  SYS_signalfd4* {.sys.}: cint
  SYS_sigpending* {.sys.}: cint
  SYS_sigprocmask* {.sys.}: cint
  SYS_sigreturn* {.sys.}: cint
  SYS_sigsuspend* {.sys.}: cint
  SYS_socketcall* {.sys.}: cint
  SYS_splice* {.sys.}: cint
  SYS_ssetmask* {.sys.}: cint
  SYS_stat* {.sys.}: cint
  SYS_stat64* {.sys.}: cint
  SYS_statfs* {.sys.}: cint
  SYS_statfs64* {.sys.}: cint
  SYS_stime* {.sys.}: cint
  SYS_stty* {.sys.}: cint
  SYS_swapoff* {.sys.}: cint
  SYS_swapon* {.sys.}: cint
  SYS_symlink* {.sys.}: cint
  SYS_symlinkat* {.sys.}: cint
  SYS_sync* {.sys.}: cint
  SYS_sync_file_range* {.sys.}: cint
  SYS_syncfs* {.sys.}: cint
  SYS_sysfs* {.sys.}: cint
  SYS_sysinfo* {.sys.}: cint
  SYS_syslog* {.sys.}: cint
  SYS_tee* {.sys.}: cint
  SYS_tgkill* {.sys.}: cint
  SYS_time* {.sys.}: cint
  SYS_timer_create* {.sys.}: cint
  SYS_timer_delete* {.sys.}: cint
  SYS_timer_getoverrun* {.sys.}: cint
  SYS_timer_gettime* {.sys.}: cint
  SYS_timer_settime* {.sys.}: cint
  SYS_timerfd_create* {.sys.}: cint
  SYS_timerfd_gettime* {.sys.}: cint
  SYS_timerfd_settime* {.sys.}: cint
  SYS_times* {.sys.}: cint
  SYS_tkill* {.sys.}: cint
  SYS_truncate* {.sys.}: cint
  SYS_truncate64* {.sys.}: cint
  SYS_ugetrlimit* {.sys.}: cint
  SYS_ulimit* {.sys.}: cint
  SYS_umask* {.sys.}: cint
  SYS_umount* {.sys.}: cint
  SYS_umount2* {.sys.}: cint
  SYS_uname* {.sys.}: cint
  SYS_unlink* {.sys.}: cint
  SYS_unlinkat* {.sys.}: cint
  SYS_unshare* {.sys.}: cint
  SYS_uselib* {.sys.}: cint
  SYS_ustat* {.sys.}: cint
  SYS_utime* {.sys.}: cint
  SYS_utimensat* {.sys.}: cint
  SYS_utimes* {.sys.}: cint
  SYS_vfork* {.sys.}: cint
  SYS_vhangup* {.sys.}: cint
  SYS_vm86* {.sys.}: cint
  SYS_vm86old* {.sys.}: cint
  SYS_vmsplice* {.sys.}: cint
  SYS_vserver* {.sys.}: cint
  SYS_wait4* {.sys.}: cint
  SYS_waitid* {.sys.}: cint
  SYS_waitpid* {.sys.}: cint
  SYS_write* {.sys.}: cint
  SYS_writev* {.sys.}: cint

type
  Registers = object
    r15: pointer
    r14: pointer
    r13: pointer
    r12: pointer
    rbp: pointer
    rbx: pointer
    r11: pointer
    r10: pointer
    r9: pointer
    r8: pointer
    rax: pointer
    rcx: pointer
    rdx: pointer
    rsi: pointer
    rdi: pointer
    origRax: pointer
    rip: pointer
    cs: pointer
    eflags: pointer
    rsp: pointer
    ss: pointer
    fsBase: pointer
    gsBase: pointer
    ds: pointer
    es: pointer
    fs: pointer
    gs: pointer

proc injectSyscall(pid: int, syscall: int, arg0, arg1, arg2, arg3, arg4, arg5: pointer): pointer {.discardable.} =
  var
    status: cint
    regs, oldRegs: Registers
    injectionAddr: pointer

  let injectionBuf = [0x0f.byte, 0x05, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90]

  ptrace(PTRACE_ATTACH, pid, nil, nil)
  wait(status.addr)
  ptrace(PTRACE_GETREGS, pid, nil, oldRegs.addr)
  regs = oldRegs
  regs.rax = cast[pointer](syscall)
  regs.rdi = arg0
  regs.rsi = arg1
  regs.rdx = arg2
  regs.r10 = arg3
  regs.r8 = arg4
  regs.r9 = arg5
  injectionAddr = cast[pointer](regs.rip)
  var oldData = ptrace(PTRACE_PEEKDATA, pid, injectionAddr, 0)
  ptrace(PTRACE_POKEDATA, pid, injectionAddr, cast[pointer](injectionBuf))
  ptrace(PTRACE_SETREGS, pid, nil, regs.addr)
  ptrace(PTRACE_SINGLESTEP, pid, nil, nil)
  discard waitpid(pid.cint, status, WSTOPPED)
  ptrace(PTRACE_GETREGS, pid, nil, regs.addr)
  result = cast[pointer](regs.rax)
  ptrace(PTRACE_POKEDATA, pid, injectionAddr, oldData)
  ptrace(PTRACE_SETREGS, pid, nil, oldRegs.addr)
  ptrace(PTRACE_DETACH, pid, nil, nil)

proc pageProtection*(pid, src, protection: int) =
  var pageStart, pageEnd: int
  for l in lines(fmt"/proc/{pid}/maps"):
    discard scanf(l, "$h-$h", pageStart, pageEnd)
    if src > pageStart and src < pageEnd:
      break
  injectSyscall(pid, SYS_mprotect, cast[pointer](pageStart), cast[pointer](pageEnd), cast[pointer](protection), nil, nil, nil)

proc allocateMemory*(pid, size, protection: int): uint =
  let ret = injectSyscall(pid, SYS_mmap, nil, cast[pointer](size), cast[pointer](protection), cast[pointer](MAP_ANONYMOUS or MAP_PRIVATE), cast[pointer](-1), nil)
  cast[uint](ret)