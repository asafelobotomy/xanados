# xanadOS Bubblewrap Gaming Security Profiles
# Modern sandboxing approach for gaming applications
# Personal Use License - see LICENSE file

# Steam with bubblewrap security
# Usage: bwrap --args-file steam.bwrap steam

--unshare-user-try
--unshare-pid
--unshare-uts
--unshare-cgroup-try
--new-session

# Filesystem access
--bind /usr /usr
--ro-bind /bin /bin
--ro-bind /sbin /sbin
--ro-bind /lib /lib
--ro-bind /lib64 /lib64
--ro-bind /etc /etc
--bind /tmp /tmp
--bind /var/tmp /var/tmp

# Home directory (restricted)
--bind-try $HOME/.local/share/Steam $HOME/.local/share/Steam
--bind-try $HOME/.steam $HOME/.steam
--bind-try $HOME/Games $HOME/Games

# Device access for gaming
--dev-bind /dev/dri /dev/dri
--dev-bind /dev/snd /dev/snd
--dev-bind /dev/input /dev/input

# Network access
--share-net

# Display server
--bind-try /tmp/.X11-unix /tmp/.X11-unix
--setenv DISPLAY $DISPLAY

# Audio
--bind-try /run/user/$(id -u)/pulse /run/user/$(id -u)/pulse

# Proc and sys (restricted)
--proc /proc
--bind-try /sys/devices/pci0000:00 /sys/devices/pci0000:00

