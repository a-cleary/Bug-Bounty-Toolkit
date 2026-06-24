# Bug Bounty Recon Toolkit

A modular Bash-based bug bounty reconnaissance framework designed to automate asset discovery, URL collection, JavaScript analysis, repository exposure detection, technology fingerprinting, and vulnerability candidate generation.

The toolkit follows a structured workflow, allowing researchers to build a progressively enriched attack surface from a small list of in-scope domains.

---

## How to Use

### 1. Initialize the Workspace

Run the setup script to create the required directory structure and placeholder files:

```bash
chmod +x setup.sh
./setup.sh
```

---

### 2. Configure Scope

Populate the files in the `scope/` directory.

Add root domains to:

```text
scope/wildcard_domains.txt
```

Example:

```text
example.com
example.org
```

Add known assets to:

```text
scope/known_subdomains.txt
```

Example:

```text
vpn.example.com
legacy.example.com
```

Add exclusions to:

```text
scope/out_of_scope.txt
```

Example:

```text
*.internal.example.com
dev.example.com
```

---

### 3. Run Recon

```bash
chmod +x recon.sh
./recon.sh
```

The toolkit will execute all enabled phases and store results in their respective directories.

---

## Disclaimer

This project is intended for authorized security testing, bug bounty programs, and defensive security research only.

Users are responsible for ensuring all activities comply with applicable laws, regulations, and program rules. Unauthorized testing against systems without permission may be illegal.
