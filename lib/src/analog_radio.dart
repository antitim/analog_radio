import 'dart:web_audio';

import 'audio_processor.dart';
import 'audio_processor_state.dart';

/// Emulates analog radio
abstract class AnalogRadio {
  factory AnalogRadio({
    AudioNode Function(AudioContext context)? setCustomNode,
  }) {
    return AudioProcessor(setCustomNode: setCustomNode);
  }

  /// Radio state
  Stream<AudioProcessorState> get state;

  /// Turns on the radio
  void turnOn();

  /// Turns off the radio
  void turnOff();

  /// Adjusts the radio to the [url] stream with the signal strength [signalStrength]. [signalStrength] must be from 0 to 1
  void tune(String url, double signalStrength);

  /// Turns on the frequency change sound
  void tuning();

  /// The current volume. From 0 to 1
  double volume = 1;

  /// Current signal strength. From 0 to 1
  double signalStrength = 1;

  /// Internal signal strength. From 0 to 1
  double internalSignalStrength = 1;

  /// The radio is playing
  bool get playing;

  /// Stream url
  String get url;

  /// The radio is on
  bool get running;

  /// Dispose
  void dispose();
}
