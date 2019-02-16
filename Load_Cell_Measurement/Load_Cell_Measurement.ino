// Brenden Wong
// Chavkin Lab
// SURP 2018

//This sketch allows Arduino Uno to record the mass of a gel cup and write the resulting mass along with a time stamp to an SD card

# include <Time.h>                                 // include time library
# include <TimeLib.h>
# include "HX711.h"                                // include load cell library
# include <SD.h>                                   // include capability to write to SD card
# include <SPI.h>
# include <LiquidCrystal.h>
# define DOUT 6                                    // define pins for load cell
# define CLK 7

LiquidCrystal lcd(9, 8, 5, 4, 3, 2);

HX711 scale(DOUT, CLK);                            ////////////////////// 
float calibration_factor = 7530; //<---------------///Adjust as needed///
char filename[] = "LOADCELL.CSV";                  //////////////////////
char filenameTime[] = "TIME.CSV";
int chipSelect = 10;
File file;
File fileTime;

void setup() {
  Serial.begin(9600);
  pinMode(chipSelect, OUTPUT);                        // chip select pin must be set to OUTPUT mode
  if (!SD.begin(chipSelect)) {                        // Initialize SD card
    Serial.println("Could not initialize SD card.");  // if return value is false, something went wrong.
  } 
  if (SD.exists(filename)) {                          // if file exists, file will be deleted
    Serial.println("File exists.");
    if (SD.remove(filename) == true) {
      Serial.println("Successfully removed file.");
    } else {
      Serial.println("Could not removed file.");
    }
  }
  if (SD.exists(filenameTime)) {
    Serial.println("Time exists.");
    if (SD.remove(filenameTime) == true) {
      Serial.println("Successfully removed time file.");
    } else {
      Serial.println("Could not remove time.");
    }
  }
  scale.set_scale();
  scale.tare();                                    //Reset the scale to 0
  long zero_factor = scale.read_average();         //Get a baseline reading
  lcd.begin(16,2);
  lcd.print("Mass is:");
}

void loop(){
  scale.set_scale(calibration_factor);             //Adjust to this calibration factor
  file = SD.open(filename, FILE_WRITE);
  if (file) {
    file.println(scale.get_units(), 2);            // write number to file
    file.close(); // close file
    Serial.print("Wrote number: ");                // debug output: show written number in serial monitor
    Serial.println(scale.get_units(), 2);
  } else {
    Serial.println("Could not open file (writing).");
  }
  fileTime = SD.open(filenameTime, FILE_WRITE);
  if (fileTime) {
    fileTime.print(hour());
    fileTime.print(":");
    fileTime.print(minute());
    fileTime.print(":");
    fileTime.println(second());
    fileTime.close();
    Serial.print("Wrote time: ");
    Serial.print(hour());
    Serial.print(":");
    Serial.print(minute());
    Serial.print(":");
    Serial.println(second());
  } else {
    Serial.println("Could not write time");
  }
  Serial.print("Scale reading: ");
  Serial.println(scale.get_units(), 2); 
  lcd.setCursor(0, 1);
  lcd.print(scale.get_units(), 2);
  delay(2000);                                   // Delay 2 seconds
}








