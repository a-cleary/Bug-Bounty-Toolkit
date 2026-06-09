#!/usr/bin/env python3

import argparse

# Generic functions
from core.collector import collect
from core.loader import load_domains
from core.exclusions import apply_exclusions
from core.output import write_result

# Tool modules
#   RunXYZ runs a tool as a subprocess
#   CallXYZ reaches out to a public API
from modules.subfinder import RunSubfinder
from modules.assetfinder import RunAssetfinder
from modules.amass import RunAmass
from modules.crtsh import CallCrtSh


MODULES = [
    RunSubfinder(),
    RunAssetfinder(),
    RunAmass(),
    CallCrtSh()
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Passive Subdomain Enumeration Tool")
    parser.add_argument("--wildcards", "-w", required=True, help="File containing wildcafd domains")
    parser.add_argument("--known", "-k", required=False, help="Optional file containing known subdomains")
    parser.add_argument("--exclude", "-e", required=False, help="subdomains to exclude")
    parser.add_argument("--output", "-o", required=True, help="Output file")

    return parser.parse_args()


def main():
    args = parse_args()
    wildcard_domains = load_domains(args.wildcards)
    results = collect(wildcard_domains, MODULES)
    if args.known:
        known = load_domains(args.known)
        results.update(known)
    if args.exclude:
        exclusions = load_domains(args.exclude)
        if exclusions:
            results = apply_exclusions(results, exclusions)

    # Enumerate wildcards, add in known subdomains, remove the excluded out of scope domains
    write_result(args.output, results)


if __name__ == "__main__":
    main()