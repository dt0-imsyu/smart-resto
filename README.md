# SmartResto

SmartResto is a full-stack MVP for a modern restaurant ordering experience with an AI waiter and AI cart upsell.

The app has three core flows:

- Browse a live restaurant menu and manage a cart.
- Ask an AI waiter for menu-grounded recommendations based on taste, diet, calories, and allergies.
- Get AI upsell suggestions in the cart before checkout.

## Stack

- Backend: Python, FastAPI, SQLAlchemy, SQLite.
- AI: Gemini API through the official `google-genai` package.
- Mobile frontend: Flutter, Riverpod, Dio.
- Build targets: Android APK and Flutter Web for quick local testing.

## Project Structure

```text
backend/
  app/
    ai_service.py      # Gemini RAG prompts, JSON upsell parsing, safe fallback
    database.py        # SQLite engine/session
    main.py            # FastAPI routes
    models.py          # SQLAlchemy models
    schemas.py         # Pydantic request/response models
    seed.py            # Demo restaurant data
frontend/
  lib/
    core/network/      # Dio API client
    features/
      ai_chat/         # AI waiter chat
      cart/            # Cart state and upsell UI
      menu/            # Menu list and category browsing
```

## Backend Setup

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements.txt
.\.venv\Scripts\python -m backend.app.seed
.\.venv\Scripts\python -m uvicorn backend.app.main:app --reload
```

The API runs at:

```text
http://127.0.0.1:8000/api/v1
```

Useful endpoints:

- `GET /api/v1/menu`
- `GET /api/v1/menu?category=Пицца`
- `POST /api/v1/orders`
- `POST /api/v1/ai/chat`
- `POST /api/v1/ai/upsell`

## Gemini Configuration

Set the API key through an environment variable. Do not commit it.

```powershell
$env:GEMINI_API_KEY = "your-key"
$env:GEMINI_MODEL = "gemini-2.5-flash-lite"
```

`GEMINI_MODEL` is optional. The backend defaults to `gemini-2.5-flash`.

If Gemini is unavailable, over quota, or returns unsafe allergy content, SmartResto falls back to deterministic menu-based recommendations.

## Frontend Setup

```powershell
cd frontend
flutter pub get
flutter analyze
flutter test
```

Run on Android emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Run on web:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Build APK

```powershell
cd frontend
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Output:

```text
frontend/build/app/outputs/flutter-apk/app-release.apk
```

## Validation Used

```powershell
.\.venv\Scripts\python -m backend.app.seed
.\.venv\Scripts\python -m compileall backend
cd frontend
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

## Notes

- The Android emulator should call the local backend through `10.0.2.2`.
- A physical Android device needs the backend host IP instead of `10.0.2.2`.
- The release APK is unsigned with a production keystore. It is suitable for MVP distribution/testing, not Play Store submission.
