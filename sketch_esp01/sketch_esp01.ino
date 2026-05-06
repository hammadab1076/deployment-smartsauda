#include <Wire.h>
#include <Adafruit_PN532.h>
#include <SoftwareSerial.h>

// ── NFC ──────────────────────────────────────────────────────────────────────
#define SDA_PIN A4
#define SCL_PIN A5
Adafruit_PN532 nfc(SDA_PIN, SCL_PIN);

// ── ESP-01 ───────────────────────────────────────────────────────────────────
SoftwareSerial espSerial(2, 3); // Arduino RX=2, TX=3 → ESP-01 TX, RX

// ── Config — UPDATE THESE ────────────────────────────────────────────────────
const char* WIFI_SSID     = "iPhone";          // your WiFi hotspot name
const char* WIFI_PASS     = "12345678";        // your WiFi hotspot password
const char* BACKEND_IP    = "172.20.193.157";     // ← run ipconfig on PC, use IPv4 under Wi-Fi adapter (iPhone hotspot = 172.20.10.x)
const int   BACKEND_PORT  = 3000;
const char* SCANNER_ID    = "SCANNER_01";
// ─────────────────────────────────────────────────────────────────────────────

String lastUid = "";

void setup() {
  Serial.begin(115200);
  espSerial.begin(115200);

  // NFC init
  nfc.begin();
  if (!nfc.getFirmwareVersion()) {
    Serial.println("ERROR: PN532 not found");
    while (1);
  }
  nfc.SAMConfig();
  Serial.println("NFC ready.");

  // ESP-01 init
  sendCmd("AT+RST",    2000);
  sendCmd("AT+CWMODE=1", 500);

  String joinCmd = String("AT+CWJAP=\"") + WIFI_SSID + "\",\"" + WIFI_PASS + "\"";
  sendCmd(joinCmd, 10000);

  Serial.println("WiFi connected. Ready to scan.");
}

void loop() {
  uint8_t uid[7] = {0};
  uint8_t uidLen  = 0;

  if (nfc.readPassiveTargetID(PN532_MIFARE_ISO14443A, uid, &uidLen, 150)) {
    // Build zero-padded hex UID
    String newUid = "";
    for (uint8_t i = 0; i < uidLen; i++) {
      if (uid[i] < 0x10) newUid += "0";
      newUid += String(uid[i], HEX);
    }

    // Only send once per new card presentation
    if (newUid != lastUid) {
      lastUid = newUid;
      Serial.print("Card scanned: ");
      Serial.println(lastUid);
      postScanToBackend(lastUid);
    }
  } else {
    // Card removed — reset so next placement triggers a new POST
    if (lastUid != "") {
      lastUid = "";
      Serial.println("Card removed.");
    }
  }
}

// ── HTTP POST /api/scan ───────────────────────────────────────────────────────
void postScanToBackend(String uid) {
  String body = "{\"uid\":\"" + uid + "\",\"scannerId\":\"" + SCANNER_ID + "\"}";
  int    bodyLen = body.length();

  String request =
    String("POST /api/scan HTTP/1.0\r\n") +
    "Host: " + BACKEND_IP + ":" + BACKEND_PORT + "\r\n" +
    "Content-Type: application/json\r\n" +
    "Content-Length: " + bodyLen + "\r\n" +
    "Connection: close\r\n\r\n" +
    body;

  // Open TCP connection
  String cipCmd = String("AT+CIPSTART=\"TCP\",\"") + BACKEND_IP + "\"," + BACKEND_PORT;
  sendCmd(cipCmd, 3000);

  // Send data
  espSerial.print("AT+CIPSEND=");
  espSerial.println(request.length());
  delay(500);
  espSerial.print(request);
  delay(1500);

  // Read response into Serial Monitor
  String resp = "";
  unsigned long t = millis();
  while (millis() - t < 2000) {
    while (espSerial.available()) {
      resp += (char)espSerial.read();
    }
  }
  Serial.println(resp);

  // Close connection
  sendCmd("AT+CIPCLOSE", 500);
}

// ── AT command helper ─────────────────────────────────────────────────────────
void sendCmd(String cmd, int waitMs) {
  espSerial.println(cmd);
  delay(waitMs);
  while (espSerial.available()) {
    Serial.write(espSerial.read());
  }
}
