import re
import requests


class AnalyzeJavascript:
    URL_REGEX = re.compile(
        r'["\'](/[^"\']+|https?://[^"\']+)["\']'
    )
    def run(self, js_files):
        results = {}
        for url in js_files:
            try:
                response = requests.get(url, timeout=15)

                matches = {match.group(1) for match in self.URL_REGEX.finditer(response.text)}
                results[url] = sorted(matches)
            except Exception:
                pass

        return results