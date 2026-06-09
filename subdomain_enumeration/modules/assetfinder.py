from core.cli import run_command
from modules.base import EnumerationModule


class RunAssetfinder(EnumerationModule):
    def name(self):
        return "assetfinder"

    def enumerate(self, domain: str) -> set[str]:
        lines = run_command(
            [
                "assetfinder",
                "--subs-only",
                domain
            ]
        )

        return {line.lower().rstrip(".") for line in lines if (line == domain or line.endswith(f".{domain}"))}