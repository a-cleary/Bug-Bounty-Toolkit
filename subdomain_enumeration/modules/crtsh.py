import requests

from modules.base import EnumerationModule


class CallCrtSh(EnumerationModule):

    def name(self):
        return "crtsh"

    def enumerate(self, domain: str) -> set[str]:
        results = set()
        url = f"https://crt.sh/?q=%25.{domain}&output=json"
        try:
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            data = response.json()
            for record in data:
                names = record.get("name_value", "")
                for name in names.split("\n"):
                    name = name.strip().lower().replace("*.", "").rstrip(".")
                    if not name:
                        continue
                    if (name == domain or name.endswith(f".{domain}")):
                        results.add(name)

        except Exception:
            pass

        return results