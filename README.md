# Produce Classifier

Offline fruit/vegetable classifier for an Android tablet with integrated scale. A TFLite model runs fully on-device, and an ESP32 pushes weight readings over WebSocket — no PC backend required.

## Architecture

```
ESP32 (HX711 + load cell)
       │
       │  WebSocket (port 8765, path /esp)
       ▼
  ┌──────────────────────────────────────────────┐
  │               Tablet App (Flutter)            │
  │                                               │
  │  EspWebSocketServer ──► WeightStore           │
  │         │                                   │
  │    HTTP /receipt/<token>   (same server)     │
  │                                               │
  │  Camera (USB UVC / built-in)                 │
  │      → TFLite inference (224×224, int8)       │
  │      → Confirm / reject ranked predictions    │
  │      → Stable weight → price → cart → receipt │
  └──────────────────────────────────────────────┘
```

All cart, pricing, and receipt logic runs locally in the app. See `docs/ESP32.md` for the ESP32 wire protocol.

## Project layout

```
lib/
  config/app_config.dart              # ports, paths, model settings, tuning constants
  services/
    esp_websocket_server.dart         # embedded WebSocket + HTTP server
    inference_service.dart            # TFLite model loading and prediction
    weight_store.dart                 # ChangeNotifier holding latest ESP weight
    weight_service.dart               # waits for stable non-zero weight
    price_service.dart                # hardcoded per-kg price lookup
    cart_service.dart                 # in-memory cart (add, fetch, clear)
    receipt_service.dart              # UUID-keyed receipt store + QR URL generation
    scale_service.dart                # abstract interface + MockScaleService
    uvc_camera_session.dart           # USB UVC camera attach/permission/controller lifecycle
  screens/
    camera_screen.dart                # live preview, USB fallback, capture button
    result_screen.dart                # confirm / reject top prediction
    confirmed_screen.dart             # weight + price display, add to cart
    cart_screen.dart                  # running cart list, generate receipt QR
  widgets/
    camera_overlay.dart               # centered square crop guide
assets/
  model.tflite                        # int8 quantized TFLite model
  labels.txt                          # class labels (one per model output)
docs/
  ESP32.md                            # ESP32 ↔ tablet WebSocket protocol
  STEP2_LOCAL_SERVICES.md             # original plan for on-device cart/prices/receipts
backend/                              # archived — no longer used
test/
  services_test.dart                  # unit tests for price, cart, receipt services
  widget_test.dart                    # smoke test (app builds)
```

## Setup

1. `flutter pub get`
2. Build and install on an Android tablet (API 24+, landscape).
3. Ensure the tablet and ESP32 are on the **same WiFi** network.
4. Note the tablet's IP address. The ESP32 connects to `ws://<tablet-ip>:8765/esp`.

Port and path are configured in `lib/config/app_config.dart`.

## Test without ESP32 hardware

Use any WebSocket client on the same network, e.g. [websocat](https://github.com/vi/websocat):

```bash
websocat ws://<tablet-ip>:8765/esp
```

Then send:

```json
{"weight_kg": 0.5}
```

Or check the server is listening: `GET http://<tablet-ip>:8765/`

## User flow

1. **Camera** — live preview from USB (or built-in) camera. Tap capture to classify.
2. **Result** — top prediction shown with confidence. Confirm or reject to see the next suggestion.
3. **Confirmed** — waits for a stable non-zero weight from the scale, fetches the per-kg price, shows weight × price. "Add to cart" stores the line item.
4. **Cart** — list of added items with a subtotal. "Generate receipt" creates a QR code that phones on the same WiFi can scan to view the receipt JSON.

## Running tests

```bash
flutter test
```
