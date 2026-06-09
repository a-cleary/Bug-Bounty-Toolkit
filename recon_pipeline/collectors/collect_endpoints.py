class CollectEndpoints:

    EXTENSIONS = (
        ".js",
        ".css",
        ".png",
        ".jpg",
        ".jpeg",
        ".gif",
        ".svg",
        ".ico",
        ".woff",
        ".woff2"
    )

    def run(self, urls):
        return sorted({url for url in urls if not url.lower().endswith(self.EXTENSIONS)})