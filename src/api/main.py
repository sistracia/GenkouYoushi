from typing import Union, cast, Annotated
from .types import Kanji, KanjiIndex
from fastapi import FastAPI, Path, HTTPException
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
from json.decoder import JSONDecoder, JSONDecodeError
from base64 import b64encode

def get_kvg_index() -> Union[KanjiIndex, None]:
    req = Request(url="https://raw.githubusercontent.com/KanjiVG/kanjivg/refs/heads/master/kvg-index.json")
    jsonDecoder = JSONDecoder()
    
    try:
        response = urlopen(req)
        return cast(KanjiIndex, jsonDecoder.decode(response.read().decode('utf-8')))
    except HTTPError as e:
        raise Exception(f"The server couldn\'t fulfill the KVG Index request. Error code: {e.code}")
    except URLError as e:
        raise Exception(f"We failed to reach a KVG Index server. Reason: {e.reason}")
    except JSONDecodeError as e:
        raise Exception(f"Fail to decode KVG Index string to JSON. Reason: {e.reason}")

    raise Exception("Unknown error on KVG Index")
    
def get_kvg(kanji: str) -> Union[str, None]:
    req = Request(url=f"https://raw.githubusercontent.com/KanjiVG/kanjivg/refs/heads/master/kanji/{kanji}")
    
    try:
        response = urlopen(req)
        return response.read().decode('utf-8')
    except HTTPError as e:
        raise Exception(f"The server couldn\'t fulfill the SVG request. Error code: {e.code}")
    except URLError as e:
        raise Exception(f"We failed to reach a SVG server. Reason: {e.reason}")

    raise Exception("Unknown error on SVG")

app = FastAPI(docs_url='/docs')

@app.get("/kanji/{kanji}")
def get_kanji_index(kanji: Annotated[str, Path(title="The kanji to get")]) -> Kanji:
    try:
        kvg_index = get_kvg_index()

        kvgs = kvg_index.get(kanji) or []
        kvg = kvgs[-1] if len(kvgs) != 0 else None
        if kvg is None:
            raise HTTPException(status_code=404, detail="Kanji not found in index.")

        kvg_file = get_kvg(kvg)
        if kvg_file is None:
            raise HTTPException(status_code=404, detail="Kanji strokes not found.")
        
        kanji: Kanji = {'kanji': b64encode(kvg_file.encode(encoding='utf-8', errors="strict"))}
        return kanji
    except HTTPException as e:
        raise e
    except UnicodeError as e:
        raise HTTPException(status_code=500, detail=f"Fail to encode KVG file. Reason: {e.reason}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fail somewhere. Reason: {e}")
