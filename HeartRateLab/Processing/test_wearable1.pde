import processing.serial.*;

Serial myPort;


// ======================================================
// DATA FROM ARDUINO
// ======================================================

float heartRate = 0;
float beatInterval = 0;
float spo2 = 0;
float confidence = 0;

float restingHR = 0;
float hrPercentage = 0;

String fitnessZone = "WAITING";

float totalTime = 0;
float veryLightTime = 0;
float lightTime = 0;
float moderateTime = 0;
float hardTime = 0;
float maximumTime = 0;


// ======================================================
// INTERFACE MODE
// ======================================================

// 0 = Fitness Mode
// 1 = Stress Mode

int currentMode = 0;


// ======================================================
// STRESS MODE
// ======================================================

float deltaHR = 0;

String stressState = "WAITING";

// Experimental thresholds
final float CALM_THRESHOLD = 5.0;
final float STRESS_THRESHOLD = 15.0;

// HR must remain above stress threshold for 5 seconds
final int STRESS_DURATION = 5000;

boolean stressTimerRunning = false;
int stressStartTime = 0;

float elevatedTime = 0;

// Prevent repeated STRESS commands
boolean stressCommandSent = false;


// ======================================================
// GRAPH
// ======================================================

final int GRAPH_SIZE = 250;

float[] hrHistory = new float[GRAPH_SIZE];

String[] zoneHistory = new String[GRAPH_SIZE];

int historyCount = 0;


// ======================================================
// SETUP
// ======================================================

void setup() {

  size(1200, 800);

  println("Available serial ports:");
  printArray(Serial.list());

  // COM3 was index 0 in our previous tests
  myPort = new Serial(
    this,
    Serial.list()[0],
    115200
  );

  myPort.bufferUntil('\n');
}


// ======================================================
// DRAW
// ======================================================

void draw() {

  background(25);

  drawTitle();
  drawModeButtons();

  if (currentMode == 0) {

    drawFitnessMode();

  } else {

    drawStressMode();
  }
}


// ======================================================
// TITLE
// ======================================================

void drawTitle() {

  fill(255);
  textAlign(LEFT);
  textSize(30);

  text(
    "Heart Rate Monitor",
    40,
    45
  );
}


// ======================================================
// MODE BUTTONS
// ======================================================

void drawModeButtons() {

  // FITNESS BUTTON

  if (currentMode == 0) {

    fill(80, 150, 255);

  } else {

    fill(80);
  }

  noStroke();

  rect(
    40,
    65,
    200,
    45,
    8
  );

  fill(255);
  textAlign(CENTER, CENTER);
  textSize(16);

  text(
    "FITNESS MODE",
    140,
    87
  );


  // STRESS BUTTON

  if (currentMode == 1) {

    fill(255, 170, 50);

  } else {

    fill(80);
  }

  rect(
    260,
    65,
    200,
    45,
    8
  );

  fill(255);

  text(
    "STRESS MODE",
    360,
    87
  );

  textAlign(LEFT);
}


// ======================================================
// MOUSE CLICK
// ======================================================

void mousePressed() {

  // FITNESS MODE

  if (
    mouseX >= 40 &&
    mouseX <= 240 &&
    mouseY >= 65 &&
    mouseY <= 110
  ) {

    currentMode = 0;

    stressTimerRunning = false;
    elevatedTime = 0;
    stressCommandSent = false;

    println("FITNESS MODE selected");
  }


  // STRESS MODE

  if (
    mouseX >= 260 &&
    mouseX <= 460 &&
    mouseY >= 65 &&
    mouseY <= 110
  ) {

    currentMode = 1;

    stressTimerRunning = false;
    elevatedTime = 0;
    stressCommandSent = false;

    println("STRESS MODE selected");
  }
}


// ======================================================
// FITNESS MODE
// ======================================================

void drawFitnessMode() {

  drawMeasurements();

  drawFitnessInformation();

  drawZoneTimes();

  drawFitnessGraph();
}


// ======================================================
// MAIN MEASUREMENTS
// ======================================================

