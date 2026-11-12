#!/usr/bin/env python3
"""Run commands on an installed NyxOS VM through its serial console.

Usage: serial-run.py VM USER PASSWORD_FILE SCRIPT_FILE [TIMEOUT_S]

Logs in at the serial getty as USER (password from PASSWORD_FILE), runs SCRIPT_FILE with
bash (`sudo -S` inside it reads the same password from $AUDIT_PW), prints the output
between markers, and logs out. For machines without the Incus agent or SSH keys.
"""
import base64
import os
import pty
import re
import select
import sys
import time

vm, user, pwfile, script = sys.argv[1:5]
timeout = float(sys.argv[5]) if len(sys.argv) > 5 else 600
password = open(pwfile).read().strip()
payload = base64.b64encode(open(script, "rb").read()).decode()

pid, fd = pty.fork()
if pid == 0:
    os.execvp("incus", ["incus", "console", vm])


def read_until(pattern, limit):
    buf = b""
    end = time.time() + limit
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.5)
        if fd in r:
            try:
                buf += os.read(fd, 65536)
            except OSError:
                break
            if re.search(pattern, buf.decode("utf-8", "replace")):
                return buf.decode("utf-8", "replace")
    raise TimeoutError(f"waiting for {pattern!r}; got {buf[-500:]!r}")


def send(s):
    os.write(fd, s.encode() + b"\r")


time.sleep(1)
# The getty may be mid-login, or a shell may still be logged in from an earlier run.
state = None
for _ in range(12):
    send("")
    try:
        got = read_until(r"login: $|\u276f|[$#] $", 8)
        state = "shell" if re.search(r"\u276f|[$#] $", got) else "login"
        break
    except TimeoutError:
        continue
if state == "login":
    send(user)
    read_until(r"[Pp]assword: ", 30)
    send(password)
    read_until(r"\u276f|[$#] $", 60)
send("stty -echo cols 250; export TERM=dumb PAGER=cat SYSTEMD_PAGER= SYSTEMD_COLORS=0 NO_COLOR=1")
time.sleep(1)
send(
    f"AUDIT_PW='{password}' bash -c \"echo ===AUDIT-BEGIN===; echo {payload} | base64 -d | bash 2>&1; echo ===AUDIT-END===\""
)
out = read_until(r"===AUDIT-END===\r?\n", timeout)
m = re.search(r"===AUDIT-BEGIN===\r?\n(.*)===AUDIT-END===", out, re.S)
text = m.group(1) if m else out
text = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", text).replace("\r", "").replace(password, "<redacted>")
print(text)
send("exit")
time.sleep(1)
os.write(fd, b"\x01q")
