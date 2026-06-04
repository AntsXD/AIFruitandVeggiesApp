# ESP32 → tablet WebSocket (step 1)

The tablet app runs a **small WebSocket server**. The ESP32 connects over WiFi and pushes weight JSON. No separate Python backend is required for weight.

## Network

- Tablet and ESP32 on the **same WiFi**.
- Find the tablet’s IP (Android: Settings → WiFi → network details).
- ESP connects to:

  `ws://<tablet-ip>:8765/esp`

  Example: `ws://192.168.1.42:8765/esp`

## Messages (ESP → tablet)

Send **text** frames with JSON:

```json
{ "weight_kg": 0.425 }
```

Optional heartbeat (same shape is fine):

```json
{ "type": "heartbeat", "weight_kg": 0.425 }
```

Only `weight_kg` is required.

## Responses (tablet → ESP)

Success:

```json
{ "ok": true, "weight_kg": 0.425 }
```

On connect, welcome:

```json
{ "type": "welcome", "ok": true }
```

Error:

```json
{ "ok": false, "error": "..." }
```

## Firmware behaviour

1. HX711 + stable-reading logic on the ESP (unchanged from before).
2. On stable reading (or every N seconds), send one JSON message over the open WebSocket.
3. Reconnect with backoff if the socket drops.
4. Tablet app stores the **latest** `weight_kg` in memory; `ConfirmedScreen` waits for a stable non-zero value.

## Arduino / ESP-IDF sketch outline

Use `WebSocketsClient` (links2004) or ESP-IDF `esp_websocket_client`:

- `begin("192.168.1.42", 8765, "/esp")` — use your tablet IP.
- `sendTXT("{\"weight_kg\":0.425}")` when weight updates.

## HTTP check (optional)

`GET http://<tablet-ip>:8765/` returns a short plain-text hint that the server is up.

## Hardware

- ESP32 + HX711 + load cell
- USB power for ESP; tablet on same LAN

Firmware project stays separate from this repo.
