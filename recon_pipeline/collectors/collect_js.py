class CollectJs:
    def run(self, urls):
        return sorted({url for url in urls if ".js" in url.lower()})