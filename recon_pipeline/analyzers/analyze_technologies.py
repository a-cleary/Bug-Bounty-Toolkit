class AnalyzeTechnologies:

    def run(self, live_hosts):
        results = {}
        for host in live_hosts:
            name = host.get("host")
            results[name] = {
                "title": host.get("title"),
                "status_code": host.get("status_code"),
                "tech": host.get("tech", [])
            }

        return results