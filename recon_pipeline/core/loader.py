def load_hosts(filename):
    hosts = set()
    with open(filename) as f:
        for line in f:
            line = line.strip()
            if line:
                hosts.add(line)
    return sorted(hosts)