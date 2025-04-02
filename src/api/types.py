from typing import TypedDict, TypeAlias

KanjiIndex: TypeAlias = dict[str, list[str]]

class Kanji(TypedDict):
    kanji: str