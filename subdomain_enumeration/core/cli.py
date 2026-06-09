import shutil
import subprocess


def check_binary(binary: str):
    if not shutil.which(binary):
        raise RuntimeError(f"{binary} not found in PATH")


def run_command(cmd: list[str], timeout: None | int = 300) -> list[str]:
    check_binary(cmd[0])
    proc = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=timeout
    )

    if proc.returncode != 0:
        stderr = proc.stderr.strip()
        raise RuntimeError(stderr or f"Command failed: {' '.join(cmd)}")

    return [line.strip() for line in proc.stdout.splitlines() if line.strip()]