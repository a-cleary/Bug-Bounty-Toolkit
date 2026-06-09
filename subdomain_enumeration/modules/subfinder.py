from core.cli import run_command
from modules.base import EnumerationModule


class RunSubfinder(EnumerationModule):

    def name(self):
        return "subfinder"

    def enumerate(self, domain: str) -> set[str]:
        lines = run_command(
            [
                "subfinder",
                "-d",
                domain,
                "-silent"
            ]
        )

        return {line.lower().rstrip(".") for line in lines if (line == domain or line.endswith(f".{domain}"))}