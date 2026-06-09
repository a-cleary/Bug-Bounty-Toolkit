from core.normailize import normalize_seed, normalize_subdomain

def load_domains(filename: str) -> set[str]:
    domains = set()
    with open(filename, "r") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            domains.add(normalize_seed(line))
    return domains


def load_known_subdomains(filename: str) -> set[str]:
    subs = set()
    with open(filename, "r") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            subs.add(normalize_subdomain(line))
    return subs