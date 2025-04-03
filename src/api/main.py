from typing import Union, cast, Annotated
from .types import Kanji, KanjiIndex
from fastapi import FastAPI, Path, HTTPException
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
from json.decoder import JSONDecoder, JSONDecodeError
from base64 import b64encode
from xml.etree import ElementTree
from re import search, DOTALL
from functools import reduce

def element_tostring(element: ElementTree.Element) -> str:
    return ElementTree.tostring(element, encoding="unicode", method="xml").strip()

def previous_element_string(elements: list[ElementTree.Element]) -> str:
    return reduce(lambda value, element: f"{value}\t{element_tostring(element)}\n", elements, "")

def svg_to_progressive_strings(svg_string: str, stroke_path: str) -> list[str]:
    xml_version_declaration = search(r'<\?xml.*?\?>', svg_string).group(0)
    doctype_declaration = search(r'<!DOCTYPE.*?\]>', svg_string, DOTALL).group(0)
    svg_tag = search(r'<svg xmlns="http://www.w3.org/2000/svg".*?>', svg_string).group(0)
    stroke_paths_tag = search(r'<g id="kvg:StrokePaths.*?>', svg_string).group(0)
    stroke_numbers_tag = search(r'<g id="kvg:StrokeNumbers.*?>', svg_string).group(0)

    ns = {"svg": "http://www.w3.org/2000/svg"}
    ElementTree.register_namespace("", ns["svg"])
    root = ElementTree.fromstring(svg_string)

    path_group = root.find(f".//svg:*[@id='kvg:StrokePaths_{stroke_path}']", ns)
    text_group = root.find(f".//svg:*[@id='kvg:StrokeNumbers_{stroke_path}']", ns)

    path_elements = path_group.findall(".//svg:path", ns)
    text_elements = text_group.findall(".//svg:text", ns)

    stroke_orders: list[str] = []
    for i in range(0, len(path_elements)):
        stroke_order = f"""{xml_version_declaration}
{doctype_declaration}
{svg_tag}
{stroke_paths_tag}
{previous_element_string(path_elements[:i])}\t{element_tostring(path_elements[i])}
</g>
{stroke_numbers_tag}
{previous_element_string(text_elements[:i])}\t{element_tostring(text_elements[i])}
</g>
</svg>
"""
        stroke_orders.append(stroke_order)

    return stroke_orders


def get_kvg_index() -> Union[KanjiIndex, None]:
    req = Request(url="https://raw.githubusercontent.com/KanjiVG/kanjivg/refs/heads/master/kvg-index.json")
    jsonDecoder = JSONDecoder()
    
    try:
        response = urlopen(req)
        return cast(KanjiIndex, jsonDecoder.decode(response.read().decode("utf-8")))
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
        return response.read().decode("utf-8")
    except HTTPError as e:
        raise Exception(f"The server couldn\'t fulfill the SVG request. Error code: {e.code}")
    except URLError as e:
        raise Exception(f"We failed to reach a SVG server. Reason: {e.reason}")

    raise Exception("Unknown error on SVG")

app = FastAPI(docs_url="/docs")

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

        stroke_orders = [b64encode(stroke_order.encode(encoding="utf-8", errors="strict")) for stroke_order in svg_to_progressive_strings(kvg_file, kvg.replace(".svg", ""))]

        kanji: Kanji = {"kanji": kanji, "stroke_orders": stroke_orders}
        return kanji
    except HTTPException as e:
        raise e
    except UnicodeError as e:
        raise HTTPException(status_code=500, detail=f"Fail to encode KVG file. Reason: {e.reason}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fail somewhere. Reason: {e}")
