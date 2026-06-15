# Bug Bounty Recon Toolkit

A modular Bash-based bug bounty reconnaissance framework designed to automate asset discovery, URL collection, JavaScript analysis, repository exposure detection, technology fingerprinting, and vulnerability candidate generation.

The toolkit follows a structured workflow, allowing researchers to build a progressively enriched attack surface from a small list of in-scope domains.

---

## Features

### Asset Discovery

* Subdomain enumeration using:

  * Subfinder
  * Assetfinder
  * Amass
  * crt.sh
* Scope filtering
* Live host validation with HTTPX

### Historical URL Collection

* GAU integration
* WaybackURLs integration
* Historical URL aggregation and deduplication

### URL Enrichment

* Katana crawling
* Parameter extraction with Unfurl
* Candidate generation using GF patterns:

  * XSS
  * SQL Injection
  * SSRF
  * Open Redirect

### JavaScript Analysis

* JavaScript asset discovery
* LinkFinder integration
* SecretFinder integration
* Endpoint extraction
* Secret identification

### Repository Analysis

* Exposed `.git` repository detection
* Repository dumping using git-dumper
* Secret discovery with TruffleHog

### Asset Enrichment

* Technology fingerprinting with WhatWeb
* WAF detection using wafw00f
* Screenshot collection with Gowitness
* Interesting host identification

### Targeted Detection

* Nuclei scanning
* GraphQL endpoint discovery
* CMS identification
* Technology-specific targeting

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

### 4. Review Results

#### Discovery

Contains:

* Enumerated subdomains
* Live hosts
* HTTPX output

#### Content Discovery

Contains:

* Historical URLs
* Katana output
* JavaScript endpoints
* Candidate URLs
* Repository findings

#### Asset Enrichment

Contains:

* Technology fingerprints
* WAF detection results
* Screenshots
* Interesting hosts

#### Findings

Contains:

* Nuclei results
* CMS detections
* GraphQL endpoints
* Other identified findings

---

### 5. Other Addional Next Steps

> _`recon.sh` must first be ran to collect the data passively_

Other Enumeration Options:

* Cloud: `cloud.sh` finds various cloud assets such as AWS, Azure, GCP, and Storage assets.
* Infrastructure: `infrastructure.sh` finds DNS records and hosts pertaining to identity, development, and monitoring.
* ASN: `asn.sh` finds IP ranges, CIDRs, and ASNs to assist in deeper enumeration.

---

## Disclaimer

This project is intended for authorized security testing, bug bounty programs, and defensive security research only.

Users are responsible for ensuring all activities comply with applicable laws, regulations, and program rules. Unauthorized testing against systems without permission may be illegal.