void drawMeasurements() {

  fill(255);
  textAlign(LEFT);


  // HEART RATE

  textSize(18);

  text(
    "Heart Rate",
    40,
    155
  );

  textSize(30);

  text(
    nf(heartRate, 0, 1) + " BPM",
    40,
    195
  );


  // BEAT INTERVAL

  textSize(18);

  text(
    "Beat Interval",
    250,
    155
  );

  textSize(30);

  text(
    nf(beatInterval, 0, 2) + " s",
    250,
    195
  );


  // SpO2

  textSize(18);

  text(
    "SpO2",
    460,
    155
  );

  textSize(30);

  text(
    nf(spo2, 0, 0) + " %",
    460,
    195
  );


  // CONFIDENCE

  textSize(18);

  text(
    "Confidence",
    630,
    155
  );

  textSize(30);

  text(
    nf(confidence, 0, 0),
    630,
    195
  );
}


// ======================================================
// FITNESS INFORMATION
// ======================================================

void drawFitnessInformation() {

  fill(255);
  textAlign(LEFT);
  textSize(18);


  text(
    "Resting HR: " +
    nf(restingHR, 0, 1) +
    " BPM",
    40,
    260
  );


  text(
    "HRmax: " +
    nf(hrPercentage, 0, 1) +
    " %",
    260,
    260
  );


  // FITNESS ZONE BOX

  setZoneColor(fitnessZone);

  noStroke();

  rect(
    480,
    230,
    330,
    45,
    8
  );

  fill(0);

  textAlign(CENTER, CENTER);
  textSize(18);

  text(
    fitnessZone,
    645,
    252
  );

  textAlign(LEFT);
}


// ======================================================
// FITNESS ZONE TIMES
// ======================================================

void drawZoneTimes() {

  fill(255);
  textAlign(LEFT);
  textSize(22);

  text(
    "Fitness Zone Times",
    850,
    145
  );


  textSize(17);


  // VERY LIGHT

  fill(180);

  text(
    "Very Light: " +
    nf(veryLightTime, 0, 1) +
    " s",
    850,
    185
  );


  // LIGHT

  fill(80, 150, 255);

  text(
    "Light: " +
    nf(lightTime, 0, 1) +
    " s",
    850,
    220
  );


  // MODERATE

  fill(70, 200, 100);

  text(
    "Moderate: " +
    nf(moderateTime, 0, 1) +
    " s",
    850,
    255
  );


  // HARD

  fill(255, 170, 50);

  text(
    "Hard: " +
    nf(hardTime, 0, 1) +
    " s",
    850,
    290
  );


  // MAXIMUM

  fill(255, 70, 70);

  text(
    "Maximum: " +
    nf(maximumTime, 0, 1) +
    " s",
    850,
    325
  );


  // TOTAL

  fill(255);

  text(
    "Total Activity: " +
    nf(totalTime, 0, 1) +
    " s",
    850,
    370
  );
}


// ======================================================
// FITNESS GRAPH
// ======================================================

void drawFitnessGraph() {

  float graphX = 60;
  float graphY = 400;

  float graphW = 1080;
  float graphH = 340;


  fill(255);
  textAlign(LEFT);
  textSize(22);

  text(
    "Heart Rate",
    graphX,
    graphY - 25
  );


  // GRAPH BACKGROUND

  fill(35);
  stroke(100);
  strokeWeight(1);

  rect(
    graphX,
    graphY,
    graphW,
    graphH
  );


  // GRID

  textSize(14);

  for (int bpm = 40; bpm <= 200; bpm += 20) {

    float y = map(
      bpm,
      40,
      200,
      graphY + graphH,
      graphY
    );


    stroke(60);

    line(
      graphX,
      y,
      graphX + graphW,
      y
    );


    fill(180);

    text(
      bpm,
      graphX - 35,
      y + 5
    );
  }


  if (historyCount < 2) {
    return;
  }


  // MULTICOLORED HR TRACE

  strokeWeight(3);


  for (int i = 1; i < historyCount; i++) {

    float x1 = map(
      i - 1,
      0,
      GRAPH_SIZE - 1,
      graphX,
      graphX + graphW
    );


    float y1 = map(
      hrHistory[i - 1],
      40,
      200,
      graphY + graphH,
      graphY
    );


    float x2 = map(
      i,
      0,
      GRAPH_SIZE - 1,
      graphX,
      graphX + graphW
    );


    float y2 = map(
      hrHistory[i],
      40,
      200,
      graphY + graphH,
      graphY
    );


    y1 = constrain(
      y1,
      graphY,
      graphY + graphH
    );


    y2 = constrain(
      y2,
      graphY,
      graphY + graphH
    );


    setZoneStrokeColor(
      zoneHistory[i]
    );


    line(
      x1,
      y1,
      x2,
      y2
    );
  }


  strokeWeight(1);
}


