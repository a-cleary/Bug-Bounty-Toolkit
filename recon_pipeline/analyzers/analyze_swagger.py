import requests


class AnalyzeSwagger:
    PATHS = [
        "/swagger",
        "/swagger-ui",
        "/swagger-ui.html",
        "/openapi.json",
        "/swagger.json",
        "/api-docs"
    ]

    def run(self, urls):
        findings = []
        for url in urls:
            base = url.rstrip("/")
            for path in self.PATHS:
                try:
                    response = requests.get(f"{base}{path}", timeout=10, allow_redirects=True)
                    if response.status_code < 400:
                        findings.append(
                            f"{base}{path}"
                        )
                except Exception:
                    pass

        return sorted(set(findings))