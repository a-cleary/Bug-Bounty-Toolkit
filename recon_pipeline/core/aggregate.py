import json
from pathlib import Path


class Aggregate:
    def run(self, output_dir):
        assets = {}
        for path in Path(output_dir).glob("*.json"):
            if path.name == "assets.json":
                continue
            with open(path) as handle:
                data = json.load(handle)
            source = path.stem
            if not isinstance(data, list):
                continue
            for record in data:
                if not isinstance(record, dict):
                    continue
                host = record.get("host")
                if not host:
                    continue
                asset = assets.setdefault(host, {"host": host})
                asset.setdefault(source, []).append(record)

        return assets