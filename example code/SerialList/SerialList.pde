// SerialList.pde
// Lists all serial ports avalible on the system
//
// Chris Elsmore 2009 <elsmorian@gmail.com>

import processing.serial.*;    // Import processing serial lib

void setup() 
{
  size(200, 200);             // Draw 200 x 200 canvas
  println(Serial.list());     // Print out list of all avalible serial ports on the system
}

