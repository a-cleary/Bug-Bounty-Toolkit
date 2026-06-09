def write_result(filename: str, subdomains: set[str]):
    with open(filename, "w") as handle:
        for subdomain in sorted(subdomains):
            handle.write(f"{subdomain}\n")