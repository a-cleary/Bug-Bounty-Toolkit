import argparse

# Generic functionality
from core.aggregate import Aggregate
from core.loader import load_hosts
from core.output import write_json

# Runs tools from the command line
from modules.httpx import RunHttpx
from modules.naabu import RunNaabu
from modules.nmap import RunNmap
from modules.gowitness import RunGowitness
from modules.katana import RunKatana

# Collects data from tool output or via web request
from collectors.collect_js import CollectJs
from collectors.collect_endpoints import CollectEndpoints
from collectors.collect_parameters import CollectParameters
from collectors.collect_robots import CollectRobots
from collectors.collect_sitemaps import CollectSitemaps

# Analyzes previous results for more informed output
from analyzers.analyze_javascript import AnalyzeJavascript
from analyzers.analyze_secrets import AnalyzeSecrets
from analyzers.analyze_swagger import AnalyzeSwagger
from analyzers.analyze_graphql import AnalyzeGraphql
from analyzers.analyze_technologies import AnalyzeTechnologies


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    # Probe hosts
    hosts = load_hosts(args.input)
    live_hosts = RunHttpx().run(hosts)
    write_json(f"{args.output}/live_hosts.json", live_hosts)

    # Screenshots
    RunGowitness().run(live_hosts, args.output)

    # Port scanning
    ports = RunNaabu().run([host["host"] for host in live_hosts])
    write_json(f"{args.output}/ports.json", ports)

    # Nmap on hosts with "interesting" ports
    RunNmap().run(ports, args.output)

    # Find URLs
    urls = RunKatana().run([host["url"] for host in live_hosts])
    write_json(f"{args.output}/urls.json", sorted(urls))
    
    # Collect JavaScript
    js_files = CollectJs().run(urls)
    write_json(f"{args.output}/js_files.json", js_files)

    # Collect endpoint documentation  
    endpoints = CollectEndpoints().run(urls)
    write_json(f"{args.output}/endpoints.json", endpoints)

    # Parameter mining
    parameters = CollectParameters().run(urls)
    write_json(f"{args.output}/parameters.json", parameters)

    # /robots.txt
    robots = CollectRobots().run([host["url"] for host in live_hosts])
    write_json(f"{args.output}/robots.json", robots)

    # /sitemap.xml
    sitemaps = CollectSitemaps().run([host["url"] for host in live_hosts])
    write_json(f"{args.output}/sitemaps.json", sitemaps)

    # Analyze previously found JS files
    js_analysis = AnalyzeJavascript().run(js_files)
    write_json(f"{args.output}/javascript.json", js_analysis)

    # Search for secrets
    secrets = AnalyzeSecrets().run(js_files)
    write_json(f"{args.output}/secrets.json", secrets)

    # Search for API documentation
    swagger = AnalyzeSwagger().run([host["url"] for host in live_hosts])
    write_json(f"{args.output}/swagger.json", swagger)

    # Search for graphql endpoints
    graphql = AnalyzeGraphql().run([host["url"] for host in live_hosts])
    write_json(f"{args.output}/graphql.json", graphql)

    # Search for tech stack
    technologies = AnalyzeTechnologies().run(live_hosts)
    write_json(f"{args.output}/technologies.json", technologies)

    # Aggregated results - may be useful for mapping enumerated items to assets
    assets = Aggregate().run(args.output)
    write_json(f"{args.output}/assets.json", assets)

if __name__ == "__main__":
    main()