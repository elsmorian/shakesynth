// SHAKETest.pde
// Prints all incomming data from the SHAKE
//
// Chris Elsmore 2009 <elsmorian@gmail.com>

import processing.serial.*;

Serial myPort;          // Create serial port object
String serialString;    // String to hold serial data
int cr = 13;            // ASCII character caridge Return = 13
int lf = 10;            // ASCII character linefeed = 10

void setup() 
{
  size(200, 200);                                            // Draw canvas 200 by 200 pixels
  String portName = Serial.list()[0];                        // Assign portname to a string from serial list (Change array number (currently 0) 
  //String portName = "/dev/tty.SHAKESK6R00SN0096-KC-SPP-1"  // Or uncomment and alter this line if you know the name from running SerialList
  myPort = new Serial(this, portName, 230400);               // Assign myport to the serial port chosen, and start comms at 230400
  myPort.clear();                                            // Clear serial port buffer
}

void draw()                                       // Draw method runs in a loop
{
  if ( myPort.available() > 0) {                  // If data is available,
    serialString = myPort.readStringUntil(lf);    // read data until linefeed encountered
    println(serialString);                        // Print read data
  }
}

