#!/usr/bin/env bash

set -euo pipefail

#######################
# Informational Files #
#######################
touch \
    notes.txt \
    credentials.txt

###############
# Directories #
###############

mkdir -p \
    scope \
    discovery \
    content \
    enrichment \
    findings \
    repos \

###############
# Scope Files #
###############

touch \
    scope/wildcard_domains.txt \
    scope/known_subdomains.txt \
    scope/out_of_scope.txt

###################
# Discovery Files #
###################

touch \
    discovery/enum_results.txt \
    discovery/subdomains_raw.txt \
    discovery/subdomains.txt \
    discovery/live_hosts.txt \
    discovery/live_hosts.json

#################
# Content Files #
#################

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
    content/git_secrets.txt \
    content/git_urls.txt \
    content/git_candidates.json

####################
# Enrichment Files #
####################

mkdir -p enrichment/screenshots

touch \
    enrichment/technologies.json \
    enrichment/waf.json \
    enrichment/interesting_hosts.txt

##################
# Findings Files #
##################

touch \
    findings/nuclei.jsonl \
    findings/wordpress.txt \
    findings/joomla.txt \
    findings/graphql.txt \
    findings/exposed_panels.txt

############################
# Cloud and Infrastructure #
############################
mkdir -p \
    cloud/aws \
    cloud/azure \
    cloud/gcp \
    infrastructure/dns \
    infrastructure/email \
    infrastructure/asn \
    infrastructure/identity \
    infrastructure/developer \
    infrastructure/monitoring

touch \
    cloud/cloud_assets.txt \
    cloud/storage.txt \
    cloud/aws/aws.txt \
    cloud/azure/azure.txt \
    cloud/gcp/gcp.txt

touch \
    infrastructure/dns/mx.txt \
    infrastructure/dns/txt.txt \
    infrastructure/dns/ns.txt \
    infrastructure/dns/caa.txt

touch \
    infrastructure/email/spf.txt \
    infrastructure/email/dmarc.txt

touch \
    infrastructure/asn/asn.txt \
    infrastructure/asn/netblocks.txt

touch \
    infrastructure/identity/identity.txt \
    infrastructure/developer/developer_tools.txt \
    infrastructure/monitoring/monitoring.txt


#############
# ASN Files #
#############
mkdir -p asn

touch \
    asn/ips.txt \
    asn/asns.txt \
    asn/netblocks.txt \
    asn/ptr.txt \
    asn/discovered_hosts.txt \
    asn/interesting_hosts.txt \
    asn/live_hosts.txt


#############
# API Files #
#############
mkdir -p api

touch \
    api/graphql.txt \
    api/swagger.txt \
    api/openapi.txt \
    api/postman.txt \
    api/api_hosts.txt \
    api/endpoints.txt \
    api/live_endpoints.txt


#################
# Secrets Files #
#################
mkdir -p secrets

touch \
    secrets/aws.txt \
    secrets/github.txt \
    secrets/slack.txt \
    secrets/jwt.txt \
    secrets/generic.txt \
    secrets/urls.txt \
    secrets/summary.txt


#############
# Takeovers #
#############
mkdir -p takeover

touch \
    discovery/all_subdomains.txt \
    takeover/takeovers.txt \
    takeover/takeovers.json



#############
# Takeovers #
#############
mkdir -p ports

touch \
    ports/open_ports.txt \
    ports/open_ports.json \
    ports/nmap.txt


###################
# Success Message #
###################

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

Information Files for Convinience:

  notes.txt - Store any type of information about the program
  credentials.txt - Store any type of created user accounts

Then run:

  ./recon.sh

After initial recon consider modules/ for more specific recon tasks


=========================================

EOF
