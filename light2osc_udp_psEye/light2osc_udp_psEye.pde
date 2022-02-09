import netP5.*;
import oscP5.*;
// import processing.video.*;

import com.thomasdiewald.ps3eye.PS3EyeP5;
import com.thomasdiewald.ps3eye.PS3Eye;

/**
 * light2osc_udp 
 * PSEYE version

 * 2017, 2018 Till Bovermann
 * http://tai-studio.org

 * captures camera data, 
 * transforms it into a few simple values 
 * (pairwise differential values of regions),
 * scrambles the regions, and 
 * sends them out via OSC over a UDP connection, 
 * directly to an scsynth process running on 
 * localhost, port 57110.
 * MIT License
 */


// cameras
int numCams = 1;
//int fps = 100; // see possible fps/resolution values below
//int fps = 50; // see possible fps/resolution values below
int fps = 25; // see possible fps/resolution values below
boolean isVGA = false; // else QVGA
PS3EyeP5[] cams;


// network
OscP5 oscP5;
NetAddress addr;


PImage region;
int numRows = 8;
int numCols = 8;
int numIndices;
float[] brightnesses;
float[] features;
int[]   indices;

int seed = 13487;

int camWidth, camHeight;
int camFps;
String camName;
//int camFps = 15;
int camRegionWidth, camRegionHeight;
int dispRegionWidth, dispRegionHeight;

void scramble(int[] array){
  int i, j, k, m, tmp;
  k = array.length;
  for (i=0, m=k; i<k-1; ++i, --m) {
    j = i + int(random(m));

    // swap elements;
    tmp = array[i];
    array[i] = array[j];
    array[j] = tmp;
  }
}

void computeBrightness(PImage img) {
  float val = 0;  

  // compute average brightness for regions
  for (int i = 0; i < numCols; i++) {
    for (int j = 0; j < numRows; j++) {
      region = img.get(i * camRegionWidth, j * camRegionHeight, camRegionWidth, camRegionHeight);
      region.loadPixels();
      val = 0.0;
      for (int k = 0; k < camRegionWidth * camRegionHeight; k++){
        val += brightness(region.pixels[k]);
      }
      brightnesses[i + j*numCols] = val / (camRegionWidth * camRegionHeight);
    }
  }
}

void featureExtract() {
  for (int i = 0; i < numIndices; i++) {
      features[i] = brightnesses[indices[i]] - brightnesses[indices[(i+1) % numIndices]];
//      features[i] = brightnesses[indices[i]];
//      features[i] = brightnesses[i];
  }
}

public void settings(){
  size(300, 150);
}

void setup() {

  randomSeed(seed);

  // network
  oscP5 = new OscP5(this, 12000);
  addr = new NetAddress("127.0.0.1",57110);
  //addr = new NetAddress("194.95.203.247",57110);

  // indexing and graphics
  numIndices = numCols * numRows;
  dispRegionWidth = width/numCols;
  dispRegionHeight = height/numRows/numCams;
  noStroke();
  
  brightnesses = new float[numIndices];
  features   = new float[numIndices];
  indices = new int[numIndices];
  for (int i=0; i<numIndices; i++) {
    indices[i] = i;
  }
  scramble(indices);

  // set up cameras
  cams = new PS3EyeP5[numCams];
 
  for (int i = 0; i < numCams; ++i) {
    cams[i] = PS3EyeP5.getDevice(this, i);
    if (isVGA) {
      camWidth = 640;
      camHeight = 480;
      cams[i].init(fps, PS3Eye.Resolution.VGA);
    } else {
      camWidth = 320;
      camHeight = 240;
      cams[i].init(fps, PS3Eye.Resolution.QVGA);
    }

    if(cams[i] == null){
      System.out.println("Not enough PS3Eyes connected. Good Bye!");
      exit();
      return;
    }
    cams[i].setAutogain(true);
    cams[i].setContrast(128);
    //cams[i].setGain(63);
    //cams[i].setExposure(100);
    cams[i].start();
    // if "false" Processing/PS3Eye frameRates are not "synchronized".
    // default value is "true".
    cams[i].waitAvailable(false); 
  };
  frameRate(500);


  camRegionWidth = camWidth/numCols;
  camRegionHeight = camHeight/numRows;
}

void draw() {
  for (int i = 0; i < numCams; ++i) {
    if(cams[i].isAvailable()){

      // get values
      computeBrightness(cams[i].getFrame());
      featureExtract();

      // prepare OSC message
      OscMessage msg = new OscMessage("/c_setn");
      // start bus
      msg.add(numRows * numCols * i);
      // length
      msg.add(indices.length);
 
       // fill OSC Msg and draw
      for (int j = 0; j < numCols*numRows; j++) {
          int idx = indices[j];
      //msg.add(pixelsVals[idx]/128 - 1);
      //fill(pixelsVals[idx]);
          msg.add(features[j]/256 * 2);
          fill(features[j]/2 + 128);

          rect(
            (j % numCols) * dispRegionWidth, 
            (dispRegionHeight * i * numRows) + ((j / numCols) * dispRegionHeight), 
            dispRegionWidth, 
            dispRegionHeight
          );
      };
  
      // send OSC Msg
      oscP5.send(msg, addr); 
    };
  };
}

/*
QVGA
  2
  3
  5
  7
  10
  12
  15
  17
  30
  37
  40
  50
  60
  75
  90
  100
  125
  137
  150
  187

VGA
  2
  3
  5
  8
  10
  15
  20
  25
  30
  40
  50
  60
  75
*/
