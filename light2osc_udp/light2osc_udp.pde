import netP5.*;
import oscP5.*;
import processing.video.*;

/**
 * Getting Started with Capture.
 * 
 * Reading and displaying an image from an attached Capture device. 
 */


Capture cam;

OscP5 oscP5;
NetAddress addr;


PImage region;
int numRows = 2;
int numCols = 4;
int numIndices;
float[] brightnesses;
float[] features;
int[]   indices;

int seed = 13487;

int camWidth, camHeight;
int camFps = 30;
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

void computeBrightness() {
  float val = 0;  

  // compute average brightness for regions
  for (int i = 0; i < numCols; i++) {
    for (int j = 0; j < numRows; j++) {
      region = cam.get(i * camRegionWidth, j * camRegionHeight, camRegionWidth, camRegionHeight);
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
  }
}

void setup() {
  size(200, 200);

  randomSeed(seed);
  camWidth = 80;
  camHeight = 45;
  oscP5 = new OscP5(this, 12000);
  addr = new NetAddress("127.0.0.1",57110);
  numIndices = numCols * numRows;

  camRegionWidth = camWidth/numCols;
  camRegionHeight = camHeight/numRows;
  dispRegionWidth = width/numCols;
  dispRegionHeight = height/numRows;
  noStroke();
  
  brightnesses = new float[numIndices];
  features   = new float[numIndices];
  indices = new int[numIndices];
  for (int i=0; i<numIndices; i++) {
    indices[i] = i;
  }
  scramble(indices);
  for (int i=0; i<numIndices; i++) {
    println(indices[i]);
  }
  
  String[] cameras = Capture.list();
  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    cam = new Capture(this, 80, 45);
  } if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    printArray(cameras);

    // The camera can be initialized directly using an element
    // from the array returned by list():
    //cam = new Capture(this, cameras[0]);
    // Or, the settings can be defined based on the text in the list
    cam = new Capture(this, camWidth, camHeight, "FaceTime HD Camera", camFps);
    
    // Start capturing the images from the camera
    cam.start();
  }
}

void draw() {
  OscMessage msg = new OscMessage("/c_setn");
  // bus
  msg.add(0);
  msg.add(indices.length);
  
  if (cam.available() == true) {
    cam.read();
  }
  
  computeBrightness();
  featureExtract();
 
  for (int i = 0; i < numCols*numRows; i++) {
      int idx = indices[i];
      //msg.add(pixelsVals[idx]/128 - 1);
      //fill(pixelsVals[idx]);
      msg.add(features[i]/256);
      fill(features[i]/2 + 128);

      rect((i % numCols) * dispRegionWidth, (i / numCols) * dispRegionHeight, dispRegionWidth, dispRegionHeight);
  }
  
  oscP5.send(msg, addr); 
}