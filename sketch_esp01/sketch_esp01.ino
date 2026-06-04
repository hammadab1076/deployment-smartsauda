/* =============================================================================
   Smart Sauda — ESP8266 (NodeMCU) sketch (WiFi sender side)
   -----------------------------------------------------------------------------
   Role: receive an NFC UID from the Arduino over SoftwareSerial (D5/D6),
         then POST it to the Railway backend over HTTPS.
         Sends the result back to the Arduino via SoftwareSerial.

   WIRING:
     Arduino pin3 (TX) → ESP8266 D5 (RX via SoftwareSerial)
     Arduino pin2 (RX) ← ESP8266 D6 (TX via SoftwareSerial)

   DEBUG:
     USB Serial Monitor at 115200 — clean debug, no Arduino interference.

   FLASHING:
     Plug USB into ESP8266's own micro-USB port.
     Board: NodeMCU 1.0 (ESP-12E Module).
============================================================================= */

#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include <SoftwareSerial.h>

const char* WIFI_SSID    = "ESP8266WIFI";
const char* WIFI_PASS    = "78612345";
const char* BACKEND_HOST = "deployment-smartsauda-production.up.railway.app";
const int   BACKEND_PORT = 443;
const char* SCANNER_ID   = "SCANNER_01";

#define LED_PIN LED_BUILTIN   // onboard LED (active LOW)

// RX=D5, TX=D6 — matches reference style
SoftwareSerial arduinoSerial(D5, D6);

String receivedData = "";

// =============================================================================
void setup() {
  Serial.begin(115200);       // Debug monitor — clean, no Arduino interference
  arduinoSerial.begin(9600);  // Arduino communication

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, HIGH);  // LED off (active LOW)

  Serial.println();
  Serial.println("=== Smart Sauda ESP8266 WiFi Sender ===");

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("WiFi connecting");

  unsigned long t = millis();
  while (WiFi.status() != WL_CONNECTED) {
    if (millis() - t > 20000) {
      Serial.println("\nWiFi FAILED. Check hotspot/credentials.");
      break;
    }
    delay(400);
    Serial.print('.');
    blink(1, 80);
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("\nWiFi OK — IP: ");
    Serial.println(WiFi.localIP());
    blink(3, 120);  // 3 quick blinks = WiFi ready
  }

  Serial.println("Waiting for UID from Arduino...");
}

// =============================================================================
void loop() {
  while (arduinoSerial.available()) {
    char c = arduinoSerial.read();

    if (c == '\n') {
      receivedData.trim();

      if (receivedData.length() > 0) {
        Serial.print("Received: ");
        Serial.println(receivedData);

        if (receivedData.startsWith("UID:")) {
          String uid = receivedData.substring(4);
          uid.trim();
          if (uid.length() > 0) {
            postScan(uid);
          }
        }
      }

      receivedData = "";
    }
    else {
      receivedData += c;
      if (receivedData.length() > 40) receivedData = "";  // guard against junk
    }
  }
}

// =============================================================================
void postScan(String uid) {
  // Ensure WiFi
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi lost — reconnecting...");
    WiFi.reconnect();
    unsigned long t = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - t < 10000) { delay(300); }
    if (WiFi.status() != WL_CONNECTED) {
      reply("RESULT:WIFI_FAIL");
      return;
    }
  }

  String body = "{\"uid\":\"" + uid + "\",\"scannerId\":\"" + SCANNER_ID + "\"}";

  WiFiClientSecure client;
  client.setInsecure();       // skip cert check — fine for FYP demo
  client.setTimeout(8000);

  if (!client.connect(BACKEND_HOST, BACKEND_PORT)) {
    Serial.println("Server connect FAILED");
    reply("RESULT:NO_SERVER");
    blink(1, 600);
    return;
  }

  // Send HTTP POST
  client.print("POST /api/scan HTTP/1.1\r\nHost: ");
  client.print(BACKEND_HOST);
  client.print("\r\nContent-Type: application/json\r\nContent-Length: ");
  client.print(body.length());
  client.print("\r\nConnection: close\r\n\r\n");
  client.print(body);

  // Read response
  unsigned long t = millis();
  while (client.available() == 0 && millis() - t < 6000) yield();
  String resp = "";
  while (client.available()) resp += (char)client.read();
  client.stop();

  // Interpret + report
  if (resp.indexOf("\"success\":true") >= 0) {
    Serial.println(">>> SCAN SUCCESS <<<");
    reply("RESULT:SUCCESS");
    blink(2, 120);
  } else if (resp.indexOf("No active cart") >= 0) {
    Serial.println("No active cart for SCANNER_01");
    reply("RESULT:NO_CART");
    blink(4, 120);
  } else if (resp.indexOf("No product") >= 0) {
    Serial.println("Unknown NFC tag");
    reply("RESULT:NO_PRODUCT");
    blink(4, 120);
  } else {
    Serial.println("Unexpected server response");
    reply("RESULT:UNKNOWN");
    blink(1, 600);
  }
}

// =============================================================================
// Send result back to Arduino via SoftwareSerial
void reply(const char* msg) {
  arduinoSerial.println(msg);
  Serial.println(msg);  // also echo to debug monitor
}

// Blink onboard LED (active LOW)
void blink(int times, int ms) {
  for (int i = 0; i < times; i++) {
    digitalWrite(LED_PIN, LOW);
    delay(ms);
    digitalWrite(LED_PIN, HIGH);
    delay(ms);
  }
}