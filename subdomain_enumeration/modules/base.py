from abc import ABC, abstractmethod


class EnumerationModule(ABC):

    @abstractmethod
    def name(self) -> str:
        pass

    @abstractmethod
    def enumerate(self, domain: str) -> set[str]:
        pass