# Security restrictions
--seccomp 3 3< "$(cat <<'EOF'
# Allow basic syscalls
allow: write
allow: read
allow: open
allow: close
allow: stat
allow: fstat
allow: lstat
allow: poll
allow: lseek
allow: mmap
allow: mprotect
allow: munmap
allow: brk
allow: rt_sigaction
allow: rt_sigprocmask
allow: rt_sigreturn
allow: ioctl
allow: access
allow: pipe
allow: select
allow: sched_yield
allow: mremap
allow: msync
allow: mincore
allow: madvise
allow: shmget
allow: shmat
allow: shmctl
allow: dup
allow: dup2
allow: pause
allow: nanosleep
allow: getitimer
allow: alarm
allow: setitimer
allow: getpid
allow: sendfile
allow: socket
allow: connect
allow: accept
allow: sendto
allow: recvfrom
allow: sendmsg
allow: recvmsg
allow: shutdown
allow: bind
allow: listen
allow: getsockname
allow: getpeername
allow: socketpair
allow: setsockopt
allow: getsockopt
allow: clone
allow: fork
allow: vfork
allow: execve
allow: exit
allow: wait4
allow: kill
allow: uname
allow: semget
allow: semop
allow: semctl
allow: shmdt
allow: msgget
allow: msgsnd
allow: msgrcv
allow: msgctl
allow: fcntl
allow: flock
allow: fsync
allow: fdatasync
allow: truncate
allow: ftruncate
allow: getdents
allow: getcwd
allow: chdir
allow: fchdir
allow: rename
allow: mkdir
allow: rmdir
allow: creat
allow: link
allow: unlink
allow: symlink
allow: readlink
allow: chmod
allow: fchmod
allow: chown
allow: fchown
allow: lchown
allow: umask
allow: gettimeofday
allow: getrlimit
allow: getrusage
allow: sysinfo
allow: times
allow: ptrace
allow: getuid
allow: syslog
allow: getgid
allow: setuid
allow: setgid
allow: geteuid
allow: getegid
allow: setpgid
allow: getppid
allow: getpgrp
allow: setsid
allow: setreuid
allow: setregid
allow: getgroups
allow: setgroups
allow: setresuid
allow: getresuid
allow: setresgid
allow: getresgid
allow: getpgid
allow: setfsuid
allow: setfsgid
allow: getsid
allow: capget
allow: capset
allow: rt_sigpending
allow: rt_sigtimedwait
allow: rt_sigqueueinfo
allow: rt_sigsuspend
allow: sigaltstack
allow: utime
allow: mknod
allow: uselib
allow: personality
allow: ustat
allow: statfs
allow: fstatfs
allow: sysfs
allow: getpriority
allow: setpriority
allow: sched_setparam
allow: sched_getparam
allow: sched_setscheduler
allow: sched_getscheduler
allow: sched_get_priority_max
allow: sched_get_priority_min
allow: sched_rr_get_interval
allow: mlock
allow: munlock
allow: mlockall
allow: munlockall
allow: vhangup
allow: modify_ldt
allow: pivot_root
allow: _sysctl
allow: prctl
allow: arch_prctl
allow: adjtimex
allow: setrlimit
allow: chroot
allow: sync
allow: acct
allow: settimeofday
allow: mount
allow: umount2
allow: swapon
allow: swapoff
allow: reboot
allow: sethostname
allow: setdomainname
allow: iopl
allow: ioperm
allow: create_module
allow: init_module
allow: delete_module
allow: get_kernel_syms
allow: query_module
allow: quotactl
allow: nfsservctl
allow: getpmsg
allow: putpmsg
allow: afs_syscall
allow: tuxcall
allow: security
allow: gettid
allow: readahead
allow: setxattr
allow: lsetxattr
allow: fsetxattr
allow: getxattr
allow: lgetxattr
allow: fgetxattr
allow: listxattr
allow: llistxattr
allow: flistxattr
allow: removexattr
allow: lremovexattr
allow: fremovexattr
allow: tkill
allow: time
allow: futex
allow: sched_setaffinity
allow: sched_getaffinity
allow: set_thread_area
allow: io_setup
allow: io_destroy
allow: io_getevents
allow: io_submit
allow: io_cancel
allow: get_thread_area
allow: lookup_dcookie
allow: epoll_create
allow: epoll_ctl_old
allow: epoll_wait_old
allow: remap_file_pages
allow: getdents64
allow: set_tid_address
allow: restart_syscall
allow: semtimedop
allow: fadvise64
allow: timer_create
allow: timer_settime
allow: timer_gettime
allow: timer_getoverrun
allow: timer_delete
allow: clock_settime
allow: clock_gettime
allow: clock_getres
allow: clock_nanosleep
allow: exit_group
allow: epoll_wait
allow: epoll_ctl
allow: tgkill
allow: utimes
allow: vserver
allow: mbind
allow: set_mempolicy
allow: get_mempolicy
allow: mq_open
allow: mq_unlink
allow: mq_timedsend
allow: mq_timedreceive
allow: mq_notify
allow: mq_getsetattr
allow: kexec_load
allow: waitid
allow: add_key
allow: request_key
allow: keyctl
allow: ioprio_set
allow: ioprio_get
allow: inotify_init
allow: inotify_add_watch
allow: inotify_rm_watch
allow: migrate_pages
allow: openat
allow: mkdirat
allow: mknodat
allow: fchownat
allow: futimesat
allow: newfstatat
allow: unlinkat
allow: renameat
allow: linkat
allow: symlinkat
allow: readlinkat
allow: fchmodat
allow: faccessat
allow: pselect6
allow: ppoll
allow: unshare
allow: set_robust_list
allow: get_robust_list
allow: splice
allow: tee
allow: sync_file_range
allow: vmsplice
allow: move_pages
allow: utimensat
allow: epoll_pwait
allow: signalfd
allow: timerfd_create
allow: eventfd
allow: fallocate
allow: timerfd_settime
allow: timerfd_gettime
allow: accept4
allow: signalfd4
allow: eventfd2
allow: epoll_create1
allow: dup3
allow: pipe2
allow: inotify_init1
allow: preadv
allow: pwritev
allow: rt_tgsigqueueinfo
allow: perf_event_open
allow: recvmmsg
allow: fanotify_init
allow: fanotify_mark
allow: prlimit64
allow: name_to_handle_at
allow: open_by_handle_at
allow: clock_adjtime
allow: syncfs
allow: sendmmsg
allow: setns
allow: getcpu
allow: process_vm_readv
allow: process_vm_writev
allow: kcmp
allow: finit_module
allow: sched_setattr
allow: sched_getattr
allow: renameat2
allow: seccomp
allow: getrandom
allow: memfd_create
allow: kexec_file_load
allow: bpf
allow: execveat
allow: userfaultfd
allow: membarrier
allow: mlock2
allow: copy_file_range
allow: preadv2
allow: pwritev2
allow: pkey_mprotect
allow: pkey_alloc
allow: pkey_free
allow: statx
allow: io_pgetevents
allow: rseq
# Deny dangerous syscalls
errno 1: mount
errno 1: umount2
errno 1: swapon
errno 1: swapoff
errno 1: reboot
errno 1: sethostname
errno 1: setdomainname
errno 1: init_module
errno 1: delete_module
errno 1: quotactl
EOF
)"

# Arguments
--
$@
