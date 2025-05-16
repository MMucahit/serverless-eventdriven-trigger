FROM python:3.10-slim

WORKDIR /app
COPY handler.py /app/handler.py

RUN pip install redis

CMD ["python", "handler.py"]
