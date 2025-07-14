import uvicorn

if __name__ == "__main__":
    uvicorn.run("kanji_api:app", port=5050, log_level="info", reload=True)
