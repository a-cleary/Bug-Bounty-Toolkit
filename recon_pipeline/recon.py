import argparse

from core.loader import load_hosts
from core.output import write_json

from modules.httpx import RunHttpx
from modules.naabu import RunNaabu
from modules.nmap import RunNmap
from modules.gowitness import RunGowitness
from modules.katana import RunKatana

from collectors.collect_js import CollectJs
from collectors.collect_endpoints import CollectEndpoints
from collectors.collect_parameters import CollectParameters
from collectors.collect_robots import CollectRobots
from collectors.collect_sitemaps import CollectSitemaps

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

    hosts = load_hosts(args.input)
    live_hosts = RunHttpx().run(hosts)
    write_json(f"{args.output}/live_hosts.json", live_hosts)

    RunGowitness().run(live_hosts, args.output)

    ports = RunNaabu().run([host["host"] for host in live_hosts])
    write_json(f"{args.output}/ports.json", ports)

    RunNmap().run(ports, args.output)

    urls = RunKatana().run([host["url"] for host in live_hosts])
    write_json(f"{args.output}/urls.json", sorted(urls))
    
    js_files = CollectJs().run(urls)
    write_json(f"{args.output}/js_files.json", js_files)
    
    endpoints = CollectEndpoints().run(urls)
    write_json(f"{args.output}/endpoints.json", endpoints)

    parameters = CollectParameters().run(urls)
    write_json(f"{args.output}/parameters.json", parameters)

    robots = CollectRobots().run([host["url"] for host in live_hosts])
    write_json(f"{args.output}/robots.json", robots)

    sitemaps = CollectSitemaps().run([host["url"] for host in live_hosts])
    write_json(f"{args.output}/sitemaps.json", sitemaps)

    js_analysis = AnalyzeJavascript().run(js_files)
    write_json(f"{args.output}/javascript.json", js_analysis)

    secrets = AnalyzeSecrets().run(js_files)
    write_json(f"{args.output}/secrets.json", secrets)

    swagger = AnalyzeSwagger().run([host["url"] for host in live_hosts])
    write_json(f"{args.output}/swagger.json", swagger)

    graphql = AnalyzeGraphql().run([host["url"] for host in live_hosts])
    write_json(f"{args.output}/graphql.json", graphql)

    technologies = AnalyzeTechnologies().run(live_hosts)
    write_json(f"{args.output}/technologies.json", technologies)

if __name__ == "__main__":
    main()