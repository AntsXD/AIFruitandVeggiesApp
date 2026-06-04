# Fruit / vegetable classifier (tablet + backend)

Offline TFLite classification on an Android tablet mounted on a scale, with weight from an ESP32 → FastAPI → Flutter poll flow.

## Project layout

- `lib/` — Flutter app (camera, inference, cart, receipt QR)
- `backend/` — FastAPI stubs (in-memory weight, cart, receipts)
- `assets/` — `model.tflite`, `labels.txt` (203 classes, simplified names)
- `docs/ESP32.md` — firmware spec (not built here)

## Setup

### Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Flutter

1. Set your LAN IP in `lib/config/app_config.dart` → `backendBaseUrl`.
2. `flutter pub get`
3. Connect an Android device (API 24+, landscape).
4. `flutter run`

### Android notes

- `minSdk` 24, landscape locked in manifest + `SystemChrome`
- Camera + Internet permissions
- `tflite_flutter` ABI filters in `android/app/build.gradle.kts`
- **USB UVC camera:** plug camera into tablet (OTG). App uses `uvccamera` first; allow **Camera** + **USB** when prompted. Falls back to built-in if no USB cam.
- Tablet needs **USB OTG** host support.

### Test weight without ESP32

```bash
curl -X POST http://localhost:8000/weight/update -H "Content-Type: application/json" -d "{\"weight_kg\": 0.5}"
```

## Flow

1. **Camera** — capture → center crop → 224×224 → TFLite → ranked labels  
2. **Result** — confirm / reject down the list  
3. **Confirmed** — poll weight, show price, add to cart  
4. **Cart** — line items, generate receipt QR (`GET /receipt/{token}`)

`MockScaleService` logs confirmed labels until real scale transport exists.
