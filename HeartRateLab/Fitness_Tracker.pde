import processing.serial.*;

Serial esp;

// How many samples to display at once
int MAX_SAMPLES = 8;

// Data names
String[] labels = {
  "Heartrate",
  "Confidence",
  "Oxygen",
  "Status",
  "Extended Status",
  "Blood Oxygen R"
};

// Data storage
ArrayList<String[]> samples = new ArrayList<String[]>();

// Used to collect one complete reading from the ESP
String[] currentSample = new String[6];
boolean[] received = new boolean[6];

void setup() {
  size(1000, 480);
  surface.setTitle("Heart Rate Monitor");

  // Print available serial ports
  println(Serial.list());

  // CHANGE THIS to the port your ESP is using
  // For example: Serial.list()[0], Serial.list()[1], etc.
  esp = new Serial(this, Serial.list()[0], 115200);

  // Read one line at a time
  esp.bufferUntil('\n');

  textFont(createFont("Arial", 16));

  // Initialize current sample
  resetCurrentSample();
}

void draw() {
  background(250);

  // Title
  fill(20);
  textAlign(LEFT, CENTER);
  textSize(24);
  text("Heart Rate Monitor", 40, 35);

  drawTable();
}

void drawTable() {
  float tableX = 40;
  float tableY = 70;

  float labelWidth = 180;
  float columnWidth = 90;
  float rowHeight = 55;

  // Number of columns actually containing data
  int count = samples.size();

  // Table dimensions
  float tableWidth = labelWidth + MAX_SAMPLES * columnWidth;
  float tableHeight = (labels.length + 1) * rowHeight;

  // Outer border
  stroke(100);
  strokeWeight(1);
  fill(255);
  rect(tableX, tableY, tableWidth, tableHeight);

  // Header
  fill(230);
  rect(tableX, tableY, tableWidth, rowHeight);

  fill(20);
  textSize(16);
  textAlign(CENTER, CENTER);

  // Information header
  text("Information", tableX + labelWidth / 2, tableY + rowHeight / 2);

  // Time/sample headers
  for (int i = 0; i < MAX_SAMPLES; i++) {
    float x = tableX + labelWidth + i * columnWidth;

    if (i < count) {
      text("Time " + (i + 1),
           x + columnWidth / 2,
           tableY + rowHeight / 2);
    }
  }

  // Draw rows
  for (int row = 0; row < labels.length; row++) {

    float y = tableY + (row + 1) * rowHeight;

    // Row label
    fill(240);
    rect(tableX, y, labelWidth, rowHeight);

    fill(20);
    textAlign(LEFT, CENTER);
    text(labels[row],
         tableX + 10,
         y + rowHeight / 2);

    // Data cells
    for (int col = 0; col < MAX_SAMPLES; col++) {

      float x = tableX + labelWidth + col * columnWidth;

      fill(255);
      rect(x, y, columnWidth, rowHeight);

      if (col < count) {
        fill(20);
        textAlign(CENTER, CENTER);

        String value = samples.get(col)[row];

        text(value,
             x + columnWidth / 2,
             y + rowHeight / 2);
      }
    }
  }
}

// Called whenever a complete line arrives from the ESP
void serialEvent(Serial esp) {

  String line = esp.readStringUntil('\n');

  if (line == null) {
    return;
  }

  line = trim(line);

  println(line);

  // Determine which value this line contains
  if (line.startsWith("Heartrate:")) {
    currentSample[0] = getValue(line);
    received[0] = true;
  }

  else if (line.startsWith("Confidence:")) {
    currentSample[1] = getValue(line);
    received[1] = true;
  }

  else if (line.startsWith("Oxygen:")) {
    currentSample[2] = getValue(line);
    received[2] = true;
  }

  else if (line.startsWith("Status:")) {
    currentSample[3] = getValue(line);
    received[3] = true;
  }

  else if (line.startsWith("Extended Status:")) {
    currentSample[4] = getValue(line);
    received[4] = true;
  }

  else if (line.startsWith("Blood Oxygen R value:")) {
    currentSample[5] = getValue(line);
    received[5] = true;
  }

  // Once all six values have arrived, save the sample
  if (allReceived()) {

    // Make a copy so future values don't overwrite this sample
    String[] newSample = new String[6];

    for (int i = 0; i < 6; i++) {
      newSample[i] = currentSample[i];
    }

    samples.add(newSample);

    // Remove oldest sample when table is full
    if (samples.size() > MAX_SAMPLES) {
      samples.remove(0);
    }

    resetCurrentSample();
  }
}

// Extract everything after the colon
String getValue(String line) {

  int colon = line.indexOf(':');

  if (colon == -1) {
    return "";
  }

  return trim(line.substring(colon + 1));
}

// Check whether we received all six values
boolean allReceived() {

  for (int i = 0; i < received.length; i++) {

    if (!received[i]) {
      return false;
    }
  }

  return true;
}

// Prepare for the next sensor reading
void resetCurrentSample() {

  for (int i = 0; i < 6; i++) {
    currentSample[i] = "";
    received[i] = false;
  }
}
