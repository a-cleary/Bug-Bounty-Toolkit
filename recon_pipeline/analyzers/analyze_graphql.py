import requests


class AnalyzeGraphql:
    PATHS = [
        "/graphql",
        "/api/graphql",
        "/query"
    ]

    def run(self, urls):
        findings = []
        for url in urls:
            base = url.rstrip("/")
            for path in self.PATHS:
                try:
                    response = requests.post(
                        f"{base}{path}",
                        json={
                            "query":
                            "{__typename}"
                        },
                        timeout=10
                    )

                    if response.status_code in (200, 400):
                        findings.append(f"{base}{path}")
                except Exception:
                    pass

        return sorted(set(findings))