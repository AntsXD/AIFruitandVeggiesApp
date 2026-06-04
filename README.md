# Fruit / vegetable classifier (tablet)

Offline TFLite on an Android tablet. Weight comes from an **ESP32 over WebSocket** into the app (no PC backend required for weight).

## Architecture (step 1 — implemented)

```
ESP32  --WebSocket-->  tablet app (port 8765, path /esp)
                              |
                         WeightStore  -->  ConfirmedScreen
```

See `docs/ESP32.md` for the wire protocol.

## Project layout

- `lib/` — Flutter app + embedded WebSocket server
- `backend/` — **legacy** FastAPI stubs (cart/receipt still call this until step 2)
- `docs/STEP2_LOCAL_SERVICES.md` — plan for on-device cart/receipt
- `assets/` — model + labels

## Setup

1. `flutter pub get`
2. Install on tablet (API 24+, landscape).
3. Tablet and ESP on the **same WiFi**.
4. Note tablet IP → ESP connects to `ws://<tablet-ip>:8765/esp`

Port/path: `lib/config/app_config.dart` → `espWebSocketPort`, `espWebSocketPath`.

### Cart / receipt (step 2 — not done)

Still uses `backendBaseUrl` in `app_config.dart` if you run the old FastAPI server. See `docs/STEP2_LOCAL_SERVICES.md`.

```bash
cd backend && pip install -r requirements.txt && uvicorn main:app --host 0.0.0.0 --port 8000
```

## Test weight without ESP32

Use any WebSocket client on the same network, e.g. [websocat](https://github.com/vi/websocat):

```bash
websocat ws://<tablet-ip>:8765/esp
```

Then type:

```json
{"weight_kg": 0.5}
```

Or `GET http://<tablet-ip>:8765/` to confirm the server is listening.

## Flow

1. **Camera** — capture → TFLite → ranked labels  
2. **Result** — confirm / reject  
3. **Confirmed** — stable weight from `WeightStore`, price from backend (step 2: local)  
4. **Cart** — backend HTTP today (step 2: local + QR on tablet)
