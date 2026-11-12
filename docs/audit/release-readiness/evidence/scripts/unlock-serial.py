#!/usr/bin/env python3
"""Answer an installed NyxOS VM's disk passphrase prompt on its serial console.

Usage: unlock-serial.py VM PASSPHRASE_FILE LOG [TIMEOUT_S]

Runs `incus console VM` (the serial console) in a pseudo-terminal, waits for the
initrd's passphrase prompt, types the passphrase, and logs the console (with the
passphrase never echoed by the prompt) until the system reaches a login prompt or the
timeout passes. Prints the seconds from start to the prompt and to the login prompt.
"""
import os
import pty
import re
import select
import sys
import time

vm, ppfile, log = sys.argv[1:4]
timeout = float(sys.argv[4]) if len(sys.argv) > 4 else 300
passphrase = open(ppfile).read().strip()

pid, fd = pty.fork()
if pid == 0:
    os.execvp("incus", ["incus", "console", vm])

start = time.time()
buf = b""
asked = None
answered = False
done = None
with open(log, "wb") as out:
    while time.time() - start < timeout:
        r, _, _ = select.select([fd], [], [], 1)
        if fd in r:
            try:
                chunk = os.read(fd, 4096)
            except OSError:
                break
            out.write(chunk)
            out.flush()
            buf = (buf + chunk)[-4096:]
        text = buf.decode("utf-8", "replace")
        if not answered and re.search(r"(?i)passphrase|password for", text):
            asked = time.time() - start
            time.sleep(0.5)
            os.write(fd, passphrase.encode() + b"\r")
            answered = True
            buf = b""
        elif answered and re.search(r"login:", text):
            done = time.time() - start
            break
        elif not answered and time.time() - start > 5 and int(time.time() - start) % 15 == 0:
            os.write(fd, b"\r")
os.write(fd, b"\x01q")
print(f"prompt_at={asked} login_at={done}")
