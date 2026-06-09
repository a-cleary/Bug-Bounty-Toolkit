import requests
import xml.etree.ElementTree as ET


class CollectSitemaps:
    def run(self, urls):
        results = {}
        for url in urls:
            sitemap_url = (f"{url.rstrip('/')}/sitemap.xml")
            try:
                response = requests.get(sitemap_url, timeout=10)
                if response.status_code != 200:
                    continue
                root = ET.fromstring(response.text)
                entries = []
                for elem in root.iter():
                    if elem.tag.endswith("loc"):
                        entries.append(elem.text)
                results[url] = entries
            except Exception:
                pass

        return results