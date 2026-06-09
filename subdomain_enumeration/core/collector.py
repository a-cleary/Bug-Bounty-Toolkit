from concurrent.futures import ThreadPoolExecutor, as_completed

from core.normailize import normalize_subdomain


def collect(domains: set[str], modules: list, workers: int = 10) -> set[str]:
    results = set()
    futures = []

    with ThreadPoolExecutor(max_workers=workers) as executor:
        for domain in domains:
            for module in modules:
                futures.append(executor.submit(module.enumerate, domain))
        for future in as_completed(futures):
            try:
                subdomains = future.result()
                for subdomain in subdomains:
                    normalized = (normalize_subdomain(subdomain))
                    if normalized:
                        results.add(normalized)
            except Exception as e:
                print(f"[!] Module failed: {e}")
    return results 