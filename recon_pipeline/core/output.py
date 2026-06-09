import json
from pathlib import Path


def write_json(filename, data):
    Path(filename).parent.mkdir(parents=True, exist_ok=True)
    with open(filename, "w") as handle:
        json.dump(data, handle, indent=2)