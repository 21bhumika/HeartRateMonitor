#include <SparkFun_Bio_Sensor_Hub_Library.h>
#include <Wire.h>

#define DEF_ADDR 0x55

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
// FITNESS MODE
// ======================================================

// Change this with your age
//const int AGE = 23;

// Estimated maximum Heart Rate
//const float MAX_HR = 220.0 - AGE;
int age = 23;          // default age
int maxHR = 220 - age;

// ======================================================
// FITNESS ZONE TIMERS
// ======================================================

// Time of previous valid fitness measurement
unsigned long lastFitnessTime = 0;

// All times are stored in milliseconds
unsigned long totalActivityTime = 0;

unsigned long veryLightTime = 0;
unsigned long lightTime = 0;
unsigned long moderateTime = 0;
unsigned long hardTime = 0;
unsigned long maximumTime = 0;


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
// FITNESS ZONE FUNCTION
// ======================================================

String getFitnessZone(float percentage) {

  if (percentage < 50.0) {

    return "BELOW FITNESS ZONES";

  }

  else if (percentage < 60.0) {

    return "VERY LIGHT";

  }

  else if (percentage < 70.0) {

    return "LIGHT";

  }

  else if (percentage < 80.0) {

    return "MODERATE";

  }

  else if (percentage < 90.0) {

    return "HARD";

  }

  else {

    return "MAXIMUM";

  }
}


