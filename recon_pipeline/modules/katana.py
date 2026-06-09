from core.cli import run_command


class RunKatana:
    def run(self, urls):
        output = run_command(
            [
                "katana",
                "-silent",
                "-jc"
            ],
            stdin="\n".join(urls),
            timeout=None
        )
        return {line.strip() for line in output.splitlines() if line.strip()}