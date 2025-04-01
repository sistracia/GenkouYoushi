from .types import Kanji
from fastapi import FastAPI

app = FastAPI(docs_url='/docs')

@app.get("/kanjis")
def all_kanjis() -> list[Kanji]:
    list_of_kanji: list[Kanji] = []
    return list_of_kanji