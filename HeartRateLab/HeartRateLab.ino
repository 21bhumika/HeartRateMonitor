#include <SparkFun_Bio_Sensor_Hub_Library.h>
#include <Wire.h>

#define DEF_ADDR 0x55

// ======================================================
// ARDUINO ROLE
// ------------------------------------------------------
// - Read the sensor
// - Filter heart rate (5-sample moving average)
// - Calculate the resting HR baseline (30 s average)
// - Send DATA packets to Processing
// - Sound the buzzer when Processing sends "STRESS"
//
// Fitness zones, max HR, beat interval and stress
// detection are all done in Processing.
//
// Packet format:
// DATA,filteredHR,spo2,confidence,restingHR
// (restingHR is 0.0 until the baseline is complete)
// ======================================================


// ======================================================
// SENSOR PINS
// ======================================================

const int resPin = 4;
const int mfioPin = 5;

// Buzzer
const int buzzerPin = 12;


// ======================================================
// SENSOR OBJECT
// ======================================================

SparkFun_Bio_Sensor_Hub bioHub(resPin, mfioPin);
bioData body;


// ======================================================
// MOVING AVERAGE FILTER
// ======================================================

const int FILTER_SIZE = 5;

float hrBuffer[FILTER_SIZE];

int hrIndex = 0;
int hrCount = 0;


// ======================================================
// RESTING HEART RATE BASELINE
// ======================================================

const unsigned long BASELINE_DURATION = 30000; // 30 seconds

bool baselineStarted = false;
bool baselineComplete = false;

unsigned long baselineStartTime = 0;

float baselineSum = 0.0;
int baselineSamples = 0;

float restingHR = 0.0;


// ======================================================
// HEART RATE MOVING AVERAGE
// ======================================================

float filterHeartRate(float newHR) {

  // Store new HR
  hrBuffer[hrIndex] = newHR;

  // Move to next position in circular buffer
  hrIndex = (hrIndex + 1) % FILTER_SIZE;

  // During startup the buffer may contain
  // fewer than 5 samples
  if (hrCount < FILTER_SIZE) {
    hrCount++;
  }

  // Calculate average
  float sum = 0.0;

  for (int i = 0; i < hrCount; i++) {
    sum += hrBuffer[i];
  }

  return sum / hrCount;
}


// ======================================================
// BUZZER
// ======================================================

void stressBeep() {

  // First beep
  digitalWrite(buzzerPin, HIGH);
  delay(200);

  digitalWrite(buzzerPin, LOW);
  delay(200);

  // Second beep
  digitalWrite(buzzerPin, HIGH);
  delay(200);

  digitalWrite(buzzerPin, LOW);
}


// ======================================================
// COMMANDS FROM PROCESSING
// ======================================================

void handleCommands() {

  if (Serial.available() > 0) {

    int command = Serial.read();

    if (command == 1) {
      stressBeep();
      Serial.println("ACK:STRESS");
    }
  }
}


// ======================================================
// SETUP
// ======================================================

void setup() {

  // Buzzer
  pinMode(buzzerPin, OUTPUT);
  digitalWrite(buzzerPin, LOW);

  // Serial (must match Processing: 115200)
  Serial.begin(115200);

  // I2C
  Wire.begin();

  // Start sensor
  int result = bioHub.begin();

  if (!result) {
    Serial.println("Sensor started!");
  } else {
    Serial.println("Could not communicate with sensor!");
  }

  // Configure sensor
  Serial.println("Configuring sensor...");

  int error = bioHub.configBpm(MODE_TWO);

  if (!error) {
    Serial.println("Sensor configured.");
  } else {
    Serial.print("Configuration error: ");
    Serial.println(error);
  }

  // Give sensor time to stabilize
  delay(4000);
}


// ======================================================
// MAIN LOOP
// ======================================================

void loop() {

  handleCommands();


  // ----------------------------------------------------
  // READ SENSOR
  // ----------------------------------------------------

  body = bioHub.readBpm();


  // ----------------------------------------------------
  // CHECK IF MEASUREMENT IS VALID
  // ----------------------------------------------------

  bool validMeasurement =
      (body.status == 3) &&
      (body.extStatus == 0) &&
      (body.confidence >= 0) &&
      (body.heartRate > 0);


  if (validMeasurement) {

    // --------------------------------------------------
    // FILTER HEART RATE
    // --------------------------------------------------

    float filteredHR = filterHeartRate(body.heartRate);


    // --------------------------------------------------
    // START RESTING BASELINE
    // --------------------------------------------------

    if (!baselineStarted) {

      baselineStarted = true;

      baselineStartTime = millis();

      baselineSum = 0.0;
      baselineSamples = 0;

      Serial.println("RESTING BASELINE STARTED");
    }


    // --------------------------------------------------
    // BASELINE PHASE
    // --------------------------------------------------

    if (!baselineComplete) {

      baselineSum += filteredHR;
      baselineSamples++;

      unsigned long elapsedTime = millis() - baselineStartTime;

      Serial.print("Baseline time: ");
      Serial.print(elapsedTime / 1000.0, 1);
      Serial.println(" / 30.0 s");

      if (elapsedTime >= BASELINE_DURATION) {

        restingHR = baselineSum / baselineSamples;

        baselineComplete = true;

        Serial.print("BASELINE COMPLETE. Resting HR: ");
        Serial.print(restingHR, 1);
        Serial.print(" BPM (");
        Serial.print(baselineSamples);
        Serial.println(" samples)");
      }
    }

    // Seconds elapsed in the baseline (stays at 30.0 once complete)
    float baselineElapsed = 0.0;

    if (baselineComplete) {
      baselineElapsed = BASELINE_DURATION / 1000.0;
    } else if (baselineStarted) {
      baselineElapsed = (millis() - baselineStartTime) / 1000.0;
    }

    // --------------------------------------------------
    // SEND DATA PACKET
    // DATA,filteredHR,spo2,confidence,restingHR
    // --------------------------------------------------

    Serial.print("DATA,");

    Serial.print(filteredHR, 1);
    Serial.print(",");

    Serial.print(body.oxygen);
    Serial.print(",");

    Serial.print(body.confidence);
    Serial.print(",");

    Serial.print(restingHR, 1);
    Serial.print(",");
    Serial.println(baselineElapsed, 1);
  }

  else {

    Serial.print("INVALID MEASUREMENT  status=");
    Serial.print(body.status);
    Serial.print("  extStatus=");
    Serial.print(body.extStatus);
    Serial.print("  confidence=");
    Serial.println(body.confidence);
  }


  delay(250);
}