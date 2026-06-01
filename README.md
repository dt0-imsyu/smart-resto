# SmartResto

## Русский

**SmartResto** — MVP приложения для ресторана с AI-официантом и AI-рекомендациями перед оформлением заказа.

### Возможности

* Просмотр меню ресторана.
* Управление корзиной.
* AI-официант с рекомендациями на основе предпочтений, диеты и аллергий.
* AI-апселл для предложения дополнительных блюд и напитков.
* Резервный режим: если Gemini недоступен или возвращает небезопасные рекомендации, система автоматически использует детерминированные рекомендации на основе меню.

### Технологии

**Backend**

* Python
* FastAPI
* SQLAlchemy
* SQLite

**AI**

* Gemini API (`google-genai`)

**Frontend**

* Flutter
* Riverpod
* Dio

### Запуск Backend

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements.txt
.\.venv\Scripts\python -m backend.app.seed
.\.venv\Scripts\python -m uvicorn backend.app.main:app --reload
```

API:

```text
http://127.0.0.1:8000/api/v1
```

### Настройка Gemini

```powershell
$env:GEMINI_API_KEY="your-key"
$env:GEMINI_MODEL="gemini-2.5-flash-lite"
```

### Запуск Frontend

```powershell
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

### Сборка APK

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

---

## English

**SmartResto** is an MVP restaurant ordering application featuring an AI waiter and AI-powered upsell recommendations.

### Features

* Restaurant menu browsing.
* Cart management.
* AI waiter for menu-based recommendations.
* AI upsell suggestions before checkout.
* Fallback mode: if Gemini is unavailable or returns unsafe recommendations, the system automatically switches to deterministic menu-based recommendations.

### Tech Stack

**Backend**

* Python
* FastAPI
* SQLAlchemy
* SQLite

**AI**

* Gemini API (`google-genai`)

**Frontend**

* Flutter
* Riverpod
* Dio

### Backend Setup

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements.txt
.\.venv\Scripts\python -m backend.app.seed
.\.venv\Scripts\python -m uvicorn backend.app.main:app --reload
```

API:

```text
http://127.0.0.1:8000/api/v1
```

### Gemini Configuration

```powershell
$env:GEMINI_API_KEY="your-key"
$env:GEMINI_MODEL="gemini-2.5-flash-lite"
```

### Frontend Setup

```powershell
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

### Build APK

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```
