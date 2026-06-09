import json

from core.cli import run_command


class RunNaabu:
    def run(self, hosts):
        output = run_command(
            ["naabu", "-json"],
            timeout=900,
            stdin="\n".join(hosts)
        )
        results = {}
        for line in output.splitlines():
            try:
                data = json.loads(line)
                results.setdefault(
                    data["host"],
                    []
                ).append(data["port"])
            except Exception:
                pass

        return results