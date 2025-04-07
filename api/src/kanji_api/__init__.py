import uvicorn

def main():
    uvicorn.run("api:app", host="0.0.0.0", port=5050, reload=True)