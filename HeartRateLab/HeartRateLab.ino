#include <SparkFun_Bio_Sensor_Hub_Library.h>
#include <Wire.h>

// No other Address options.
#define DEF_ADDR 0x55

// Reset pin, MFIO pin
const int resPin = 4;
const int mfioPin = 5;
const int buzzerPin = D12;

// Takes address, reset pin, and MFIO pin.
SparkFun_Bio_Sensor_Hub bioHub(resPin, mfioPin); 

/*type biodata - holds Heart rate, confidence,
    blood oxygen levels, finger detection,
    led data, etc. */
bioData body;  

void setup(){
  // Initialize the buzzer pin as an output
  pinMode(buzzerPin, OUTPUT); 

  Serial.begin(115200);

  //enables I2C communication
  Wire.begin();

  //enables sensor communication
  int result = bioHub.begin();
  if (!result)
    Serial.println("Sensor started!");
  else
    Serial.println("Could not communicate with the sensor!!!");

  Serial.println("Configuring Sensor...."); 

  //configures  Oximeter Settings, enables necessary alghorithms to collect data
  //MODE_TWO gets more info
  int error = bioHub.configBpm(MODE_TWO); // Configuring just the BPM settings. 
  if(!error){
    Serial.println("Sensor configured.");
  }
  else {
    Serial.println("Error configuring sensor.");
    Serial.print("Error: "); 
    Serial.println(error); 
  }
  // Data lags a bit behind the sensor, if you're finger is on the sensor when
  // it's being configured this delay will give some time for the data to catch
  // up. 
  delay(4000); 

}

//get led data through: bioHub.configSensor()

void loop(){

  // biometic data is collected here
  // readBpm function saved in our "body"
  body = bioHub.readBpm();
  Serial.print("Heartrate: ");
  Serial.println(body.heartRate); 
  Serial.print("Confidence: ");
  Serial.println(body.confidence); 
  Serial.print("Oxygen: ");
  Serial.println(body.oxygen); 
  Serial.print("Status: ");  //checks if live sample present
  Serial.println(body.status); 

  //MODE_TWO additions:
  Serial.print("Extended Status: "); //checks if live sample present
  Serial.println(body.extStatus); 
  Serial.print("Blood Oxygen R value: ");
  Serial.println(body.rValue); 

  delay(250); // Slowing it down, we don't need to break our necks here.
}

  //MODE_TWO additions:
  Serial.print("Extended Status: "); //checks if live sample pressed right
  Serial.println(body.extStatus); 
  Serial.print("Blood Oxygen R value: ");
  Serial.println(body.rValue); 

  // testing buzzer by checking if finger status is good
  if (body.extStatus == 0){
    digitalWrite(buzzerPin, HIGH);
  }
  else {
    digitalWrite(buzzerPin, LOW);
  }
  delay(250); // Slowing it down, we don't need to break our necks here.
}