import shutil
import subprocess


def check_binary(binary: str):
    if not shutil.which(binary):
        raise RuntimeError(f"{binary} not found in PATH")


def run_command(cmd: list[str], timeout: int = 300, stdin: str | None = None):
    check_binary(cmd[0])
    proc = subprocess.run(
        cmd,
        input=stdin,
        text=True,
        capture_output=True,
        timeout=timeout
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "Command failed")
    return proc.stdout