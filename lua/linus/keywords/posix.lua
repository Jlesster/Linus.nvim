-- linus/keywords/posix.lua
-- POSIX / Linux system call reference.

return {

  -- ── File I/O ──────────────────────────────────────────────────────────────

  ["open"] = [[
**`open`** — Open a file (`<fcntl.h>`)

```c
#include <fcntl.h>
int fd = open("file.txt", O_RDONLY);
int fd = open("file.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);

if (fd == -1) { perror("open"); return; }   // errno set on failure
```

| Flag | Meaning |
|------|---------|
| `O_RDONLY`  | Read only |
| `O_WRONLY`  | Write only |
| `O_RDWR`    | Read and write |
| `O_CREAT`   | Create if doesn't exist |
| `O_TRUNC`   | Truncate to zero length |
| `O_APPEND`  | Append writes to end |
| `O_EXCL`    | Fail if file exists (with O_CREAT) |
| `O_NONBLOCK`| Non-blocking I/O |
| `O_CLOEXEC` | Close on exec (avoid FD leak) |

**See also:** `close`, `read`, `write`, `lseek`, `fcntl`, `creat`]],

  ["creat"] = [[
**`creat`** — Create a file (`<fcntl.h>`)

```c
int fd = creat("file.txt", 0644);   // equivalent to open(..., O_WRONLY|O_CREAT|O_TRUNC)
```

**Less common** than `open(..., O_WRONLY|O_CREAT|O_TRUNC, mode)`. Returns fd or -1.

**See also:** `open`, `close`, `umask`]],

  ["close"] = [[
**`close`** — Close a file descriptor (`<unistd.h>`)

```c
#include <unistd.h>
if (close(fd) == -1) {
    // EBADF: not a valid fd; EINTR: interrupted (rare — retry)
}
```

Closing an already-closed fd (`EBADF`) is a programming error. After `close`, the fd number may be reused by the next `open`/`dup`/`socket`.

**Always close fds** — Linux has a per-process limit (`ulimit -n`, usually 1024).

**See also:** `open`, `read`, `write`, `dup2`, `fdopen`]],

  ["read"] = [[
**`read`** — Read bytes from a file descriptor (`<unistd.h>`)

```c
char buf[4096];
ssize_t n = read(fd, buf, sizeof(buf));
if (n == -1) { /* error — check errno */ }
if (n == 0)  { /* EOF */ }
```

**May read fewer bytes than requested** (short read) — always check the return value. Signals (`EINTR`) may interrupt; loop to retry.

```c
// Robust read loop:
ssize_t total = 0;
while (total < count) {
    ssize_t n = read(fd, buf + total, count - total);
    if (n == -1) { if (errno == EINTR) continue; break; }
    if (n == 0) break;  // EOF
    total += n;
}
```

**See also:** `write`, `pread`, `readv`, `open`]],

  ["write"] = [[
**`write`** — Write bytes to a file descriptor (`<unistd.h>`)

```c
ssize_t n = write(fd, buf, count);
```

May write fewer bytes than requested (short write). Loop to ensure all data written. `EINTR` may occur; retry.

**See also:** `read`, `pwrite`, `writev`, `fsync`]],

  ["lseek"] = [[
**`lseek`** — Reposition file offset (`<unistd.h>`)

```c
off_t pos = lseek(fd, 0, SEEK_SET);     // seek to absolute 0
off_t end = lseek(fd, 0, SEEK_END);     // seek to end
off_t cur = lseek(fd, 0, SEEK_CUR);     // get current position (no seek)
off_t back = lseek(fd, -100, SEEK_CUR); // backwards 100 bytes

if (pos == (off_t)-1) { perror("lseek"); }  // ESPIPE on pipes/sockets
```

**Not supported** for pipes, FIFOs, sockets. Seeking past the end creates a **sparse file** (reads return zero until data is written).

**See also:** `pread`, `pwrite`, `ftruncate`, `fallocate`]],

  ["pread"] = [[
**`pread`** — Atomic read at a given offset (`<unistd.h>`)

```c
ssize_t n = pread(fd, buf, count, offset);
// Equivalent to lseek + read, but atomic — offset is not modified.
```

**See also:** `pwrite`, `read`, `lseek`]],

  ["pwrite"] = [[
**`pwrite`** — Atomic write at a given offset (`<unistd.h>`)

```c
ssize_t n = pwrite(fd, buf, count, offset);
```

**See also:** `pread`, `write`, `lseek`]],

  ["dup"] = [[
**`dup`** — Duplicate a file descriptor (`<unistd.h>`)

```c
int newfd = dup(oldfd);           // picks the lowest available fd number
int newfd = dup2(oldfd, target);  // closes target if open, then duplicates
int newfd = dup3(oldfd, target, O_CLOEXEC);  // dup2 + O_CLOEXEC (Linux 2.6.27)
```

Used for redirecting stdin/stdout/stderr:
```c
int fd = open("out.log", O_WRONLY | O_CREAT | O_TRUNC, 0644);
dup2(fd, STDOUT_FILENO);
close(fd);   // original fd no longer needed
```

**See also:** `open`, `close`, `fcntl`]],

  ["pipe"] = [[
**`pipe`** — Create a unidirectional data channel (`<unistd.h>`)

```c
int fds[2];
pipe(fds);        // fds[0] = read end, fds[1] = write end

// Linux-specific: pipe2(fds, O_CLOEXEC) or pipe2(fds, O_NONBLOCK)
```

Data written to `fds[1]` can be read from `fds[0]`. Common for inter-process communication (fork + exec).

**See also:** `read`, `write`, `fork`, `socketpair`]],

  ["fcntl"] = [[
**`fcntl`** — Manipulate file descriptor (`<fcntl.h>`)

```c
int flags = fcntl(fd, F_GETFL);                 // get flags
fcntl(fd, F_SETFL, flags | O_NONBLOCK);         // set non-blocking

int fd_clone = fcntl(fd, F_DUPFD, 0);           // duplicate (like dup)

// File locking:
struct flock lock = { .l_type = F_WRLCK, .l_whence = SEEK_SET, .l_start = 0, .l_len = 0 };
fcntl(fd, F_SETLK, &lock);                      // non-blocking lock attempt
```

**See also:** `dup`, `open`, `flock`]],

  ["fsync"] = [[
**`fsync`** — Flush cached writes to persistent storage (`<unistd.h>`)

```c
fsync(fd);     // block until data + metadata are written to disk
fdatasync(fd); // like fsync but metadata may be skipped (faster)
```

**Critical for data integrity** — `write` returns before data hits disk (OS caches). `fsync` guarantees durability.

**Performance note:** calling `fsync` on every write hurts throughput. Batch writes and sync periodically.

**See also:** `write`, `open`, `O_SYNC`, `sync`]],

  ["mmap"] = [[
**`mmap`** — Map files or devices into memory (`<sys/mman.h>`)

```c
#include <sys/mman.h>

// Map a file into memory:
int fd = open("data", O_RDONLY);
size_t len = 4096;
char *p = mmap(NULL, len, PROT_READ, MAP_PRIVATE, fd, 0);
if (p == MAP_FAILED) { perror("mmap"); }

// Anonymous memory (like malloc, but page-aligned):
char *p = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);

munmap(p, len);   // unmap when done
```

| Flag | Meaning |
|------|---------|
| `PROT_READ` | Pages can be read |
| `PROT_WRITE`| Pages can be written |
| `PROT_EXEC` | Pages can be executed |
| `MAP_SHARED`| Writes propagate to file (visible to other processes) |
| `MAP_PRIVATE` | Copy-on-write — modifications not written back |
| `MAP_ANONYMOUS` | No file backing (zero-initialised) |
| `MAP_FIXED` | Place mapping at exactly the given address |

**See also:** `munmap`, `mprotect`, `msync`, `brk`]],

  ["munmap"] = [[
**`munmap`** — Unmap mapped memory (`<sys/mman.h>`)

```c
if (munmap(addr, length) == -1) { perror("munmap"); }
```

All mappings created by `mmap` (including heap via `malloc`) should be unmapped when done.

**See also:** `mmap`, `mprotect`, `msync`]],

  ["mprotect"] = [[
**`mprotect`** — Set protection on a memory region (`<sys/mman.h>`)

```c
mprotect(addr, len, PROT_READ);                    // make read-only
mprotect(addr, len, PROT_READ | PROT_WRITE);       // read-write
mprotect(addr, len, PROT_NONE);                    // no access (guard pages)
```

**addr must be page-aligned.** Affects only the calling process's address space.

**See also:** `mmap`, `madvise`, `mlock`]],

  ["opendir"] = [[
**`opendir`** — Open a directory for reading (`<dirent.h>`)

```c
#include <dirent.h>

DIR *dir = opendir("/path");
if (!dir) { perror("opendir"); return; }

struct dirent *entry;
while ((entry = readdir(dir)) != NULL) {
    printf("%s\n", entry->d_name);     // filename (excluding path)
    // entry->d_type: DT_REG, DT_DIR, DT_LNK, etc. (Linux)
}

closedir(dir);
```

**See also:** `readdir`, `closedir`, `stat`, `scandir`]],

  ["readdir"] = [[
**`readdir`** — Read a directory entry (`<dirent.h>`)

```c
struct dirent *entry = readdir(dir);
// Returns NULL on end or error; check errno to distinguish:
// errno == 0 at end; errno != 0 on error
```

| Field | Meaning |
|-------|---------|
| `d_name` | Filename (not full path) |
| `d_type` | File type (Linux: `DT_REG`, `DT_DIR`, `DT_LNK`, `DT_UNKNOWN`) |

**Not** reentrant — use `readdir_r` for threaded code (or just `readdir` with external locking).

**See also:** `opendir`, `closedir`, `stat`]],

  ["closedir"] = [[
**`closedir`** — Close a directory stream (`<dirent.h>`)

```c
closedir(dir);   // returns 0 on success, -1 on error
```

**See also:** `opendir`, `readdir`]],

  ["stat"] = [[
**`stat`** — Get file status (`<sys/stat.h>`)

```c
#include <sys/stat.h>

struct stat st;
stat("/path/to/file", &st);     // follow symlinks
lstat("/path/to/symlink", &st); // do NOT follow symlinks
fstat(fd, &st);                 // by fd (no symlink concern)

// Key fields:
st.st_mode    // file type + permissions (use macros below)
st.st_size    // size in bytes
st.st_uid     // owner UID
st.st_gid     // owner GID
st.st_mtime   // last modification time (time_t)
st.st_atime   // last access time
st.st_ctime   // last status change time

// Mode checking macros:
S_ISREG(st.st_mode)   // regular file
S_ISDIR(st.st_mode)   // directory
S_ISLNK(st.st_mode)   // symlink
S_ISCHR(st.st_mode)   // character device
S_ISBLK(st.st_mode)   // block device
S_ISFIFO(st.st_mode)  // FIFO / named pipe
S_ISSOCK(st.st_mode)  // socket
```

**See also:** `lstat`, `fstat`, `access`, `chmod`]],

  ["access"] = [[
**`access`** — Check file permissions (`<unistd.h>`)

```c
if (access("/path/to/file", R_OK) == 0) { /* readable */ }

// Modes:
F_OK   // existence
R_OK   // readable
W_OK   // writable
X_OK   // executable
```

**Security note:** `access` checks the **real** UID/GID, not the effective. This creates a TOCTOU race (check then use). Use `euidaccess` or just open and check error.

**See also:** `stat`, `faccessat`]],

  ["chmod"] = [[
**`chmod`** — Change file permissions (`<sys/stat.h>`)

```c
chmod("file.txt", 0644);         // rw-r--r--
chmod("script.sh", 0755);        // rwxr-xr-x
fchmod(fd, 0644);                // by fd
```

Only the file owner or root can change permissions. Bits are the standard Unix octal.

**See also:** `stat`, `chown`, `umask`]],

  ["chown"] = [[
**`chown`** — Change file owner and group (`<unistd.h>`)

```c
chown("file.txt", 1000, 1000);   // uid, gid
lchown("symlink", uid, gid);     // do NOT follow symlink
fchown(fd, uid, gid);            // by fd
```

Only root can change the owner; the owner can change the group to one they belong to.

**See also:** `stat`, `chmod`, `getuid`]],

  ["link"] = [[
**`link`** — Create a hard link (`<unistd.h>`)

```c
link("existing.txt", "new_hardlink.txt");  // both point to same inode
```

Hard links share the same inode (same data blocks). Cannot cross filesystems; cannot link directories (except by root with special privileges).

**See also:** `symlink`, `unlink`, `rename`, `stat`]],

  ["symlink"] = [[
**`symlink`** — Create a symbolic link (`<unistd.h>`)

```c
symlink("/usr/local/bin/python3", "python");     // symlink contains "target" as text
// readlink retrieves the link target:
char buf[PATH_MAX];
ssize_t len = readlink("python", buf, sizeof(buf) - 1);
buf[len] = '\0';
```

Symlinks can be dangling (target doesn't exist). Can cross filesystems. Most syscalls follow symlinks by default.

**See also:** `link`, `readlink`, `unlink`, `stat`, `lstat`]],

  ["unlink"] = [[
**`unlink`** — Remove a filename (`<unistd.h>`)

```c
unlink("file.txt");   // remove a hard link; data freed when refs == 0
```

If the link count drops to zero **and** no process has the file open, the data is freed. If a process has it open, the file persists until the last fd is closed (even if unlinked).

**See also:** `link`, `rename`, `remove` (C stdlib), `rmdir`]],

  ["rename"] = [[
**`rename`** — Atomically rename a file (`<stdio.h>`)

```c
rename("old.txt", "new.txt");     // atomic if on same filesystem
```

If `new.txt` exists, it is atomically replaced. `rename` across filesystems may fail with `EXDEV` (use `cp` + `unlink`).

**See also:** `link`, `unlink`, `move_file`]],

  ["mkdir"] = [[
**`mkdir`** — Create a directory (`<sys/stat.h>`)

```c
mkdir("newdir", 0755);   // creates only the last component
```

**Does not** create parents. For `mkdir -p` behavior, iterate or use `mkdir_parents` (not a standard call — write the loop yourself).

**See also:** `rmdir`, `opendir`, `stat`]],

  ["rmdir"] = [[
**`rmdir`** — Remove an empty directory (`<unistd.h>`)

```c
rmdir("emptydir");   // fails with ENOTEMPTY if directory is not empty
```

**See also:** `mkdir`, `remove` (C stdlib), `unlink`]],

  ["getcwd"] = [[
**`getcwd`** — Get current working directory (`<unistd.h>`)

```c
char buf[PATH_MAX];
if (getcwd(buf, sizeof(buf))) { printf("%s\n", buf); }

// Or let malloc handle it:
char *cwd = getcwd(NULL, 0);   // Linux glibc extension
free(cwd);
```

**See also:** `chdir`, `realpath`, `chroot`]],

  ["chdir"] = [[
**`chdir`** — Change working directory (`<unistd.h>`)

```c
if (chdir("/tmp") == -1) { perror("chdir"); }
fchdir(fd);   // change to directory referenced by fd
```

**See also:** `getcwd`, `fchdir`, `mkdir`]],

  ["realpath"] = [[
**`realpath`** — Resolve path to canonical absolute path (`<stdlib.h>`)

```c
char *resolved = realpath("rel/../link/file", NULL);  // allocates buffer
// Returns NULL if path doesn't exist
free(resolved);
```

Returns an absolute path with symlinks resolved, `.` and `..` collapsed.

**See also:** `getcwd`, `canonicalize_file_name` (glibc), `readlink`]],

  -- ── Process control ───────────────────────────────────────────────────────

  ["fork"] = [[
**`fork`** — Create a child process (`<unistd.h>`)

```c
pid_t pid = fork();
if (pid == -1) {
    perror("fork");   // EAGAIN: process limit reached
} else if (pid == 0) {
    // Child — returns 0
    // pid = getpid() for child, getppid() for parent
    // All fds are duplicated (close-on-exec respected)
} else {
    // Parent — pid > 0 is child's PID
    waitpid(pid, NULL, 0);
}
```

**Key behaviors:**
- Child is a **copy** of parent (using copy-on-write)
- Child inherits: fd table, signal handlers, umask, env, working dir
- Child does **not** inherit: memory locks, pending signals, async I/O operations
- After `fork`, it's **unsafe** to call most functions in the child before `exec` (only async-signal-safe functions)

**Always** check the return value — a failed `fork` is not uncommon on loaded systems.

**See also:** `execve`, `waitpid`, `clone` (Linux), `vfork`]],

  ["execve"] = [[
**`execve`** — Replace process image (`<unistd.h>`)

```c
char *argv[] = {"ls", "-la", NULL};
char *envp[] = {"PATH=/usr/bin", "HOME=/home/user", NULL};

execve("/bin/ls", argv, envp);
// If successful, never returns — process is replaced

// Convenience wrappers (all end with exec*):
execl("/bin/ls", "ls", "-la", (char *)NULL);
execlp("ls", "ls", "-la", (char *)NULL);          // search PATH
execv("/bin/ls", argv);
execvp("ls", argv);                                // search PATH
execvpe("ls", argv, envp);                         // search PATH + env
```

The first argument (`argv[0]`) is conventionally the program name. `exec` preserves: open fds (unless `O_CLOEXEC`), PID, working directory, signal mask.

**See also:** `fork`, `system`, `posix_spawn`]],

  ["waitpid"] = [[
**`waitpid`** — Wait for child process state change (`<sys/wait.h>`)

```c
#include <sys/wait.h>

int status;
pid_t child = waitpid(pid, &status, 0);  // block until child exits

// Macros to interpret status:
WIFEXITED(status)     // true if exited normally
WEXITSTATUS(status)   // exit code (0-255)

WIFSIGNALED(status)   // true if terminated by signal
WTERMSIG(status)      // signal number

WIFSTOPPED(status)    // true if stopped (WUNTRACED)
WSTOPSIG(status)      // stop signal

// Options:
WNOHANG     // non-blocking — returns 0 if child still running
WUNTRACED   // also return on stopped (but not traced) children
WCONTINUED  // also return on continued (SIGCONT) children

// Wait for any child:
wait(&status);   // equivalent to waitpid(-1, &status, 0)
```

**Zombie avoidance:** call `wait`/`waitpid` for every `fork`ed child. If the parent never waits, the child becomes a zombie until the parent exits (then init reaps it).

**See also:** `fork`, `waitid`, `execve`, `signal`, `sigaction`]],

  ["wait"] = [[
**`wait`** — Wait for any child (`<sys/wait.h>`)

```c
int status;
pid_t pid = wait(&status);
// Equivalent to waitpid(-1, &status, 0)
```

**See also:** `waitpid`, `waitid`, `fork`]],

  ["getpid"] = [[
**`getpid`** — Get process ID (`<unistd.h>`)

```c
pid_t pid = getpid();          // current process
pid_t ppid = getppid();        // parent process
```

**See also:** `fork`, `getpgid`, `getsid`]],

  ["exit"] = [[
**`exit`** — Terminate process (`<stdlib.h>`)

```c
exit(0);           // normal exit (calls atexit handlers, flushes stdio)
_exit(0);          // immediate exit (no handlers, no flush — async-signal-safe)
atexit(func);      // register function to be called on exit (LIFO order)
```

`exit` vs `_exit`:
- `exit()` — standard C: flushes stdio buffers, calls `atexit` handlers, calls destructors for thread-local storage
- `_exit()` — immediate kernel exit: no handlers run, no buffers flushed. Use in child after `fork` to avoid flushing parent's buffers twice

**Never** call `exit` from a signal handler (use `_exit` instead).

**See also:** `atexit`, `abort`, `fork`]],

  ["kill"] = [[
**`kill`** — Send a signal to a process (`<signal.h>`)

```c
kill(pid, SIGTERM);           // send SIGTERM to process
kill(pid, 0);                 // check if process exists (returns 0 or -1/ESRCH)

// Common signals:
SIGTERM  // polite termination request (default: terminate)
SIGKILL  // forceful termination (cannot be caught/blocked)
SIGINT   // interrupt (Ctrl+C)
SIGHUP   // hangup (terminal disconnected, or reload daemon config)
SIGUSR1  // user-defined signal 1
SIGUSR2  // user-defined signal 2

// Send to all processes in group:
kill(0, SIGTERM);             // send to process group
kill(-1, SIGTERM);            // send to all processes (if root)
```

**See also:** `signal`, `sigaction`, `raise`, `waitpid`]],

  ["alarm"] = [[
**`alarm`** — Schedule a SIGALRM in N seconds (`<unistd.h>`)

```c
unsigned remaining = alarm(5);   // SIGALRM in 5 seconds
alarm(0);                        // cancel pending alarm
```

**Simpler** than `setitimer`. Only one alarm per process. Signals are not queued — if a previous alarm hasn't fired, its time is replaced.

**Prefer `setitimer`** or `timer_create` for sub-second precision.

**See also:** `signal`, `setitimer`, `timer_create`, `nanosleep`]],

  ["sleep"] = [[
**`sleep`** — Suspend thread for seconds (`<unistd.h>`)

```c
unsigned remaining = sleep(3);          // sleep for 3 seconds
unsigned left = sleep(10);              // returns remaining if interrupted
```

May return early if a signal arrives (`remaining > 0`). For sub-second sleep, use `nanosleep` or `usleep`.

**See also:** `nanosleep`, `usleep` (obsolete), `alarm`, `timer_create`]],

  ["nanosleep"] = [[
**`nanosleep`** — High-resolution sleep (`<time.h>`)

```c
#include <time.h>

struct timespec req = { .tv_sec = 0, .tv_nsec = 500000000 };  // 500 ms
struct timespec rem;
if (nanosleep(&req, &rem) == -1 && errno == EINTR) {
    // Interrupted by signal — rem contains remaining time
}
```

**Signal-safe** (async-signal-safe). Precision depends on kernel timer resolution. Prefer `clock_nanosleep` for absolute deadlines.

**See also:** `sleep`, `clock_nanosleep`, `clock_gettime`, `timer_create`]],

  ["daemon"] = [[
**`daemon`** — Run in background (`<unistd.h>`)

```c
if (daemon(0, 0) == -1) { perror("daemon"); }  // fork, detach from terminal

// Flags:
daemon(0, 0);        // chdir to /, redirect stdin/stdout/stderr to /dev/null
daemon(0, 1);        // preserve stdout/stderr (noclose = 1)
```

**Not** in POSIX (BSD extension, widely available). Manual daemonisation: fork → setsid → fork → chdir("/") → umask(0) → redirect fds.

**See also:** `fork`, `setsid`, `umask`]],

  ["setsid"] = [[
**`setsid`** — Create a new session and process group (`<unistd.h>`)

```c
pid_t sid = setsid();   // detach from controlling terminal
```

Call `setsid` after `fork` in a daemonisation sequence. The calling process becomes the session leader of a new session and the process group leader of a new process group.

**See also:** `daemon`, `fork`, `getsid`, `setpgid`]],

  ["setpgid"] = [[
**`setpgid`** — Set process group ID (`<unistd.h>`)

```c
setpgid(pid, pgid);     // set pid's process group to pgid
// In child after fork: setpgid(0, 0); to create new group
```

Used for job control (shells). Combined with `tcsetpgrp` for terminal ownership.

**See also:** `setsid`, `fork`, `tcsetpgrp`]],

  -- ── Signals ───────────────────────────────────────────────────────────────

  ["sigaction"] = [[
**`sigaction`** — Examine and change signal action (`<signal.h>`)

```c
#include <signal.h>

struct sigaction sa = { 0 };
sa.sa_handler = handler;         // or sa_sigaction for 3-arg handler
sigemptyset(&sa.sa_mask);        // signals blocked during handler
sa.sa_flags = SA_RESTART;        // auto-restart interrupted syscalls

if (sigaction(SIGINT, &sa, NULL) == -1) {
    perror("sigaction");
}

// Old way (limited — prefer sigaction):
signal(SIGINT, handler);         // less portable behaviour (System V vs BSD)
```

**Prefer `sigaction` over `signal`** — it is POSIX-standard, has well-defined semantics, supports blocking masks during handler execution, and `SA_RESTART` controls syscall interruption.

**Flags:** `SA_RESTART` (restart interrupted syscalls), `SA_SIGINFO` (use sa_sigaction with siginfo_t), `SA_NOCLDSTOP` (don't get SIGCHLD for stopped children), `SA_NODEFER` (don't block the signal in handler).

**See also:** `signal`, `kill`, `sigprocmask`, `sigwait`]],

  ["signal"] = [[
**`signal`** — Simple signal handling (C standard, `<signal.h>`)

```c
#include <signal.h>

signal(SIGINT, SIG_IGN);   // ignore Ctrl+C
signal(SIGPIPE, SIG_IGN);  // ignore broken pipe
signal(SIGTERM, handler);

void handler(int sig) {
    // async-signal-safe functions only (write, not printf)
    write(STDOUT_FILENO, "caught\n", 7);
}
```

**Portability:** `signal()` semantics differ between Unix implementations (BSD resets handler after delivery; System V doesn't). Prefer `sigaction` for new code and libraries.

**See also:** `sigaction`, `kill`, `raise`, `sigprocmask`]],

  ["sigprocmask"] = [[
**`sigprocmask`** — Examine/change blocked signals (`<signal.h>`)

```c
sigset_t old, block;
sigemptyset(&block);
sigaddset(&block, SIGINT);
sigaddset(&block, SIGTERM);

sigprocmask(SIG_BLOCK, &block, &old);   // block them
// ... critical section ...
sigprocmask(SIG_SETMASK, &old, NULL);   // restore

sigprocmask(SIG_UNBLOCK, &block, NULL); // unblock
```

| Operation | Effect |
|-----------|--------|
| `SIG_BLOCK` | Add set to current blocked mask |
| `SIG_UNBLOCK` | Remove set from current blocked mask |
| `SIG_SETMASK` | Replace current blocked mask with set |

**See also:** `sigemptyset`, `sigfillset`, `sigpending`, `sigsuspend`]],

  ["sigemptyset"] = [[
**`sigemptyset`** — Initialise signal set to empty (`<signal.h>`)

```c
sigset_t set;
sigemptyset(&set);     // initialise (must do before add/fill)
sigfillset(&set);      // initialise to all signals
sigaddset(&set, SIGINT);
sigdelset(&set, SIGINT);
int is_member = sigismember(&set, SIGINT);
```

**Always** call `sigemptyset` or `sigfillset` to initialise a `sigset_t` before using it — the underlying representation is opaque.

**See also:** `sigprocmask`, `sigaction`, `sigpending`]],

  ["sigsuspend"] = [[
**`sigsuspend`** — Atomically unblock signals and wait (`<signal.h>`)

```c
sigset_t mask;
// ... construct signal mask with interesting signals ...
sigsuspend(&mask);    // replaces blocked mask and waits for any signal in mask
                       // returns -1 with EINTR when handler returns
```

**Atomically** sets the signal mask and blocks for a signal — no race condition where a signal arrives between `sigprocmask` and `pause`.

**See also:** `sigprocmask`, `sigwait`, `pause`, `sigaction`]],

  ["sigwait"] = [[
**`sigwait`** — Synchronously wait for a signal (`<signal.h>`)

```c
sigset_t set;
sigemptyset(&set);
sigaddset(&set, SIGINT);
sigaddset(&set, SIGTERM);
sigprocmask(SIG_BLOCK, &set, NULL);   // block signals first

int sig;
sigwait(&set, &sig);                  // blocks until one arrives
printf("received signal: %d\n", sig);
```

**Used in dedicated signal-handling threads** — signals are blocked in all threads, one thread calls `sigwait` to handle them synchronously. This avoids the constraints of signal handlers (async-signal-safe only).

**See also:** `sigwaitinfo`, `sigtimedwait`, `sigprocmask`, `sigaction`, `pthread_sigmask`]],

  -- ── POSIX threads ─────────────────────────────────────────────────────────

  ["pthread_create"] = [[
**`pthread_create`** — Create a new thread (`<pthread.h>`)

```c
#include <pthread.h>

void *worker(void *arg) {
    int *val = (int *)arg;
    printf("thread: %d\n", *val);
    return NULL;
}

pthread_t tid;
int err = pthread_create(&tid, NULL, worker, &arg);
if (err != 0) { /* errno-style error code */ }

err = pthread_join(tid, NULL);     // wait for thread
if (err != 0) { /* error */ }
```

Compile with `-pthread` (or `-lpthread` on older systems). On success, a new thread starts executing `worker(arg)`. Threads share address space, fds, signal handlers — but have separate stacks and errno.

**See also:** `pthread_join`, `pthread_detach`, `pthread_exit`, `pthread_self`, `pthread_cancel`]],

  ["pthread_join"] = [[
**`pthread_join`** — Wait for thread termination (`<pthread.h>`)

```c
void *retval;
int err = pthread_join(thread_id, &retval);
// retval is the pointer returned by the thread function or PTHREAD_CANCELED
```

Only one thread should `pthread_join` a given thread. A detached thread cannot be joined.

**See also:** `pthread_create`, `pthread_detach`, `pthread_exit`]],

  ["pthread_detach"] = [[
**`pthread_detach`** — Mark thread as detached (`<pthread.h>`)

```c
pthread_detach(pthread_self());   // detach current thread
// or: pthread_detach(tid);
```

Detached threads' resources are automatically reclaimed on exit — they cannot be joined. Prevents thread resource leaks for "fire and forget" threads.

**See also:** `pthread_create`, `pthread_join`, `pthread_attr_setdetachstate`]],

  ["pthread_mutex_lock"] = [[
**`pthread_mutex_lock`** — Lock a mutex (`<pthread.h>`)

```c
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;   // static init

int err = pthread_mutex_lock(&mutex);      // block until acquired
int err = pthread_mutex_trylock(&mutex);   // EBUSY if already locked
int err = pthread_mutex_unlock(&mutex);    // release

// Dynamic init:
pthread_mutex_init(&mutex, NULL);           // default attributes
pthread_mutex_destroy(&mutex);              // cleanup
```

**Recursive mutex** — use `PTHREAD_MUTEX_RECURSIVE` attribute if the owning thread needs to lock again (code smell — redesign if possible).

**See also:** `pthread_mutex_init`, `pthread_mutex_destroy`, `pthread_cond_wait`, `pthread_rwlock_rdlock`]],

  ["pthread_cond_wait"] = [[
**`pthread_cond_wait`** — Wait on a condition variable (`<pthread.h>`)

```c
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
bool ready = false;

// Waiter:
pthread_mutex_lock(&mutex);
while (!ready) {                              // must check in a loop (spurious wakeup)
    pthread_cond_wait(&cond, &mutex);          // atomically unlocks mutex, waits
}
pthread_mutex_unlock(&mutex);

// Signaller:
pthread_mutex_lock(&mutex);
ready = true;
pthread_mutex_unlock(&mutex);
pthread_cond_signal(&cond);                    // wake one waiter
// pthread_cond_broadcast(&cond);             // wake all
```

**Always** re-check the predicate after `pthread_cond_wait` returns (spurious wakeups are possible). The mutex is re-acquired before the function returns.

**See also:** `pthread_mutex_lock`, `pthread_cond_signal`, `pthread_cond_broadcast`, `pthread_cond_timedwait`]],

  ["pthread_once"] = [[
**`pthread_once`** — Execute initialisation exactly once (`<pthread.h>`)

```c
pthread_once_t once = PTHREAD_ONCE_INIT;

void init_once(void) {
    // runs exactly once — thread-safe
}

void threadsafe_init(void) {
    pthread_once(&once, init_once);
}
```

**Thread-safe** one-time initialisation, even if multiple threads call it simultaneously. Internally uses a fast path (check flag) and a slow path (locking).

**See also:** `pthread_create`, `call_once` (C++11)]],

  ["pthread_key_create"] = [[
**`pthread_key_create`** — Thread-specific data key (`<pthread.h>`)

```c
pthread_key_t key;
void destructor(void *ptr) { free(ptr); }

pthread_key_create(&key, destructor);   // create key with optional destructor

// Per-thread usage:
pthread_setspecific(key, malloc(100));
void *ptr = pthread_getspecific(key);
```

Each thread gets its own value for the same key. The destructor is called when a thread exits (if the value is non-NULL). Keys are per-process, not per-thread.

**See also:** `pthread_setspecific`, `pthread_getspecific`, `pthread_key_delete`]],

  ["pthread_self"] = [[
**`pthread_self`** — Get calling thread's ID (`<pthread.h>`)

```c
pthread_t tid = pthread_self();
int eq = pthread_equal(tid1, tid2);   // compare thread IDs (portable)
```

`pthread_t` is an opaque type — do not compare with `==` (use `pthread_equal`). The format is implementation-defined.

**See also:** `pthread_create`, `pthread_equal`, `pthread_join`]],

  -- ── Networking ─────────────────────────────────────────────────────────────

  ["socket"] = [[
**`socket`** — Create an endpoint for communication (`<sys/socket.h>`)

```c
#include <sys/socket.h>

int s = socket(AF_INET, SOCK_STREAM, 0);   // TCP (IPv4)
int s = socket(AF_INET6, SOCK_STREAM, 0);  // TCP (IPv6)
int s = socket(AF_INET, SOCK_DGRAM, 0);    // UDP (IPv4)
int s = socket(AF_UNIX, SOCK_STREAM, 0);   // Unix domain socket

if (s == -1) { perror("socket"); }
```

| Domain | Meaning |
|--------|---------|
| `AF_INET` | IPv4 |
| `AF_INET6` | IPv6 |
| `AF_UNIX` | Local Unix socket |
| `AF_NETLINK` | Linux kernel interface |

| Type | Meaning |
|------|---------|
| `SOCK_STREAM` | Reliable, connection-oriented (TCP) |
| `SOCK_DGRAM` | Unreliable, connectionless (UDP) |
| `SOCK_RAW` | Raw IP packets (root required) |
| `SOCK_SEQPACKET` | Reliable, connection-oriented, preserves message boundaries |

**See also:** `bind`, `listen`, `accept`, `connect`, `socketpair`, `getsockopt`]],

  ["bind"] = [[
**`bind`** — Bind a socket to an address (`<sys/socket.h>`)

```c
#include <netinet/in.h>

struct sockaddr_in addr = {
    .sin_family = AF_INET,
    .sin_port = htons(8080),
    .sin_addr = { .s_addr = INADDR_ANY }   // listen on all interfaces
};

if (bind(s, (struct sockaddr *)&addr, sizeof(addr)) == -1) {
    perror("bind");
}
```

**Common errors:** `EADDRINUSE` (port already in use — use `SO_REUSEADDR`), `EACCES` (need root for ports < 1024).

**See also:** `socket`, `listen`, `connect`, `getsockname`, `setsockopt`]],

  ["listen"] = [[
**`listen`** — Mark socket as passive (ready to accept) (`<sys/socket.h>`)

```c
int backlog = 128;   // max pending connections (kernel caps)
if (listen(s, backlog) == -1) { perror("listen"); }
```

**See also:** `socket`, `bind`, `accept`, `connect`]],

  ["accept"] = [[
**`accept`** — Accept a connection on a listening socket (`<sys/socket.h>`)

```c
struct sockaddr_in client_addr;
socklen_t addrlen = sizeof(client_addr);
int client_fd = accept(server_fd, (struct sockaddr *)&client_addr, &addrlen);
if (client_fd == -1) {
    if (errno == EINTR || errno == EAGAIN) { /* retry or handle */ }
    perror("accept");
}
// client_addr holds the remote address

// Linux-specific: accept4(server_fd, ... , SOCK_CLOEXEC)
```

Returns a **new** fd for the connection; the original listening socket remains active. `accept` blocks by default; use `O_NONBLOCK` or poll/select/epoll for non-blocking.

**See also:** `bind`, `listen`, `connect`, `poll`, `epoll`]],

  ["connect"] = [[
**`connect`** — Connect a socket to a remote address (`<sys/socket.h>`)

```c
struct sockaddr_in addr = {
    .sin_family = AF_INET,
    .sin_port = htons(80),
};
inet_pton(AF_INET, "93.184.216.34", &addr.sin_addr);

if (connect(s, (struct sockaddr *)&addr, sizeof(addr)) == -1) {
    perror("connect");
}
```

For TCP: initiates the three-way handshake. For Unix domain: establishes a connection to a listening socket. For UDP: sets the default destination address.

**See also:** `socket`, `bind`, `accept`, `getaddrinfo`]],

  ["send"] = [[
**`send`** — Send data over a connected socket (`<sys/socket.h>`)

```c
ssize_t n = send(s, buf, len, 0);          // TCP or connected UDP
ssize_t n = sendto(s, buf, len, 0, dest_addr, addrlen);  // UDP
ssize_t n = sendmsg(s, &msg_hdr, 0);       // scatter/gather I/O

// Flags:
MSG_NOSIGNAL  // don't generate SIGPIPE on closed connection
MSG_DONTWAIT  // non-blocking operation
MSG_MORE      // TCP: don't send segment yet (like TCP_CORK)
```

May return fewer bytes than requested (especially with non-blocking sockets). Returns -1 on error (`EPIPE` if peer closed).

**See also:** `recv`, `sendto`, `sendmsg`, `write`, `connect`]],

  ["recv"] = [[
**`recv`** — Receive data from a connected socket (`<sys/socket.h>`)

```c
char buf[4096];
ssize_t n = recv(s, buf, sizeof(buf), 0);   // TCP
// recvfrom for UDP (fills in source address):
struct sockaddr_in src;
socklen_t srclen = sizeof(src);
n = recvfrom(s, buf, sizeof(buf), 0, (struct sockaddr *)&src, &srclen);

// Flags:
MSG_PEEK     // read data without consuming it
MSG_DONTWAIT // non-blocking
MSG_WAITALL  // block until exactly len bytes received (implementation may return less)

if (n == 0) { /* graceful shutdown */ }
```

`recv` returns 0 when the peer has closed the connection (TCP). `n == -1` on error; `EAGAIN`/`EWOULDBLOCK` for non-blocking with no data.

**See also:** `send`, `recvfrom`, `recvmsg`, `read`, `shutdown`]],

  ["shutdown"] = [[
**`shutdown`** — Shut down part of a full-duplex connection (`<sys/socket.h>`)

```c
shutdown(s, SHUT_RD);    // no more reads
shutdown(s, SHUT_WR);    // no more writes (sends TCP FIN)
shutdown(s, SHUT_RDWR);  // both directions
```

Unlike `close`, `shutdown` affects all copies of the fd (other processes/threads still have their own references). `SHUT_WR` sends FIN — the peer sees EOF on read.

**See also:** `close`, `recv`, `send`, `socket`]],

  ["setsockopt"] = [[
**`setsockopt`** — Set socket options (`<sys/socket.h>`)

```c
int optval = 1;

// Reuse address (avoid EADDRINUSE on restart):
setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval));

// TCP keep-alive:
setsockopt(s, SOL_SOCKET, SO_KEEPALIVE, &optval, sizeof(optval));

// Send/receive timeout:
struct timeval tv = { .tv_sec = 5, .tv_usec = 0 };
setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

// Disable Nagle's algorithm (low-latency):
setsockopt(s, IPPROTO_TCP, TCP_NODELAY, &optval, sizeof(optval));
```

**See also:** `getsockopt`, `socket`, `bind`, `ioctl`]],

  ["getaddrinfo"] = [[
**`getaddrinfo`** — Resolve hostname/service to socket address (`<netdb.h>`)

```c
#include <netdb.h>

struct addrinfo hints = { .ai_family = AF_UNSPEC, .ai_socktype = SOCK_STREAM };
struct addrinfo *result;

int ret = getaddrinfo("example.com", "80", &hints, &result);
if (ret != 0) {
    fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(ret));
    return;
}

// Iterate result list:
for (struct addrinfo *rp = result; rp != NULL; rp = rp->ai_next) {
    s = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
    if (s == -1) continue;
    if (connect(s, rp->ai_addr, rp->ai_addrlen) != -1) break;  // success
    close(s);
}

freeaddrinfo(result);
```

**Prefer over obsolete `gethostbyname`** — it's IPv4/IPv6 agnostic, reentrant, and POSIX-standard.

**See also:** `freeaddrinfo`, `gai_strerror`, `getnameinfo`, `inet_pton`]],

  ["inet_pton"] = [[
**`inet_pton`** — Convert text IP to binary address (`<arpa/inet.h>`)

```c
#include <arpa/inet.h>

struct in_addr ipv4;
inet_pton(AF_INET, "192.0.2.1", &ipv4);

struct in6_addr ipv6;
inet_pton(AF_INET6, "::1", &ipv6);

// Reverse:
char buf[INET6_ADDRSTRLEN];
inet_ntop(AF_INET, &ipv4, buf, sizeof(buf));
```

Returns 1 on success, 0 if input is not a valid address, -1 on error (`EAFNOSUPPORT`).

**See also:** `getaddrinfo`, `inet_ntop`, `socket`]],

  ["poll"] = [[
**`poll`** — Monitor multiple file descriptors for I/O readiness (`<poll.h>`)

```c
#include <poll.h>

struct pollfd fds[2];
fds[0].fd = stdin_fd;
fds[0].events = POLLIN;          // interested in readability

fds[1].fd = server_fd;
fds[1].events = POLLIN;

int ret = poll(fds, 2, 5000);    // timeout: 5000 ms
if (ret == -1) { perror("poll"); }
if (ret == 0)  { /* timeout */ }

if (fds[0].revents & POLLIN) { /* read from stdin */ }
if (fds[1].revents & POLLIN) { /* accept connection */ }
```

| Event | Meaning |
|-------|---------|
| `POLLIN` | Data available to read |
| `POLLOUT` | Socket ready for writing |
| `POLLERR` | Error condition (output only) |
| `POLLHUP` | Hang up (peer closed) |
| `POLLRDHUP`| Peer closed (Linux 2.6.17+) |

**Scalability:** `poll` is O(n) — fine for hundreds of fds. For thousands, use `epoll` (Linux) or `kqueue` (BSD).

**See also:** `select`, `epoll`, `accept`, `recv`]],

  ["select"] = [[
**`select`** — Synchronous I/O multiplexing (`<sys/select.h>`)

```c
fd_set read_fds;
FD_ZERO(&read_fds);
FD_SET(fd, &read_fds);

struct timeval tv = { .tv_sec = 5, .tv_usec = 0 };

int ret = select(fd + 1, &read_fds, NULL, NULL, &tv);
if (ret == -1) { perror("select"); }
if (ret == 0)  { /* timeout */ }
if (FD_ISSET(fd, &read_fds)) { /* data ready */ }
```

**Limitations:** fd_set is limited to `FD_SETSIZE` (typically 1024). For modern code, **prefer `poll`** (no fd limit) or `epoll` (Linux, high-performance).

**See also:** `poll`, `epoll`, `FD_SET`, `FD_ISSET`]],

  ["epoll"] = [[
**`epoll`** — I/O event notification facility (Linux, `<sys/epoll.h>`)

```c
#include <sys/epoll.h>

// Create epoll instance:
int epfd = epoll_create1(0);
// edge-triggered: EPOLLET in events

struct epoll_event ev, events[64];
ev.events = EPOLLIN;
ev.data.fd = server_fd;
epoll_ctl(epfd, EPOLL_CTL_ADD, server_fd, &ev);

// Event loop:
while (1) {
    int nfds = epoll_wait(epfd, events, 64, -1);  // block indefinitely
    for (int i = 0; i < nfds; i++) {
        if (events[i].events & EPOLLIN) {
            // handle events[i].data.fd
        }
    }
}

close(epfd);
```

**Scalable** — O(1) with number of fds. Best with **edge-triggered** (`EPOLLET`) + non-blocking I/O.

**See also:** `poll`, `select`, `accept`, `recv`, `eventfd`, `signalfd`]],

  -- ── IPC ────────────────────────────────────────────────────────────────────

  ["shmget"] = [[
**`shmget`** — Allocate a System V shared memory segment (`<sys/shm.h>`)

```c
#include <sys/shm.h>

key_t key = IPC_PRIVATE;       // or ftok("/path", 'X')
int shmid = shmget(key, 4096, IPC_CREAT | 0666);
if (shmid == -1) { perror("shmget"); }

void *ptr = shmat(shmid, NULL, 0);   // attach
// ... use shared memory ...
shmdt(ptr);                           // detach
shmctl(shmid, IPC_RMID, NULL);       // remove
```

**Legacy.** Prefer `mmap(MAP_ANONYMOUS | MAP_SHARED)` for new code — it's simpler and doesn't require `key_t`.

**See also:** `shmat`, `shmdt`, `shmctl`, `mmap`, `ftok`]],

  ["semget"] = [[
**`semget`** — Create/access System V semaphore set (`<sys/sem.h>`)

```c
#include <sys/sem.h>

int semid = semget(IPC_PRIVATE, 1, IPC_CREAT | 0666);
semctl(semid, 0, SETVAL, 1);          // initialise to 1 (binary semaphore)

struct sembuf op = { .sem_num = 0, .sem_op = -1, .sem_flg = 0 };
semop(semid, &op, 1);                 // wait (P)

op.sem_op = 1;
semop(semid, &op, 1);                 // signal (V)

semctl(semid, 0, IPC_RMID);          // remove
```

**Legacy.** Prefer `mmap` with `pthread_mutex_t` (set `pthread_mutexattr_setpshared`), or POSIX semaphores (`sem_open`, `sem_wait`, `sem_post`).

**See also:** `semctl`, `semop`, `pthread_mutexattr_setpshared`, `mmap`]],

  ["msgget"] = [[
**`msgget`** — Create/access System V message queue (`<sys/msg.h>`)

```c
int msqid = msgget(IPC_PRIVATE, IPC_CREAT | 0666);

struct msgbuf {
    long mtype;          // message type (> 0)
    char mtext[256];     // message data
};

struct msgbuf msg = { .mtype = 1, .mtext = "hello" };
msgsnd(msqid, &msg, sizeof(msg.mtext), 0);

msgrcv(msqid, &msg, sizeof(msg.mtext), 0, 0);  // type 0 = any type

msgctl(msqid, IPC_RMID, NULL);
```

**Legacy.** Prefer POSIX message queues (`mq_open`, `mq_send`, `mq_receive`) or Unix domain sockets for portable IPC.

**See also:** `msgsnd`, `msgrcv`, `msgctl`, `mq_open`, `socketpair`]],

  ["mq_open"] = [[
**`mq_open`** — Open/create a POSIX message queue (`<mqueue.h>`)

```c
#include <fcntl.h>
#include <mqueue.h>

struct mq_attr attr = { .mq_maxmsg = 10, .mq_msgsize = 256 };
mqd_t mq = mq_open("/myqueue", O_CREAT | O_RDWR, 0644, &attr);
if (mq == (mqd_t)-1) { perror("mq_open"); }

mq_send(mq, "hello", 5, 0);             // priority 0
char buf[256];
unsigned prio;
ssize_t n = mq_receive(mq, buf, 256, &prio);

mq_close(mq);
mq_unlink("/myqueue");                   // remove when done
```

Mount `mqueue` filesystem: `mount -t mqueue none /dev/mqueue`. Max message size is limited by `/proc/sys/fs/mqueue/msgsize_max`.

**See also:** `mq_send`, `mq_receive`, `mq_notify`, `mq_unlink`, `mq_getattr`, `mq_setattr`, `socketpair`]],

  ["eventfd"] = [[
**`eventfd`** — File descriptor for event notification (Linux, `<sys/eventfd.h>`)

```c
#include <sys/eventfd.h>

int efd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
// Write to signal:
uint64_t val = 1;
write(efd, &val, sizeof(val));
// Read to consume:
read(efd, &val, sizeof(val));

// Use with epoll:
struct epoll_event ev;
ev.events = EPOLLIN;
ev.data.fd = efd;
epoll_ctl(epfd, EPOLL_CTL_ADD, efd, &ev);
```

**Lightweight** — simpler than pipe or signal for thread-to-thread notification. The counter accumulates writes (use with `EFD_SEMAPHORE` for decrementing by 1).

**See also:** `pipe`, `signalfd`, `timerfd_create`, `epoll`]],

  ["timerfd_create"] = [[
**`timerfd_create`** — Timer file descriptor (Linux, `<sys/timerfd.h>`)

```c
#include <sys/timerfd.h>

int tfd = timerfd_create(CLOCK_MONOTONIC, TFD_NONBLOCK | TFD_CLOEXEC);

struct itimerspec ts = {
    .it_interval = { .tv_sec = 1, .tv_nsec = 0 },  // repeat every 1s
    .it_value    = { .tv_sec = 1, .tv_nsec = 0 },   // fire after 1s
};
timerfd_settime(tfd, 0, &ts, NULL);

// Read expiration count (use with epoll):
uint64_t expirations;
read(tfd, &expirations, sizeof(expirations));

close(tfd);
```

**Best for integrating timers with event loops** (epoll/select/poll). The fd becomes readable on each expiration; the read returns the number of expirations since last read.

**See also:** `timerfd_settime`, `timerfd_gettime`, `epoll`, `eventfd`]],

  ["signalfd"] = [[
**`signalfd`** — Receive signals as file descriptor (Linux, `<sys/signalfd.h>`)

```c
#include <sys/signalfd.h>

sigset_t mask;
sigemptyset(&mask);
sigaddset(&mask, SIGINT);
sigaddset(&mask, SIGTERM);
sigprocmask(SIG_BLOCK, &mask, NULL);   // must block signals first

int sfd = signalfd(-1, &mask, SFD_NONBLOCK | SFD_CLOEXEC);
// Use with epoll:
struct epoll_event ev;
ev.events = EPOLLIN;
ev.data.fd = sfd;
epoll_ctl(epfd, EPOLL_CTL_ADD, sfd, &ev);

// On read:
struct signalfd_siginfo fdsi;
read(sfd, &fdsi, sizeof(fdsi));    // fdsi.ssi_signo = signal number
```

**Clean signal handling** — integrate signals into the event loop rather than using async-signal-safe handlers.

**See also:** `sigprocmask`, `eventfd`, `timerfd_create`, `epoll`]],

  ["inotify_init"] = [[
**`inotify_init`** — Monitor file system events (Linux, `<sys/inotify.h>`)

```c
#include <sys/inotify.h>

int fd = inotify_init1(IN_NONBLOCK | IN_CLOEXEC);
int wd = inotify_add_watch(fd, "/path/to/watch",
    IN_CREATE | IN_DELETE | IN_MODIFY);

// Read events:
char buf[4096];
ssize_t n = read(fd, buf, sizeof(buf));
// Walk through struct inotify_event(s) in buf

// Cleanup:
inotify_rm_watch(fd, wd);
close(fd);
```

| Event | Meaning |
|-------|---------|
| `IN_CREATE`  | File/dir created |
| `IN_DELETE`  | File/dir deleted |
| `IN_MODIFY`  | File modified |
| `IN_ATTRIB`  | Metadata changed |
| `IN_MOVED_FROM` / `IN_MOVED_TO` | File moved (use cookie to pair) |

**See also:** `inotify_add_watch`, `inotify_rm_watch`, `epoll`, `stat`]],

  -- ── Time ───────────────────────────────────────────────────────────────────

  ["clock_gettime"] = [[
**`clock_gettime`** — High-resolution clock time (`<time.h>`)

```c
#include <time.h>

struct timespec ts;

clock_gettime(CLOCK_MONOTONIC, &ts);      // monotonic (uptime, no NTP adjustments)
clock_gettime(CLOCK_REALTIME, &ts);       // wall clock (may jump)
clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &ts);  // CPU time consumed by this process
clock_gettime(CLOCK_THREAD_CPUTIME_ID, &ts);   // CPU time consumed by this thread

long ns = ts.tv_nsec + ts.tv_sec * 1000000000L;
```

**Prefer `CLOCK_MONOTONIC`** for measuring intervals (not affected by NTP or admin time changes).

**See also:** `clock_settime`, `clock_getres`, `gettimeofday` (obsolete), `nanosleep`]],

  ["clock_nanosleep"] = [[
**`clock_nanosleep`** — Sleep with a specified clock (`<time.h>`)

```c
#include <time.h>

struct timespec req = { .tv_sec = 0, .tv_nsec = 100000000 };  // 100ms

// Relative sleep:
clock_nanosleep(CLOCK_MONOTONIC, 0, &req, NULL);

// Absolute sleep (wake at specific time — more precise, no drift):
struct timespec deadline;
clock_gettime(CLOCK_MONOTONIC, &deadline);
deadline.tv_nsec += 500000000;
if (deadline.tv_nsec >= 1000000000) { deadline.tv_sec++; deadline.tv_nsec -= 1000000000; }
clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &deadline, NULL);
```

**Absolute sleep** avoids cumulative drift (e.g., in frame-rate control). Unlike `nanosleep`, clock_nanosleep lets you choose the clock.

**See also:** `nanosleep`, `clock_gettime`, `timer_create`]],

  ["gettimeofday"] = [[
**`gettimeofday`** — Get current time with microseconds (`<sys/time.h>`)

```c
#include <sys/time.h>

struct timeval tv;
gettimeofday(&tv, NULL);   // NULL = don't care about timezone
long micros = tv.tv_sec * 1000000L + tv.tv_usec;
```

**Prefer `clock_gettime`** — `gettimeofday` is not monotonic (time can jump backwards due to NTP) and has lower precision.

**See also:** `clock_gettime`, `time` (C stdlib), `settimeofday`]],

  ["setitimer"] = [[
**`setitimer`** — Schedule periodic delivery of a signal (`<sys/time.h>`)

```c
struct itimerval it = {
    .it_interval = { .tv_sec = 1, .tv_usec = 0 },  // repeat every 1s
    .it_value    = { .tv_sec = 1, .tv_usec = 0 },   // first fire after 1s
};
setitimer(ITIMER_REAL, &it, NULL);   // sends SIGALRM
// ITIMER_VIRTUAL → SIGVTALRM (when process is executing)
// ITIMER_PROF   → SIGPROF   (when process is executing or kernel on its behalf)
```

**Legacy** — prefer `timer_create` (POSIX timers) for better resolution and per-timer signals.

**See also:** `getitimer`, `timer_create`, `alarm`, `signal`, `sigaction`]],

  ["timer_create"] = [[
**`timer_create`** — Create a POSIX per-process timer (`<time.h>`)

```c
#include <signal.h>
#include <time.h>

timer_t timer;
struct sigevent se = {
    .sigev_notify = SIGEV_SIGNAL,
    .sigev_signo = SIGUSR1,
};
timer_create(CLOCK_MONOTONIC, &se, &timer);

struct itimerspec ts = {
    .it_interval = { .tv_sec = 0, .tv_nsec = 500000000 },  // 500ms period
    .it_value    = { .tv_sec = 0, .tv_nsec = 500000000 },   // first fire in 500ms
};
timer_settime(timer, 0, &ts, NULL);

// ... SIGUSR1 fires each period ...

timer_delete(timer);
```

| Notification | Meaning |
|-------------|---------|
| `SIGEV_SIGNAL` | Deliver signal on expiration |
| `SIGEV_THREAD` | Invoke function in new thread |
| `SIGEV_NONE` | No notification (poll with `timer_gettime`) |

**See also:** `timer_settime`, `timer_gettime`, `timer_delete`, `setitimer`, `clock_gettime`]],

  -- ── System and user info ───────────────────────────────────────────────────

  ["uname"] = [[
**`uname`** — Get system identification (`<sys/utsname.h>`)

```c
#include <sys/utsname.h>

struct utsname buf;
uname(&buf);
printf("sysname:  %s\n", buf.sysname);    // "Linux"
printf("nodename: %s\n", buf.nodename);   // hostname
printf("release:  %s\n", buf.release);    // "6.2.0-32-generic"
printf("version:  %s\n", buf.version);    // kernel build info
printf("machine:  %s\n", buf.machine);    // "x86_64"
```

**See also:** `gethostname`, `sysconf`]],

  ["sysconf"] = [[
**`sysconf`** — Get system configuration limits (`<unistd.h>`)

```c
long nprocs = sysconf(_SC_NPROCESSORS_ONLN);   // online CPUs
long nprocs_conf = sysconf(_SC_NPROCESSORS_CONF);  // configured CPUs
long clktck = sysconf(_SC_CLK_TCK);             // clock ticks per second
long pagesz = sysconf(_SC_PAGESIZE);            // memory page size
long argmax = sysconf(_SC_ARG_MAX);             // max arguments to exec
long openmax = sysconf(_SC_OPEN_MAX);           // max open fds per process
```

Returns -1 on error (or if limit is indeterminate). Use `sysconf` instead of hardcoding constants.

**See also:** `pathconf`, `fpathconf`, `getrlimit`]],

  ["gethostname"] = [[
**`gethostname`** — Get hostname of the machine (`<unistd.h>`)

```c
char hostname[HOST_NAME_MAX + 1];
gethostname(hostname, sizeof(hostname));
```

Truncated if buffer is smaller than `HOST_NAME_MAX + 1`. Can be set with `sethostname` (root only).

**See also:** `uname`, `getdomainname`]],

  ["getrlimit"] = [[
**`getrlimit`** — Get/set resource limits (`<sys/resource.h>`)

```c
#include <sys/resource.h>

struct rlimit rl;
getrlimit(RLIMIT_NOFILE, &rl);     // max open file descriptors
// rl.rlim_cur = soft limit, rl.rlim_max = hard limit

rl.rlim_cur = 4096;
setrlimit(RLIMIT_NOFILE, &rl);

// Other resources:
RLIMIT_CPU      // CPU time (seconds)
RLIMIT_AS       // address space (bytes)
RLIMIT_DATA     // data segment (bytes)
RLIMIT_STACK    // stack size (bytes)
RLIMIT_CORE     // core file size (bytes)
RLIMIT_NPROC    // max child processes
```

**See also:** `sysconf`, `getrusage`, `ulimit` (shell builtin)]],

  ["getrusage"] = [[
**`getrusage`** — Get resource usage (`<sys/resource.h>`)

```c
#include <sys/resource.h>

struct rusage usage;
getrusage(RUSAGE_SELF, &usage);     // resources used by calling process
getrusage(RUSAGE_CHILDREN, &usage); // resources used by waited-for children
getrusage(RUSAGE_THREAD, &usage);   // resources used by calling thread (Linux)

printf("user CPU: %ld.%06lds\n",
    usage.ru_utime.tv_sec, usage.ru_utime.tv_usec);
printf("sys  CPU: %ld.%06lds\n",
    usage.ru_stime.tv_sec, usage.ru_stime.tv_usec);
printf("max RSS:  %ld KB\n", usage.ru_maxrss);
```

**See also:** `getrlimit`, `times`, `clock_gettime`]],

  ["getpwuid"] = [[
**`getpwuid`** — Get user info by UID (`<pwd.h>`)

```c
#include <pwd.h>

struct passwd *pw = getpwuid(1000);   // lookup by UID
struct passwd *pw = getpwnam("alice"); // lookup by name
// Reentrant: getpwuid_r, getpwnam_r

if (pw) {
    printf("name:   %s\n", pw->pw_name);
    printf("uid:    %d\n", pw->pw_uid);
    printf("gid:    %d\n", pw->pw_gid);
    printf("home:   %s\n", pw->pw_dir);
    printf("shell:  %s\n", pw->pw_shell);
}
```

**See also:** `getgrgid`, `getlogin`, `getuid`]],

  ["getgrgid"] = [[
**`getgrgid`** — Get group info by GID (`<grp.h>`)

```c
#include <grp.h>

struct group *gr = getgrgid(1000);   // lookup by GID
struct group *gr = getgrnam("staff"); // lookup by name

if (gr) {
    printf("name:  %s\n", gr->gr_name);
    printf("gid:   %d\n", gr->gr_gid);
    // gr->gr_mem: null-terminated array of member names
    for (char **m = gr->gr_mem; *m != NULL; m++)
        printf("  member: %s\n", *m);
}
```

**See also:** `getpwuid`, `getgroups`, `getgid`, `getegid`]],

  ["getuid"] = [[
**`getuid`** — Get user/group identity (`<unistd.h>`)

```c
uid_t uid = getuid();        // real user ID
uid_t euid = geteuid();      // effective user ID (used for permission checks)
gid_t gid = getgid();        // real group ID
gid_t egid = getegid();      // effective group ID

int ngroups = getgroups(0, NULL);    // supplementary group count
gid_t list[ngroups];
getgroups(ngroups, list);            // supplementary group list
```

**See also:** `setuid`, `seteuid`, `getpwuid`, `getlogin`]],

  -- ── File system events and notifications ───────────────────────────────────

  ["flock"] = [[
**`flock`** — Apply or remove an advisory lock (`<sys/file.h>`)

```c
#include <sys/file.h>

fd = open("lockfile", O_CREAT | O_RDWR, 0644);
flock(fd, LOCK_EX);     // exclusive lock (blocking)
// ... critical section ...
flock(fd, LOCK_UN);     // unlock

// Non-blocking:
if (flock(fd, LOCK_EX | LOCK_NB) == -1) {
    if (errno == EWOULDBLOCK) { /* lock held by another process */ }
}
```

**Advisory** — cooperating processes must use flock. Released automatically when all fds to the file are closed.

**See also:** `fcntl` (POSIX record locking), `lockf`, `open`]],

  ["ftruncate"] = [[
**`ftruncate`** — Truncate a file to a specified length (`<unistd.h>`)

```c
ftruncate(fd, 0);            // empty the file
ftruncate(fd, 4096);         // extend or shrink to 4096 bytes
```

Extending with `ftruncate` creates a **sparse file** (reads return zero for the new area). Can be used with `mmap` to allocate resizable memory-mapped regions.

**See also:** `truncate`, `fallocate`, `mmap`, `lseek`]],

  ["fallocate"] = [[
**`fallocate`** — Pre-allocate space for a file (`<fcntl.h>`, Linux)

```c
#include <fcntl.h>

fallocate(fd, 0, 0, 1 << 30);           // allocate 1 GiB, space guaranteed
fallocate(fd, FALLOC_FL_KEEP_SIZE, 0, 1 << 30);  // allocate but don't change size
fallocate(fd, FALLOC_FL_PUNCH_HOLE | FALLOC_FL_KEEP_SIZE, 0, 4096);  // punch a hole
```

**Pre-allocate** disk space without writing data (faster than writing zeros). Returns `ENOSPC` if insufficient space. `FALLOC_FL_PUNCH_HOLE` deallocates blocks (makes the file sparse).

**See also:** `ftruncate`, `posix_fallocate`, `mmap`, `lseek`]],

  ["posix_fallocate"] = [[
**`posix_fallocate`** — Allocate disk space (POSIX, `<fcntl.h>`)

```c
int err = posix_fallocate(fd, 0, 1 << 30);  // returns 0 on success
```

Like `fallocate` but **portable**. Guarantees that subsequent writes to the range won't fail due to ENOSPC. May write zeros on systems without `fallocate` support.

**See also:** `fallocate`, `ftruncate`, `mmap`]],

  ["sendfile"] = [[
**`sendfile`** — Copy data between file descriptors (`<sys/sendfile.h>`, Linux)

```c
#include <sys/sendfile.h>

int in_fd = open("input", O_RDONLY);
int out_fd = open("output", O_WRONLY | O_CREAT | O_TRUNC, 0644);
off_t offset = 0;
ssize_t n = sendfile(out_fd, in_fd, &offset, 1 << 20);  // copy 1 MiB
```

**Zero-copy** — data is transferred within the kernel without copying to userspace. Efficient for serving static files. Returns the number of bytes copied.

**See also:** `splice`, `copy_file_range`, `write`, `mmap`]],

  ["copy_file_range"] = [[
**`copy_file_range`** — Copy data between file descriptors (Linux, `<unistd.h>`)

```c
#include <unistd.h>

loff_t in_off = 0, out_off = 0;
ssize_t n = copy_file_range(in_fd, &in_off, out_fd, &out_off, 1 << 20, 0);
```

**Server-side copy** — kernel may perform it within the filesystem (reflink on CoW filesystems like btrfs/xfs). Faster than `sendfile` + userspace loop.

**See also:** `sendfile`, `splice`, `read`, `write`]],

  ["splice"] = [[
**`splice`** — Move data between two file descriptors (Linux, `<fcntl.h>`)

```c
int pipefd[2];
pipe(pipefd);

// Move data from in_fd to pipe without userspace copy:
ssize_t n = splice(in_fd, NULL, pipefd[1], NULL, 4096, SPLICE_F_MOVE);
// Move data from pipe to out_fd:
n = splice(pipefd[0], NULL, out_fd, NULL, n, SPLICE_F_MOVE);
```

**Zero-copy** data transfer between two fds (must use a pipe as intermediary). More flexible than `sendfile`.

**See also:** `sendfile`, `copy_file_range`, `tee`, `pipe`]],

  -- ── Miscellaneous ──────────────────────────────────────────────────────────

  ["ioctl"] = [[
**`ioctl`** — Device I/O control (`<sys/ioctl.h>`)

```c
#include <sys/ioctl.h>

// Terminal size:
struct winsize ws;
ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws);
printf("rows: %d, cols: %d\n", ws.ws_row, ws.ws_col);

// Non-blocking stdin:
int flags = 0;
ioctl(STDIN_FILENO, FIONBIO, &flags);

// Device-specific operations (driver-defined).
```

**Generic kitchen-sink syscall** — used for terminal, device, and network interface control. Request codes are device-specific and often poorly documented.

**See also:** `fcntl`, `tcgetattr`, `open`]],

  ["isatty"] = [[
**`isatty`** — Check if fd is a terminal (`<unistd.h>`)

```c
if (isatty(STDOUT_FILENO)) {
    // stdout is connected to a terminal
} else {
    // probably piped or redirected to a file
}
```

Often used to decide whether to use colour output, or whether to print progress information interactively.

**See also:** `ttyname`, `tcgetattr`, `fileno`]],

  ["umask"] = [[
**`umask`** — Set file creation mask (`<sys/stat.h>`)

```c
mode_t old = umask(022);   // set umask, return previous
// Created files: 0666 - umask = 0644 (rw-r--r--)
// Created dirs:  0777 - umask = 0755 (rwxr-xr-x)
```

Unset bits in `umask` are cleared from the permission bits of all newly created files/directories. Common values: `022` (group/other cannot write), `077` (only owner can read).

**See also:** `open`, `creat`, `mkdir`, `chmod`]],

  ["syslog"] = [[
**`syslog`** — Log messages to system logger (`<syslog.h>`)

```c
#include <syslog.h>

openlog("myapp", LOG_PID | LOG_NDELAY, LOG_USER);
syslog(LOG_INFO, "application started (pid=%d)", getpid());
syslog(LOG_ERR, "failed to open config: %m");  // %m = current errno string
closelog();

// Priority levels (most to least severe):
// LOG_EMERG, LOG_ALERT, LOG_CRIT, LOG_ERR,
// LOG_WARNING, LOG_NOTICE, LOG_INFO, LOG_DEBUG
```

Messages go to syslog daemon (typically `/var/log/syslog` or `journald`). `%m` is a glibc extension that expands to `strerror(errno)`.

**See also:** `openlog`, `closelog`, `setlogmask`]],

  ["backtrace"] = [[
**`backtrace`** — Get function call trace (glibc, `<execinfo.h>`)

```c
#include <execinfo.h>

void print_backtrace(void) {
    void *buffer[100];
    int n = backtrace(buffer, 100);                  // get return addresses
    char **symbols = backtrace_symbols(buffer, n);    // resolve to symbols
    for (int i = 0; i < n; i++) {
        fprintf(stderr, "%s\n", symbols[i]);
    }
    free(symbols);
}
```

**See also:** `addr2line` (tool), `libunwind`, `__builtin_return_address`]],

  ["endian"] = [[
**`endian`** — Byte order conversion (`<endian.h>`, `<arpa/inet.h>`)

```c
#include <arpa/inet.h>

// Network byte order is big-endian:
uint32_t n = htonl(0x12345678);   // host → network (32-bit)
uint32_t h = ntohl(n);            // network → host (32-bit)
uint16_t s = htons(0x1234);       // host → network (16-bit)
uint16_t t = ntohs(s);            // network → host (16-bit)

// Detecting endianness:
int x = 1;
bool little = *(char*)&x == 1;    // little-endian (x86 / most ARM)
```

**See also:** `byteorder` (3), `be64toh`, `htobe64`, `le64toh`, `htole64`]],

  -- ── Error helpers ──────────────────────────────────────────────────────────

  ["perror"] = [[
**`perror`** — Print errno description to stderr (`<stdio.h>`)

```c
#include <stdio.h>

int fd = open("nonexistent", O_RDONLY);
if (fd == -1) {
    perror("open");               // "open: No such file or directory"
    perror(NULL);                  // just the error string (non-standard)
}
```

**See also:** `strerror`, `errno`, `printf`, `dprintf`]],

  ["strerror"] = [[
**`strerror`** — Get string description of error number (`<string.h>`)

```c
#include <string.h>

printf("%s\n", strerror(errno));   // "No such file or directory"

// Reentrant (C11):
char buf[256];
strerror_r(errno, buf, sizeof(buf));   // GNU version: returns char*
// XSI-compliant version: returns int, fills buf
```

**Not thread-safe** by default (returns pointer to static buffer). Use `strerror_r` in threaded code.

**See also:** `perror`, `errno`, `printf`]],

  ["errno"] = [[
**`errno`** — Last error code (`<errno.h>`)

```c
#include <errno.h>
#include <string.h>

int fd = open("file", O_RDONLY);
if (fd == -1) {
    fprintf(stderr, "errno: %d — %s\n", errno, strerror(errno));
}

// Common values:
// EPERM      (1): Operation not permitted
// ENOENT     (2): No such file or directory
// EIO        (5): I/O error
// EACCES    (13): Permission denied
// EEXIST    (17): File exists
// EINTR     (4): Interrupted system call
// EAGAIN    (11): Resource unavailable, try again
// ENOMEM    (12): Out of memory
// EBADF     (9): Bad file descriptor
// EINVAL    (22): Invalid argument
// EPIPE     (32): Broken pipe
// EDOM      (33): Math argument out of domain
// ERANGE    (34): Result too large
```

`errno` is a thread-local variable. Should be checked immediately after a function indicates failure (before any other calls that might modify it).

**See also:** `perror`, `strerror`, `open`, `read`, `write`]],
}
