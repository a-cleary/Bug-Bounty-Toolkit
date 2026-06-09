import json

from core.cli import run_command


class RunHttpx:
    def run(self, hosts):
        output = run_command(
            [
                "httpx",
                "-json",
                "-silent",
                "-title",
                "-tech-detect",
                "-status-code"
            ],
            stdin="\n".join(hosts)
        )
        results = []
        for line in output.splitlines():
            try:
                results.append(json.loads(line))
            except Exception:
                pass
            
        return results