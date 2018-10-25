## light2osc
2017, 2018 — Till Bovermann

Use a camera as a light sensor array.
Configured for use with [SuperCollider](http://supercollider.github.io)'s' `scsynth`, writing directly to its first control buses.

### Functionality


`light2osc` samples the incoming video into equal sized rects, computes their brightness, calculates difference values between two areas, crambles them,[^1] and spits them out as an OSC message. 


In short:

 * capture camera data, 
 * read out averages values within regions,
 * scramble regions,
 * calculate pairwise differential values, and
 * send values to `scsynth` process (localhost, port 57110) via OSC over TCP/UDP.

### Variants

+ `light2osc_udp` — uses GStreamer, should work with most webcams (except PS3 Eye) on most operating systems, sends data as UDP
+ `light2osc_tcp` — uses GStreamer, should work with most webcams (except PS3 Eye) on most operating systems, sends data as TCP (rarely used)
+ `light2osc_udp_psEye` – uses libusb implementation specific for PS3 Eye cameras. Works with multiple cameras (tested with upto 12)

### Install

+ Install [Processing3](http://processing.org/)
+ Install `OscP5` from wihtin Processing (`Sketch>Import Library...>Add Library...`)

For `light2osc_udp`  and `light2osc_tcp`

+ Install `Video` from wihtin Processing (`Sketch>Import Library...>Add Library...`)

For `light2osc_udp_psEye`

+ Install `ps3eye` from wihtin Processing (`Sketch>Import Library...>Add Library...`)


#### Linux

For `light2osc_udp`  and `light2osc_tcp` it is necessary to install `gstreamer`
    ```$ sudo apt-get install gstreamer0.10 libgstreamer-plugins-base0.10-dev```

For `light2osc_udp_psEye` it is necessary to 

+ install `libusb` (should be installed anyway).
+ remove the [driver module](https://lwn.net/Articles/308358/) (for the OmniVision OV534 USB bridge chip).
After (re-)plugging your camera(s), remove the module with 
    ```
    $ sudo rmmod gspca_ov534 
    ```

### Troubleshooting

If the default camera selection does not work and you don't get any values when running the program, copy the desired camera config string from the printed list and paste it as the first element to the `cameraNames` array:

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
See the calculated values popping up in scsynth by running

```sc
s.boot;
s.scope(8, 0, rate: \control);
```

Use them e.g. via

```sc
{Splay.ar(SinOsc.ar(200 + (100 * In.kr(0, 4))))}
```


#### `light2osc_udp`  and `light2osc_tcp`

Depending whether you are using `UDP` or `TCP` as the OSC base protocol, run the appropriate script derivate. If you don't know which one to use, it is very likely the `udp` variant.

The scripts are configured to work with camera configurations manually named in the scripts themselves. If it does not find any of those cameras, it uses the default camera. 
You can optimise the program by adding your cam config to the variable `cameraNames`.
By running the scripts, you also get a list of available Cameras, copy/paste the string that has your camera with the lowest resolution and highest FPS.


[^1]: With some programming skill, you should be able to remove the difference computation and/or scrambling, however it proofed sensual to use difference values instead of absolute values: Processing's camera capture routine does automatic exposure compensation: seemingly "absolute" values are not absolute anyhow and differences mean a more stable result in shifting light situations.
