# :radio: Analog radio emulator

[![pub package](https://img.shields.io/pub/v/analog_radio.svg)](https://pub.dev/packages/analog_radio)
[![Web Demo](https://img.shields.io/badge/Radio-Demo-FFB300.svg)](https://analog-radio-example.web.app/)

## About

This package adds distortion to the online audio stream, so it becomes like a radio receiver.

You can change the signal level so that it can be very weak and there will be a lot of interference.

The AudioContext Api is used. Therefore, it works only in the browser.

[Example](https://analog-radio-example.web.app/)

## Install

```sh
dart pub add analog_radio
```

## Using

```dart
// Creating radio instance. Will be created audiocontext with audio processing.
var radio = AnalogRadio();

// Start playing sound. You will be able to hear the radio noise
radio.turnOn();

// You set up the "radio receiver" for a specific audio stream with a signal level of 0.9.
// You will hear an audio stream with a slight addition of noise and distortion.
radio.tune('https://vip2.fastcast4u.com/proxy/classicrockdoug?mp=/1', 0.9);

// With a signal level of 0.3, the audio stream will be heard very poorly with a high level of interference
radio.tune('https://vip2.fastcast4u.com/proxy/classicrockdoug?mp=/1', 0.3);

// Stop playing sound
radio.turnOff();
```

## Developing

```sh
dart pub global activate webdev
dart pub get
webdev serve --release
```
