from pathlib import Path

from core.cli import run_command


INTERESTING_PORTS = {
    21,
    22,
    25,
    53,
    3306,
    5432,
    6379,
    8080,
    8443,
    9200,
    27017
}


class RunNmap:
    def run(self, port_results, output_dir):
        nmap_dir = Path(output_dir) / "nmap"
        nmap_dir.mkdir(
            parents=True,
            exist_ok=True
        )
        for host, ports in port_results.items():
            if not any(port in INTERESTING_PORTS for port in ports):
                continue

            run_command(
                [
                    "nmap",
                    "-sV",
                    "-sC",
                    "-p",
                    ",".join(list(set(map(str, ports)))),
                    "-oN",
                    str(nmap_dir / f"{host}.txt"),
                    host
                ],
                timeout=1800
            )