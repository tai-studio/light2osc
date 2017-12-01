import netP5.*;
import oscP5.*;
import processing.video.*;

/**
 * light2osc_tcp 

 * 2017, Till Bovermann
 * http://tai-studio.org

 * captures camera data, 
 * transforms it into 8 simple values 
 * (pairwise differential values of the regions),
 * scrambles the regions, and 
 * sends them out via OSC over a TCP connection, 
 * directly to an scsynth process running on 
 * localhost, port 57110.
 * MIT License
 */


 Capture cam;

 OscP5 oscP5;
 NetAddress addr;


 PImage region;
 int numRows = 1;
 int numCols = 8;
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
  size(800, 200);

  randomSeed(seed);
  
  oscP5 = new OscP5(this, "127.0.0.1", 57110, OscP5.TCP);
  oscP5.send("/notify", new Object[] {new Integer(1)});


  numIndices = numCols * numRows;

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
  
  // debug
  //for (int i=0; i<numIndices; i++) {
  //  println(indices[i]);
  //}

  // camera names in order of importance
  // aim for fastest fps with smallest amount of pixels 
  // prefer external cams
  String[] cameraNames = {
    "name=HD Pro Webcam C920,size=240x135,fps=30",
    "name=HD Pro Webcam C920 #2,size=240x135,fps=30",
    "name=FaceTime HD Camera,size=80x45,fps=30"
  };
  
  String[] cameras = Capture.list();
  if (cameras == null) {
    println("Failed to retrieve the list of available cameras.");
  } else if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    printArray(cameras);
    println("--------------------------------");
  }
  
  for (int i=0; i<cameraNames.length; i++) {
    try {
      print("trying ");
      println(cameraNames[i]);
      cam = new Capture(this, cameraNames[i]);
      cam.start();
      //String[] elems = "name=HD Pro Webcam C920,size=240x135,fps=30"
      String[] elems = split(cameraNames[i], ',');
      String[] dimensions = split(split(elems[1], '=')[1], 'x');
      camWidth = int(dimensions[0]);
      camHeight = int(dimensions[1]);
      camFps = int(split(elems[2], '=')[1]);
   
      //// debug
      //println(camWidth);
      //println(camHeight);
      //println(camFps);
      
      break;
    } catch (Exception e) {
      println("... not connected.");
      
      // clean up
      cam.stop();
      cam = null;
    }
  } // rof
  
  if(cam == null) { // no cam found
    println("no known cam config connected, using default cam. For optimal performance, add preferred config string to 'cameraNames' array.");
    // quick fix: use element from the array returned by list():
    //cam = new Capture(this, cameras[24]);
    //camWidth = 720;
    //camHeight = 640;
    //camFps = 30;
    cam = new Capture(this, camWidth, camHeight);
    camWidth = 720;
    camHeight = 640;
    camFps = 30;
    cam.start();
  }

  camRegionWidth = camWidth/numCols;
  camRegionHeight = camHeight/numRows;
}

void sendMsg() {
  OscMessage msg = new OscMessage("/c_setn");
  // bus
  msg.add(0);
  msg.add(indices.length);

  for (int i = 0; i < numCols*numRows; i++) {
      // int idx = indices[i];
      //msg.add(pixelsVals[idx]/128 - 1);
      //fill(pixelsVals[idx]);
      msg.add(features[i]/256);
  }
  // oscP5.send(msg, c);   
  oscP5.send(msg);
}

void draw() {

  if (cam.available() == true) {
    cam.read();
  }

  computeBrightness();
  featureExtract();
  sendMsg();

  for (int i = 0; i < numCols*numRows; i++) {
    int idx = indices[i];
    //msg.add(pixelsVals[idx]/128 - 1);
    //fill(pixelsVals[idx]);
    //msg.add(features[i]/256);
    fill(features[i]/2 + 128);
  
    rect((i % numCols) * dispRegionWidth, (i / numCols) * dispRegionHeight, dispRegionWidth, dispRegionHeight);
  }
}