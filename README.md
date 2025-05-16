# Argo Redis Email Demo

Bu proje, tamamen **open-source** ve **serverless** olarak, FastAPI üzerinden alınan verilerin Redis aracılığıyla zamanlanmış şekilde işlenmesini ve Argo Workflows tarafından tetiklenmesini amaçlar. Demo ortamında, email atma yerine terminale yazdırma işlemi yapılmaktadır.

---

## 🚀 Kullanılan Teknolojiler

| Teknoloji      | Görevi                                                                    |
| -------------- | ------------------------------------------------------------------------- |
| FastAPI        | HTTP istekleri alır ve verileri Redis'e yazar                             |
| Redis          | Geçici verileri saklar ve `key expired` event'i yayar                     |
| Argo Workflows | Serverless çalışan iş akışlarını tanımlar ve yürütür                      |
| Argo Events    | Redis üzerindeki `key expiration` event'lerini dinleyip Workflow tetikler |
| Docker         | Worker scriptleri kapsayan container imajlarını üretir                    |

---

## 🧾 Proje Yapısı

```
project-root/
├── README.md
├── argo/
│   ├── workflow.yaml              # Argo Workflow tanımı (email gönderim işlemi)
│   └── event-source.yaml          # Redis key expiration'ı dinleyen Event Source
├── email_worker/
│   ├── handler.py                 # Redis'ten veriyi okuyup terminale yazan script
│   └── Dockerfile                # Email worker için Docker imajı
├── redis/
│   └── redis.conf                # (Opsiyonel) Redis config dosyası
└── fastapi-server/
    └── main.py                   # İstek alıp Redis'e veri yazan FastAPI sunucusu
```

---

### 🔄 **Argo Event ve Argo Sensor Arasındaki Farklar**

**Argo Event** ve **Argo Sensor**, Argo Workflows ekosisteminde dış olaylara tepki veren ve iş akışlarını tetikleyen iki önemli bileşendir. Ancak bunlar farklı görevleri yerine getirir.

| Özellik                | **Argo Event**                                                     | **Argo Sensor**                                              |
| ---------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------ |
| **Görev**              | Olay kaynağını dinler ve olayları belirler.                        | Olaylara tepki verir ve bir workflow'u tetikler.             |
| **Kullanımı**          | Dış sistemlerden gelen olayları tanımlar (Redis, HTTP, Kafka vs.). | Olayları alır ve bu olaylarla ilgili workflow'ları tetikler. |
| **Olayları Dinleme**   | Dış bir kaynağın olaylarını dinler (event source).                 | Olayları dinler ve workflow tetikler.                        |
| **İş Akışı Tetikleme** | Tek başına iş akışını tetiklemez.                                  | Olay gerçekleştiğinde iş akışını tetikler.                   |
| **Örnek**              | Redis key expiration event, HTTP webhook event                     | Redis key expired event alındığında workflow başlatır.       |

### **Argo Event**:

- **Olay Kaynağını Dinler ve Yayınlar**: Argo Event, dış bir kaynaktan (Redis, Kafka, HTTP vs.) gelen olayları dinler. Bu olayları "yayınlar" veya **event source** aracılığıyla Argo'ya bildirir.

  **Örnek**: Redis'te bir anahtarın süresi dolarsa, **Redis EventSource** bu olayı dinler ve Argo'ya bildirir.

### **Argo Sensor**:

- **Argo Event'in Yayınladığı Olayı Dinler ve Workflow Tetikler**: Argo Sensor, Argo Event tarafından yayınlanan olayı dinler. Bu olayı aldıktan sonra, belirli bir iş akışını (workflow) tetikler.

  **Örnek**: Redis'teki bir anahtarın süresi dolduğunda Argo Event, Redis EventSource aracılığıyla bu olayı Argo'ya yayınlar. Argo Sensor bu olayı dinler ve bu olay gerçekleştiğinde bir Argo Workflow'u başlatır.

### **Özetle**:

- **Argo Event**: Olay kaynağını dinler ve bu olayları Argo'ya bildirir (yayınlar).
- **Argo Sensor**: Argo Event tarafından yayınlanan olayı dinler ve bu olaya bağlı olarak bir workflow'u tetikler.

---

## 🔄 Akış Özeti

1. FastAPI `/send-later` endpoint'ine istek atar
2. Redis'e email ve mesaj yazılır, delay key'i 60 sn'de expire olacak şekilde ayarlanır
3. Redis delay key'i expire olduğunda event yayar
4. Argo Events bu event’i alır ve `job_id` parametresi ile Workflow tetikler
5. Argo Workflow içinde çalışan `email-worker` container, Redis'ten ilgili `job:<id>` key'ini okur ve terminale yazdırır

---
