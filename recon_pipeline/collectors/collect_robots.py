import requests


class CollectRobots:
    def run(self, urls):
        results = {}
        for url in urls:
            robots_url = f"{url.rstrip('/')}/robots.txt"
            try:
                response = requests.get(robots_url, timeout=10)
                if response.status_code != 200:
                    continue

                disallowed = []
                for line in response.text.splitlines():
                    if line.lower().startswith("disallow:"):
                        disallowed.append(
                            line.split(":", 1)[1].strip())
                results[url] = disallowed
            except Exception:
                pass

        return results