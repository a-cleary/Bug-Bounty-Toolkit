from core.cli import run_command
from modules.base import EnumerationModule


class RunAmass(EnumerationModule):
    def name(self):
        return "amass"

    def enumerate(self, domain: str) -> set[str]:
        lines = run_command(
            [
                "amass",
                "enum",
                "-passive",
                "-d",
                domain
            ],
            timeout=None
        )

        return {line.lower().rstrip(".") for line in lines if (line == domain or line.endswith(f".{domain}"))}