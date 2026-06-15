#!/usr/bin/env bash

set -euo pipefail

########################################
# Directories
########################################

mkdir -p \
    scope \
    discovery \
    content \
    enrichment \
    findings \
    repos \
    tools

########################################
# Scope Files
########################################

touch \
    scope/wildcard_domains.txt \
    scope/known_subdomains.txt \
    scope/out_of_scope.txt

########################################
# Discovery Files
########################################

touch \
    discovery/enum_results.txt \
    discovery/subdomains_raw.txt \
    discovery/subdomains.txt \
    discovery/live_hosts.txt \
    discovery/live_hosts.json

########################################
# Content Files
########################################

touch \
    content/gau.txt \
    content/waybackurls.txt \
    content/historical_urls.txt \
    content/katana_urls.txt \
    content/all_urls.txt \
    content/expanded_urls.txt \
    content/params.txt \
    content/js_files.txt \
    content/js_endpoints.txt \
    content/js_secrets.txt \
    content/linkfinder_raw.txt \
    content/secretfinder_raw.txt \
    content/xss_candidates.txt \
    content/sqli_candidates.txt \
    content/ssrf_candidates.txt \
    content/redirect_candidates.txt \
    content/git_candidates.txt \
    content/git_repos.txt \
    content/git_secrets.txt

########################################
# Enrichment Files
########################################

mkdir -p enrichment/screenshots

touch \
    enrichment/technologies.json \
    enrichment/waf.json \
    enrichment/interesting_hosts.txt

########################################
# Findings Files
########################################

touch \
    findings/nuclei.jsonl \
    findings/wordpress.txt \
    findings/joomla.txt \
    findings/graphql.txt \
    findings/exposed_panels.txt


########################################
# Success Message
########################################

cat <<EOF

=========================================
Bug Bounty Toolkit Initialized
=========================================

Directories Created:

  scope/
  discovery/
  content/
  enrichment/
  findings/
  repos/

Populate:

  scope/wildcard_domains.txt
  scope/known_subdomains.txt
  scope/out_of_scope.txt

Then run:

  ./recon.sh

=========================================

EOF