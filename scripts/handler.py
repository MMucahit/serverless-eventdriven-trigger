import os
import redis

r = redis.Redis(host="192.168.49.2", port=30080, decode_responses=True)

job_id_raw = os.getenv("JOB_ID")


if not job_id_raw:
    print("❌ JOB_ID environment variable not set.")
    exit(1)

job_id = job_id_raw.replace("delay:", "") if job_id_raw else None
job_key = f"job:{job_id}"

print(f"JOB_ID: {job_id}")

job_data = r.hgetall(job_key)

if not job_data:
    print(f"❌ Redis'te '{job_key}' için veri bulunamadı.")
    exit(1)

print("\n📬 GÖNDERİLEN EMAIL")
print(f"Kime: {job_data.get('email')}")
print(f"Mesaj: {job_data.get('message')}")
print("✅ Email terminale yazıldı.")

r.delete(job_key)