// ======================================================
// STRESS MODE
// ======================================================

void drawStressMode() {

  // Difference between current HR and resting HR

  deltaHR = heartRate - restingHR;


  // ====================================================
  // DETERMINE STRESS STATE
  // ====================================================

  if (heartRate <= 0 || restingHR <= 0) {

    stressState = "WAITING";

    stressTimerRunning = false;

    elevatedTime = 0;

    stressCommandSent = false;
  }


  // ----------------------------------------------------
  // CALM
  // ----------------------------------------------------

  else if (deltaHR <= CALM_THRESHOLD) {

    stressState = "CALM";

    stressTimerRunning = false;

    elevatedTime = 0;

    // Ready for a future stress episode
    stressCommandSent = false;
  }


  // ----------------------------------------------------
  // NORMAL
  // ----------------------------------------------------

  else if (deltaHR < STRESS_THRESHOLD) {

    stressState = "NORMAL";

    stressTimerRunning = false;

    elevatedTime = 0;

    // Ready for a future stress episode
    stressCommandSent = false;
  }


  // ----------------------------------------------------
  // ABOVE STRESS THRESHOLD
  // ----------------------------------------------------

  else {

    // Start timer only once

    if (!stressTimerRunning) {

      stressTimerRunning = true;

      stressStartTime = millis();
    }


    elevatedTime =
      (millis() - stressStartTime) / 1000.0;


    // --------------------------------------------------
    // STRESSED AFTER 5 SECONDS
    // --------------------------------------------------

    if (elevatedTime >= 5.0) {

      stressState = "STRESSED";


      // Send STRESS command only once
      if (!stressCommandSent) {

        println("ABOUT TO SEND STRESS");

        myPort.write("STRESS\n");

        delay(100);

        myPort.write("TEST\n");
  
        println("STRESS + TEST sent to Arduino");

        stressCommandSent = true;
      }

    }


    // --------------------------------------------------
    // ABOVE THRESHOLD, BUT LESS THAN 5 SECONDS
    // --------------------------------------------------

    else {

      stressState = "ELEVATED";
    }
  }


  // ====================================================
  // CURRENT HEART RATE
  // ====================================================

  fill(255);
  textAlign(LEFT);
  textSize(18);

  text(
    "Current Heart Rate",
    60,
    175
  );


  textSize(38);

  text(
    nf(heartRate, 0, 1) +
    " BPM",
    60,
    220
  );


  // ====================================================
  // RESTING HEART RATE
  // ====================================================

  textSize(18);

  text(
    "Resting Heart Rate",
    340,
    175
  );


  textSize(38);

  text(
    nf(restingHR, 0, 1) +
    " BPM",
    340,
    220
  );


  // ====================================================
  // CHANGE FROM RESTING
  // ====================================================

  textSize(18);

  text(
    "Change from Resting",
    650,
    175
  );


  textSize(38);


  if (deltaHR >= 0) {

    text(
      "+" +
      nf(deltaHR, 0, 1) +
      " BPM",
      650,
      220
    );

  } else {

    text(
      nf(deltaHR, 0, 1) +
      " BPM",
      650,
      220
    );
  }


  // ====================================================
  // CURRENT STATE
  // ====================================================

  textSize(20);

  fill(255);

  text(
    "Current State",
    60,
    300
  );


  // STATE COLOR

  if (stressState.equals("CALM")) {

    fill(70, 200, 100);

  }

  else if (stressState.equals("NORMAL")) {

    fill(255, 190, 60);

  }

  else if (stressState.equals("ELEVATED")) {

    fill(255, 140, 40);

  }

  else if (stressState.equals("STRESSED")) {

    fill(255, 70, 70);

  }

  else {

    fill(120);
  }


  noStroke();

  rect(
    60,
    320,
    350,
    80,
    10
  );


  fill(0);

  textAlign(CENTER, CENTER);

  textSize(30);

  text(
    stressState,
    235,
    360
  );


  textAlign(LEFT);


  // ====================================================
  // ELEVATED TIMER
  // ====================================================

  if (
    stressTimerRunning &&
    !stressState.equals("STRESSED")
  ) {

    fill(255);

    textSize(16);

    text(
      "Elevated HR: " +
      nf(elevatedTime, 0, 1) +
      " / 5.0 s",
      60,
      430
    );
  }


  // ====================================================
  // THRESHOLD INFORMATION
  // ====================================================

  fill(180);

  textSize(16);


  text(
    "CALM: HR increase <= +" +
    nf(CALM_THRESHOLD, 0, 0) +
    " BPM",
    470,
    325
  );


  text(
    "NORMAL: +" +
    nf(CALM_THRESHOLD, 0, 0) +
    " to +" +
    nf(STRESS_THRESHOLD, 0, 0) +
    " BPM",
    470,
    355
  );


  text(
    "STRESSED: HR increase >= +" +
    nf(STRESS_THRESHOLD, 0, 0) +
    " BPM for 5 s",
    470,
    385
  );


  // ====================================================
  // STRESS GRAPH
  // ====================================================

  drawStressGraph();
}


