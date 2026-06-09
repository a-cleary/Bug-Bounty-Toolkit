import tempfile
from pathlib import Path

from core.cli import run_command


class RunGowitness:

    def run(self, live_hosts, output_dir):
        urls = [
            host["url"]
            for host in live_hosts
            if host.get("url")
        ]

        if not urls:
            return

        screenshot_dir = (
            Path(output_dir)
            / "screenshots"
        )

        screenshot_dir.mkdir(
            parents=True,
            exist_ok=True
        )

        with tempfile.NamedTemporaryFile(mode="w", delete=False) as handle:
            handle.write("\n".join(urls))
            filename = handle.name

        run_command(
            [
                "gowitness",
                "scan",
                "file",
                "-f",
                filename,
                "--screenshot-path",
                str(screenshot_dir)
            ],
            timeout=3600
        )