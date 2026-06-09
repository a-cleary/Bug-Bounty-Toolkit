from fnmatch import fnmatch


def apply_exclusions(subdomains, exclusions):
    return {subdomain for subdomain in subdomains if not any(fnmatch(subdomain, pattern) for pattern in exclusions)}