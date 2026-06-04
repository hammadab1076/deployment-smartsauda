/* =============================================================================
   Smart Sauda — ARDUINO UNO sketch (NFC reader side)
   -----------------------------------------------------------------------------
   Role: read NFC card UID from the PN532, send it to the ESP8266 over hardware
         serial (pin1 TX → ESP8266 RX).

   WIRING (soldered board):
     PN532  → Arduino I2C   : SDA→A4, SCL→A5, VCC→5V, GND→GND
     ESP8266 link           : Arduino pin1 (TX) → ESP8266 RX
                              Arduino pin0 (RX) ← ESP8266 TX

   IMPORTANT: Set Serial Monitor baud to 9600 (must match ESP8266).
   NOTE: Disconnect USB while uploading if you get upload errors (pin0/1
         are shared with USB). Reconnect after upload.
============================================================================= */

#include <Wire.h>
#include <Adafruit_PN532.h>

#define SDA_PIN A4
#define SCL_PIN A5
Adafruit_PN532 nfc(SDA_PIN, SCL_PIN);

String lastUid = "";

void setup() {
  Serial.begin(9600);  // 9600 must match ESP8266 arduinoSerial baud

  Serial.println(F("=== Arduino NFC Reader ==="));

  nfc.begin();
  uint32_t ver = nfc.getFirmwareVersion();
  if (!ver) {
    Serial.println(F("FAIL: PN532 not found. Check SDA=A4 SCL=A5."));
    while (1);
  }
  Serial.print(F("PN532 fw "));
  Serial.print((ver >> 16) & 0xFF);
  Serial.print('.');
  Serial.println((ver >> 8) & 0xFF);
  nfc.SAMConfig();

  Serial.println(F("Ready. Tap a card."));
}

void loop() {
  uint8_t uid[7] = {0};
  uint8_t uidLen = 0;

  if (nfc.readPassiveTargetID(PN532_MIFARE_ISO14443A, uid, &uidLen, 150)) {
    String newUid = "";
    for (uint8_t i = 0; i < uidLen; i++) {
      if (uid[i] < 0x10) newUid += '0';
      newUid += String(uid[i], HEX);
    }
    if (newUid != lastUid) {
      lastUid = newUid;
      // Send in UID: format — ESP8266 processes lines starting with "UID:"
      Serial.print(F("UID:"));
      Serial.println(newUid);
    }
  } else {
    if (lastUid.length()) {
      lastUid = "";
    }
  }

  delay(50);
}
