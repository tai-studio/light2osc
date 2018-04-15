## light2osc
2017, Till Bovermann

Use a camera as a light sensor array.
Configured for use with [SuperCollider](http://supercollider.github.io)'s' `scsynth`, writing directly to its first control buses.

### Functionality


`light2osc` samples the incoming video into equal sized rects, computes their brightness, calculates difference values between two areas, and spits them out as an OSC message. 

If you don't like it, you can easily remove the difference computation, however it proofed sensual to use those instead of absolute values: Processing's camera capture routine does automatic exposure compensation; seemingly "absolute" values are not absolute anyhow.

In short:

 * capture camera data, 
 * read out averages values within regions,
 * scramble regions,
 * calculate pairwise differential values, and
 * send values to `scsynth` process (localhost, port 57110) via OSC over TCP/UDP.


### Install

+ Install [Processing3](http://processing.org/)
+ Install libraries `OscP5` and `Video` from wihtin Processing (`Sketch>Import Library...>Add Library...`)

#### Linux

1. It seems to be necessary to install gstreamer

    ```$ sudo apt-get install gstreamer0.10 libgstreamer-plugins-base0.10-dev```
2. The default camera detection does not work. If you don't get any values when running the program, copy the desired camera config string from the printed list and paste it as the first element to the `cameraNames` array:

    ```
    String[] cameraNames = {
      "name=/dev/video0,size=160x120,fps=30", // linux gstreamer device
      "name=HD Pro Webcam C920,size=240x135,fps=30",
      "name=HD Pro Webcam C920 #2,size=240x135,fps=30",
      "name=FaceTime HD Camera,size=80x45,fps=30"
    };
    ```

### Usage

The scripts write directly to the first control buses of an `scsynth` process running at port `57110`.

Depending whether you are using `UDP` or `TCP` as the OSC base protocol, run the appropriate script derivate. If you don't know, then it is very likely you want the `udp` variant.

The scripts are configured to work with camera configurations manually named in the scripts itself. If it does not find any of those cameras, it uses the default camera. 
You can optimise it by adding your cam config to the variable `cameraNames`.
By running the script you get a list of available Cameras, copy/paste the string that has your camera with the lowest resolution and highest FPS.

See the calculated values popping up in scsynth by running

```sclang
s.boot;
s.scope(8, 0, rate: \control);
```

Use them e.g. via

```sclang
{Splay.ar(SinOsc.ar(200 + (100 * In.kr(0, 4))))}
```