// ======================================================
// STRESS GRAPH
// ======================================================

void drawStressGraph() {

  float graphX = 60;
  float graphY = 470;

  float graphW = 1080;
  float graphH = 270;


  fill(255);

  textAlign(LEFT);

  textSize(22);

  text(
    "Heart Rate vs Resting Heart Rate",
    graphX,
    graphY - 25
  );


  // GRAPH BACKGROUND

  fill(35);

  stroke(100);

  strokeWeight(1);

  rect(
    graphX,
    graphY,
    graphW,
    graphH
  );


  // GRID

  textSize(14);


  for (int bpm = 40; bpm <= 160; bpm += 20) {

    float y = map(
      bpm,
      40,
      160,
      graphY + graphH,
      graphY
    );


    stroke(60);

    line(
      graphX,
      y,
      graphX + graphW,
      y
    );


    fill(180);

    text(
      bpm,
      graphX - 35,
      y + 5
    );
  }


  // ====================================================
  // RESTING HR LINE
  // ====================================================

  if (restingHR > 0) {

    float restingY = map(
      restingHR,
      40,
      160,
      graphY + graphH,
      graphY
    );


    restingY = constrain(
      restingY,
      graphY,
      graphY + graphH
    );


    stroke(
      100,
      200,
      255
    );

    strokeWeight(2);

    line(
      graphX,
      restingY,
      graphX + graphW,
      restingY
    );


    fill(
      100,
      200,
      255
    );

    text(
      "Resting HR",
      graphX + 10,
      restingY - 8
    );
  }


  // ====================================================
  // HR TRACE
  // ====================================================

  if (historyCount < 2) {

    strokeWeight(1);

    return;
  }


  strokeWeight(3);


  for (int i = 1; i < historyCount; i++) {

    float x1 = map(
      i - 1,
      0,
      GRAPH_SIZE - 1,
      graphX,
      graphX + graphW
    );


    float y1 = map(
      hrHistory[i - 1],
      40,
      160,
      graphY + graphH,
      graphY
    );


    float x2 = map(
      i,
      0,
      GRAPH_SIZE - 1,
      graphX,
      graphX + graphW
    );


    float y2 = map(
      hrHistory[i],
      40,
      160,
      graphY + graphH,
      graphY
    );


    y1 = constrain(
      y1,
      graphY,
      graphY + graphH
    );


    y2 = constrain(
      y2,
      graphY,
      graphY + graphH
    );


    // Color according to HR relative to resting HR

    float sampleDelta =
      hrHistory[i] - restingHR;


    if (
      sampleDelta <=
      CALM_THRESHOLD
    ) {

      stroke(70, 200, 100);

    }

    else if (
      sampleDelta <
      STRESS_THRESHOLD
    ) {

      stroke(255, 190, 60);

    }

    else {

      stroke(255, 70, 70);
    }


    line(
      x1,
      y1,
      x2,
      y2
    );
  }


  strokeWeight(1);
}


