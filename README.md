## light2osc
2017, Till Bovermann

simple script to use a camera as a simple light sensor.
It comes configured for use with the [SuperCollider] scsynth and writes directly to the first control buses.

### Install

+ Install [Processing3](http://processing.org/)
+ Install libraries OscP5 and Camera from wihtin Processing


### Usage

The scripts write directly to the first control buses of an scsynth running at port `57110`.

Depending whether you are using `UDP` or `TCP` as the OSC base protocol, run the appropriate script derivate. If you don't know, then it is very likely you want the `udp` variant.

The scripts are configured to work with my camera in its lowest resolution and highest framerate. If you have a different camera, you need to adjust the settings accordingly. Choose the lowest resolution and highest framerate for your camera.

See the calculated values popping up in scsynth by running

```sclang
s.boot;
s.scope(8, 0, rate: \control);
```

Use them e.g. via

```sclang
{Splay.ar(SinOsc.ar(200 + (100 * In.kr(0, 4)))}
```


### What it does

`light2osc` samples the incoming video into equal sized rects, computes their brightness, computes difference values between two areas, and spits them out as an OSC message. It is simple to remove the difference computation but for me it proofed sensual to use those instead of absolute values since the camera anyhow does automatic exposure compensation, so absolute values are not absolute anyhow.