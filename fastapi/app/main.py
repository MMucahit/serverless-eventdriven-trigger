## Others
import uuid

## FastAPI
from fastapi import FastAPI

## Pydantic
from pydantic import BaseModel

## Redis
import redis

app = FastAPI()

r = redis.Redis(host="192.168.49.2", port=30080, decode_responses=True)

class EmailRequest(BaseModel):
    email: str
    message: str


@app.post("/send_later")
async def send_later(body: EmailRequest):
    job_id = str(uuid.uuid4())
    
    r.hset(f"job:{job_id}", mapping={
        "email": body.email,
        "message": body.message
    })
    
    r.set(f"delay:{job_id}", "", ex=10)
    
    return {"status": "scheduled", "job_id": job_id}
