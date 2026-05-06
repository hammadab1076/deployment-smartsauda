#include <SPI.h>
#include <Adafruit_PN532.h>

// SPI pins
#define PN532_SS   10

Adafruit_PN532 nfc(PN532_SS);

void setup(void) {
  Serial.begin(9600);
  Serial.println("Initializing PN532...");

  nfc.begin();

  uint32_t versiondata = nfc.getFirmwareVersion();
  if (!versiondata) {
    Serial.println("Didn't find PN532 module!");
    while (1);
  }

  Serial.print("Found chip PN5"); 
  Serial.println((versiondata >> 24) & 0xFF, HEX);

  nfc.SAMConfig(); // configure board to read RFID

  Serial.println("Waiting for an NFC card...");
}

void loop(void) {
  uint8_t success;
  uint8_t uid[7];      // buffer to store UID
  uint8_t uidLength;   // length of UID

  // Wait for NFC tag
  success = nfc.readPassiveTargetID(
    PN532_MIFARE_ISO14443A, 
    uid, 
    &uidLength
  );

  if (success) {
    Serial.println("NFC Tag Detected!");

    Serial.print("UID: ");
    for (uint8_t i = 0; i < uidLength; i++) {
      Serial.print(uid[i], HEX);
      Serial.print(" ");
    }
    Serial.println();

    delay(1000); // avoid multiple reads
  }
}