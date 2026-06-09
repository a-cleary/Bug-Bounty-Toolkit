from urllib.parse import urlparse, parse_qs


class CollectParameters:
    def run(self, urls):
        params = set()
        for url in urls:
            query = urlparse(url).query
            if not query:
                continue

            params.update(parse_qs(query).keys())
            
        return sorted(params)