// SHAKESynth.pde
//
// SHAKESynth - Processing sound generator controled by a SHAKE device.
// Chris Elsmore 2009 <elsmorian@gmail.com>
//
// Copyright (c) 2009, Chris Elsmore
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the organization nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY Chris Elsmore ''AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL Chris Elsmore BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import processing.serial.*;  // Import required libs
import ddf.minim.*;
import ddf.minim.signals.*;

Minim myMinim;            // Create Minim object
AudioOutput myAudioOut;   // Create AudioOut object

SawWave mySawWave;        // Create Wave objects
SineWave mySineWave;
TriangleWave myTriangleWave;
SquareWave mySquareWave;

Serial myPort;            // Create myPort object from Serial class
String serialString;      // Data received from the serial port as a String
int cr = 13;              // ASCII char Caridge Return = 13
int lf = 10;              // ASCII char Line Feed = 10

int selectedWave = 0;
int portamento;
int initalamp;
Boolean mute = false;

void setup() {
    size(512, 300, P2D);        // Draw a 512x300 canvas
    myMinim = new Minim(this);
    myAudioOut = myMinim.getLineOut(Minim.STEREO);  // Create lineout from minim, default bufferSize is 1024, samplerate 44100, 16bit
  
    mySawWave = new SawWave(440, 0.5, myAudioOut.sampleRate());       // Create waveforms
    mySineWave = new SineWave(440, 0.5, myAudioOut.sampleRate());
    myTriangleWave = new TriangleWave(440, 0.5, myAudioOut.sampleRate());
    mySquareWave = new SquareWave(440, 0.5, myAudioOut.sampleRate());
  
    portamento = 200;                      // Set portamento for smooth frequency change
    mySawWave.portamento(portamento);
    mySineWave.portamento(portamento);
    myTriangleWave.portamento(portamento);
    mySquareWave.portamento(portamento);
    
    initalamp = 0;                        // Mute initial waves
    mySawWave.setAmp(initalamp);
    mySineWave.setAmp(initalamp);
    myTriangleWave.setAmp(initalamp);
    mySquareWave.setAmp(initalamp);
  
    myAudioOut.addSignal(mySawWave);      // Add waves to sound output
    myAudioOut.addSignal(mySineWave);
    myAudioOut.addSignal(myTriangleWave);
    myAudioOut.addSignal(mySquareWave);
  
    String portName = Serial.list()[12];               // Create Port name from the []th serial in the list
    myPort = new Serial(this, portName, 230400);       // Setup coms to SHAKE
    //myPort.write("$WRI,0000,82");                    // Exclude all data but ACC + Nav Button data
    myPort.clear();
    
    // Throw out the first reading, in case we started reading in the middle of packet
    println(serialString);
    serialString = null;
}

void draw() {
    background(0);
    stroke(0,255,0);
    while (myPort.available() > 0) {                 // When data is avalible,
        serialString = myPort.readStringUntil(lf);   // Read data until LF (Linefeed) char is found (End of SHAKE data string)
        if (serialString != null) {                  // If line is not null, split using commas as tokens
            String[] serialArray = split(serialString, ',');
            if (serialArray[0].equals("$ACC")) {     // If read serial string is a accelerometer packet;
                float x = float(serialArray[1]);     // Get X Y and Z ACC values
                float y = float(serialArray[2]);
                float z = float(serialArray[3]);
                
                if (z > 600){mute = false; switchWave();}   // If SHAKE is right way up, enable currently selected wave
                else if (z < -600){mute = true; muteAll();} // If SHAKE is upside down, mute.
                
                if (y > 600){increaseAllPan();}             // Control panning from Y axis ACC data
                else if (y < -600){decreaseAllPan();}
                
                setAllFrequency(x);    // Call setAllFrequency with current X ACC data
            }//End if
            
            else {
                serialArray = split(serialString, char(cr));  // Control enabled wave type via navigation switch on SHAKE
                if (serialArray[0].equals("$NVD")) {          // Cycle down through wave types, looping from 0 to 3
                    if (selectedWave == 0){
                        selectedWave = 3;
                    }
                    else {
                        selectedWave--;
                    }
                }//End else
                if (serialArray[0].equals("$NVU")) { // Cycle up through wave types, looping from 3 to 0
                    if (selectedWave == 3){
                        selectedWave = 0;
                    }
                    else {
                        selectedWave++;
                    }
                }//End if
            }//End else
            if(!mute){switchWave();} // Ef mute is not enabled, update waves with amplitude data
        }
        for(int i = 0; i < myAudioOut.bufferSize() - 1; i++) {        // Draw wave representations of selected sound on canvas,
            float x1 = map(i, 0, myAudioOut.bufferSize(), 0, width);  // Map buffersize to canvas size so buffer fits width.
            float x2 = map(i+1, 0, myAudioOut.bufferSize(), 0, width);
            //strokeWeight(3);
            line(x1, 60 + myAudioOut.left.get(i)*50, x2, 60 + myAudioOut.left.get(i+1)*50);  // Plot lines for waves
            line(x1, 200 + myAudioOut.right.get(i)*50, x2, 200 + myAudioOut.right.get(i+1)*50);
         }//End for
    }//End while
}//End draw

void setAllFrequency(float frequency ){ // Set wave frequencies
    frequency += 1000;
    mySawWave.setFreq(frequency);
    mySineWave.setFreq(frequency);
    myTriangleWave.setFreq(frequency);
    mySquareWave.setFreq(frequency);
}

void increaseAllPan() { // Increase all wave pans
    float pan = mySawWave.pan();
    pan += 0.025;
    mySawWave.setPan(pan);
    mySineWave.setPan(pan);
    myTriangleWave.setPan(pan);
    mySquareWave.setPan(pan);
}

void decreaseAllPan() { // Decrease all wave pans
    float pan = mySawWave.pan();
    pan -= 0.025;
    mySawWave.setPan(pan);
    mySineWave.setPan(pan);
    myTriangleWave.setPan(pan);
    mySquareWave.setPan(pan);
}

void muteAll() { // Mute all waves
    mySawWave.setAmp(0);
    mySineWave.setAmp(0);
    myTriangleWave.setAmp(0);
    mySquareWave.setAmp(0);

}

void switchWave() {  // Enable slected wave
    switch(selectedWave) {
        case 0:
            mySawWave.setAmp(1);
            mySineWave.setAmp(0);
            myTriangleWave.setAmp(0);
            mySquareWave.setAmp(0);
            break;
                            
        case 1:
            mySawWave.setAmp(0);
            mySineWave.setAmp(1);
            myTriangleWave.setAmp(0);
            mySquareWave.setAmp(0);
            break;

        case 2:
            mySawWave.setAmp(0);
            mySineWave.setAmp(0);
            myTriangleWave.setAmp(1);
            mySquareWave.setAmp(0);
            break;

        case 3:
            mySawWave.setAmp(0);
            mySineWave.setAmp(0);
            myTriangleWave.setAmp(0);
            mySquareWave.setAmp(1);
            break;
    }//End switch
} 

void stop() {  // Close all sound objects nicely
    myAudioOut.close();
    myMinim.stop();
    super.stop();
}