// ======================================================
// ADD HEART RATE TO HISTORY
// ======================================================

void addHeartRate(
  float newHR,
  String newZone
) {

  if (newHR <= 0) {
    return;
  }


  // BUFFER NOT FULL

  if (historyCount < GRAPH_SIZE) {

    hrHistory[historyCount] =
      newHR;

    zoneHistory[historyCount] =
      newZone;

    historyCount++;
  }


  // BUFFER FULL

  else {

    for (
      int i = 0;
      i < GRAPH_SIZE - 1;
      i++
    ) {

      hrHistory[i] =
        hrHistory[i + 1];

      zoneHistory[i] =
        zoneHistory[i + 1];
    }


    hrHistory[
      GRAPH_SIZE - 1
    ] = newHR;


    zoneHistory[
      GRAPH_SIZE - 1
    ] = newZone;
  }
}


// ======================================================
// FITNESS ZONE BOX COLOR
// ======================================================

void setZoneColor(String zone) {

  if (zone.equals("VERY LIGHT")) {

    fill(180);

  }

  else if (zone.equals("LIGHT")) {

    fill(80, 150, 255);

  }

  else if (zone.equals("MODERATE")) {

    fill(70, 200, 100);

  }

  else if (zone.equals("HARD")) {

    fill(255, 170, 50);

  }

  else if (zone.equals("MAXIMUM")) {

    fill(255, 70, 70);

  }

  else {

    fill(140);
  }
}


// ======================================================
// FITNESS GRAPH COLORS
// ======================================================

void setZoneStrokeColor(String zone) {

  if (zone == null) {

    stroke(200);

    return;
  }


  if (zone.equals("VERY LIGHT")) {

    stroke(180);

  }

  else if (zone.equals("LIGHT")) {

    stroke(80, 150, 255);

  }

  else if (zone.equals("MODERATE")) {

    stroke(70, 200, 100);

  }

  else if (zone.equals("HARD")) {

    stroke(255, 170, 50);

  }

  else if (zone.equals("MAXIMUM")) {

    stroke(255, 70, 70);

  }

  else {

    stroke(200);
  }
}


// ======================================================
// SERIAL EVENT
// ======================================================

void serialEvent(Serial port) {

  String line =
    port.readStringUntil('\n');


  if (line == null) {
    return;
  }


  line = trim(line);


  // Only process DATA packets

  if (!line.startsWith("DATA,")) {
    return;
  }


  println(
    "Received: " + line
  );


  String[] data =
    split(line, ',');


  // Expected DATA packet = 14 elements

  if (data.length == 14) {

    heartRate =
      float(data[1]);


    beatInterval =
      float(data[2]);


    spo2 =
      float(data[3]);


    confidence =
      float(data[4]);


    restingHR =
      float(data[5]);


    hrPercentage =
      float(data[6]);


    fitnessZone =
      data[7];


    totalTime =
      float(data[8]);


    veryLightTime =
      float(data[9]);


    lightTime =
      float(data[10]);


    moderateTime =
      float(data[11]);


    hardTime =
      float(data[12]);


    maximumTime =
      float(data[13]);


    // Add sample to graph

    addHeartRate(
      heartRate,
      fitnessZone
    );
  }
}