// ======================================================
// SETUP
// ======================================================
void stressBeep();
void setup() {

  // ----------------------------------------------------
  // BUZZER
  // ----------------------------------------------------

  pinMode(buzzerPin, OUTPUT);

  // Buzzer disabled for now
  digitalWrite(buzzerPin, LOW);


  // ----------------------------------------------------
  // SERIAL
  // ----------------------------------------------------

  Serial.begin(115200);


  // ----------------------------------------------------
  // I2C
  // ----------------------------------------------------

  Wire.begin();


  // ----------------------------------------------------
  // START SENSOR
  // ----------------------------------------------------

  int result = bioHub.begin();

  if (!result) {

    Serial.println("Sensor started!");

  }

  else {

    Serial.println("Could not communicate with sensor!");

  }


  // ----------------------------------------------------
  // CONFIGURE SENSOR
  // ----------------------------------------------------

  Serial.println("Configuring sensor...");

  int error = bioHub.configBpm(MODE_TWO);

  if (!error) {

    Serial.println("Sensor configured.");

  }

  else {

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
  
 // ============================================
// COMMANDS FROM PROCESSING
// ============================================

 // if (Serial.available() > 0) {

 // String command = Serial.readStringUntil('\n');
  //command.trim();

  
  //stressBeep();
  
 //}
 if (Serial.available() > 0) {

  String command = Serial.readStringUntil('\n');
  command.trim();

  if (command.startsWith("AGE,")) {

    int newAge = command.substring(4).toInt();

    if (newAge > 0 && newAge < 120) {
      age = newAge;
      maxHR = 220 - age;
    }
  }

  else if (command == "STRESS") {
    stressBeep();
  }
  else if (command == 'TEXT'){
    stressBeep();
  }
}


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
      (body.confidence > 0) &&
      (body.heartRate > 0);


  // ====================================================
  // VALID MEASUREMENT
  // ====================================================

  if (validMeasurement) {


    // --------------------------------------------------
    // FILTER HEART RATE
    // --------------------------------------------------

    float filteredHR =
        filterHeartRate(body.heartRate);


    // --------------------------------------------------
    // BEAT INTERVAL
    // --------------------------------------------------

    float beatInterval =
        60.0 / body.heartRate;


    // ==================================================
    // START RESTING BASELINE
    // ==================================================

    if (!baselineStarted) {

      baselineStarted = true;

      baselineStartTime = millis();

      baselineSum = 0.0;
      baselineSamples = 0;


      Serial.println();
      Serial.println("============================");
      Serial.println("RESTING BASELINE STARTED");
      Serial.println("============================");
      Serial.println();
    }


    // ==================================================
    // BASELINE PHASE
    // ==================================================

    if (!baselineComplete) {

      // Add valid filtered HR
      baselineSum += filteredHR;

      baselineSamples++;


      // Calculate elapsed baseline time
      unsigned long elapsedTime =
          millis() - baselineStartTime;


      Serial.print("Baseline time: ");

      Serial.print(
        elapsedTime / 1000.0,
        1
      );

      Serial.println(" / 30.0 s");


      // ------------------------------------------------
      // CHECK IF BASELINE IS COMPLETE
      // ------------------------------------------------

      if (elapsedTime >= BASELINE_DURATION) {

        // Calculate Resting HR
        restingHR =
            baselineSum / baselineSamples;

        baselineComplete = true;


        Serial.println();
        Serial.println("============================");
        Serial.println("BASELINE COMPLETE");


        Serial.print("Resting Heart Rate: ");

        Serial.print(restingHR, 1);

        Serial.println(" BPM");


        Serial.print("Valid samples: ");

        Serial.println(baselineSamples);


        Serial.println("============================");
        Serial.println();
      }
    }


    // ==================================================
    // DISPLAY CURRENT SENSOR DATA
    // ==================================================

    Serial.println("VALID MEASUREMENT");


    Serial.print("Heartrate: ");

    Serial.print(body.heartRate);

    Serial.println(" BPM");


    Serial.print("Filtered Heartrate: ");

    Serial.print(filteredHR, 1);

    Serial.println(" BPM");


    Serial.print("Beat Interval: ");

    Serial.print(beatInterval, 2);

    Serial.println(" s");


    Serial.print("Confidence: ");

    Serial.println(body.confidence);


    Serial.print("Oxygen: ");

    Serial.print(body.oxygen);

    Serial.println(" %");


    Serial.print("Status: ");

    Serial.println(body.status);


    Serial.print("Extended Status: ");

    Serial.println(body.extStatus);


    Serial.print("Blood Oxygen R value: ");

    Serial.println(body.rValue);


    // ==================================================
    // FITNESS MODE
    // ==================================================

    // Fitness Mode starts after the 30 s baseline

    if (baselineComplete) {


      // ------------------------------------------------
      // CALCULATE HR PERCENTAGE
      // ------------------------------------------------

      float hrPercentage =
          (filteredHR / maxHR) * 100.0;


      // ------------------------------------------------
      // DETERMINE FITNESS ZONE
      // ------------------------------------------------

      String fitnessZone =
          getFitnessZone(hrPercentage);


      // ------------------------------------------------
      // CALCULATE ELAPSED TIME
      // ------------------------------------------------

      unsigned long currentTime = millis();

      unsigned long deltaTime = 0;


      // Avoid counting time before Fitness Mode starts
      if (lastFitnessTime != 0) {

        deltaTime =
            currentTime - lastFitnessTime;
      }


      // Save current time for next iteration
      lastFitnessTime = currentTime;


      // =================================================
      // UPDATE FITNESS ZONE TIMERS
      // =================================================

      // Activity starts at 50% of Maximum HR

      if (hrPercentage >= 50.0) {


        // Total active time
        totalActivityTime += deltaTime;


        // -----------------------------------------------
        // VERY LIGHT
        // 50 - 60 %
        // -----------------------------------------------

        if (hrPercentage < 60.0) {

          veryLightTime += deltaTime;

        }


        // -----------------------------------------------
        // LIGHT
        // 60 - 70 %
        // -----------------------------------------------

        else if (hrPercentage < 70.0) {

          lightTime += deltaTime;

        }


        // -----------------------------------------------
        // MODERATE
        // 70 - 80 %
        // -----------------------------------------------

        else if (hrPercentage < 80.0) {

          moderateTime += deltaTime;

        }


        // -----------------------------------------------
        // HARD
        // 80 - 90 %
        // -----------------------------------------------

        else if (hrPercentage < 90.0) {

          hardTime += deltaTime;

        }


        // -----------------------------------------------
        // MAXIMUM
        // >= 90 %
        // -----------------------------------------------

        else {

          maximumTime += deltaTime;

        }
      }


      // =================================================
      // CONVERT MILLISECONDS TO SECONDS
      // =================================================

      float totalSeconds =
          totalActivityTime / 1000.0;


      float veryLightSeconds =
          veryLightTime / 1000.0;


      float lightSeconds =
          lightTime / 1000.0;


      float moderateSeconds =
          moderateTime / 1000.0;


      float hardSeconds =
          hardTime / 1000.0;


      float maximumSeconds =
          maximumTime / 1000.0;


      // =================================================
      // DISPLAY FITNESS MODE
      // =================================================

      Serial.println();

      Serial.println("===== FITNESS MODE =====");


      Serial.print("Age: ");

      Serial.println(age);


      Serial.print("Maximum HR: ");

      Serial.print(maxHR, 0);

      Serial.println(" BPM");


      Serial.print("Current HR: ");

      Serial.print(filteredHR, 1);

      Serial.println(" BPM");


      Serial.print("HR percentage: ");

      Serial.print(hrPercentage, 1);

      Serial.println(" %");


      Serial.print("Fitness Zone: ");

      Serial.println(fitnessZone);


      // ------------------------------------------------
      // DISPLAY FITNESS TIMES
      // ------------------------------------------------

      Serial.println();


      Serial.print("Total Activity Time: ");

      Serial.print(totalSeconds, 1);

      Serial.println(" s");


      Serial.print("Very Light Time: ");

      Serial.print(veryLightSeconds, 1);

      Serial.println(" s");


      Serial.print("Light Time: ");

      Serial.print(lightSeconds, 1);

      Serial.println(" s");


      Serial.print("Moderate Time: ");

      Serial.print(moderateSeconds, 1);

      Serial.println(" s");


      Serial.print("Hard Time: ");

      Serial.print(hardSeconds, 1);

      Serial.println(" s");


      Serial.print("Maximum Time: ");

      Serial.print(maximumSeconds, 1);

      Serial.println(" s");


      Serial.println("========================");
      Serial.print("DATA,");
      Serial.print(filteredHR, 1);
      Serial.print(",");

      Serial.print(beatInterval, 2);
      Serial.print(",");

      Serial.print(body.oxygen);
      Serial.print(",");

      Serial.print(body.confidence);
      Serial.print(",");

      Serial.print(restingHR, 1);
      Serial.print(",");

      Serial.print(hrPercentage, 1);
      Serial.print(",");

      Serial.print(fitnessZone);
      Serial.print(",");

      Serial.print(totalSeconds, 1);
      Serial.print(",");

      Serial.print(veryLightSeconds, 1);
      Serial.print(",");

      Serial.print(lightSeconds, 1);
      Serial.print(",");

      Serial.print(moderateSeconds, 1);
      Serial.print(",");

      Serial.print(hardSeconds, 1);
      Serial.print(",");

      Serial.println(maximumSeconds, 1);
    }
  }


  // ====================================================
  // INVALID MEASUREMENT
  // ====================================================

  else {

    // Reset the reference time.
    // This prevents invalid periods from being counted
    // as activity time when the signal returns.

    lastFitnessTime = 0;


    Serial.println("INVALID MEASUREMENT");


    Serial.print("Status: ");

    Serial.println(body.status);


    Serial.print("Extended Status: ");

    Serial.println(body.extStatus);


    Serial.print("Confidence: ");

    Serial.println(body.confidence);
  }
    

  Serial.println("----------------------");



  delay(250);
}


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