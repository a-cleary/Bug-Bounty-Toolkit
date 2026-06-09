def normalize_seed(domain: str) -> str:
    domain = domain.strip().lower()
    if domain.startswith("*."):
        domain = domain[2:]
    return domain

def normalize_subdomain(subdomain: str) -> str:
    return subdomain.strip().lower().replace("*.", "").rstrip(".")


def belongs_to_domain(subdomain: str, domain: str) -> bool:
    return subdomain == domain or subdomain.endswith(f".{domain}")