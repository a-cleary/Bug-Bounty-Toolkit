import re
import requests


class AnalyzeSecrets:
    PATTERNS = {
        "aws_access_key":
            r"AKIA[0-9A-Z]{16}",

        "google_api_key":
            r"AIza[0-9A-Za-z\-_]{35}",

        "github_token":
            r"ghp_[0-9A-Za-z]{36}",

        "jwt":
            r"eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+"
    }

    def run(self, js_files):
        findings = []
        for url in js_files:
            try:
                response = requests.get(url, timeout=15)
                content = response.text
                for name, pattern in self.PATTERNS.items():
                    matches = re.findall(pattern, content)
                    if matches:
                        findings.append({
                            "file": url,
                            "type": name,
                            "count": len(matches)
                        })
            except Exception:
                pass

        return findings