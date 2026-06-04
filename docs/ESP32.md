# ESP32 scale firmware (not implemented)

The tablet app does **not** read weight directly. An ESP32 on the load cell pushes readings to the local FastAPI backend; Flutter polls `GET /weight/current`.

## Hardware

- ESP32 dev board
- HX711 + load cell (same wiring as your scale build)

## WiFi

- Connect to the same LAN as the backend and tablet.
- Reconnect automatically on disconnect.
- Send a lightweight heartbeat `POST /weight/update` with the last known stable weight every **10 s** (configurable) so the backend knows the node is alive.

## Stable reading logic (firmware)

1. Read raw HX711 samples; tare on boot (store offset in NVS optional).
2. When the reading has been within a small band (e.g. ±2 g) for ~500 ms, treat it as **stable**.
3. Only POST when the stable value changes by more than a debounce threshold, or on heartbeat.

## API contract

**Endpoint:** `POST http://<backend-ip>:8000/weight/update`

**Body (JSON):**

```json
{ "weight_kg": 0.425 }
```

**Response:** `{ "ok": true, "weight_kg": 0.425 }`

The backend keeps a single in-memory `weight_kg`; the latest POST wins.

## Flutter / tablet

No serial/USB from the app. After the user confirms a label, `ConfirmedScreen` polls `GET /weight/current` until a stable non-zero weight is seen.

## Do not implement in this repo yet

Firmware lives in a separate Arduino/PlatformIO project. This document is the handoff spec for that work.
