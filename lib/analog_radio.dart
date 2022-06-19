import 'audio_processor.dart';
import 'audio_processor_state.dart';
import 'filter_type.dart';

/// Emulates analog radio
abstract class AnalogRadio {
  factory AnalogRadio() {
    return AudioProcessor();
  }

  /// Radio state
  Stream<AudioProcessorState> get state;

  /// Turns on the radio
  void turnOn();

  /// Turns off the radio
  void turnOff();

  /// Adjusts the radio to the [url] stream with the signal strength [signalStrength]. [signalStrength] must be from 0 to 1
  void tune(String url, double signalStrength);

  /// The current volume. From 0 to 1
  double volume = 1;

  /// Current signal strength. From 0 to 1
  double signalStrength = 1;

  /// Internal signal strength. From 0 to 1
  double internalSignalStrength = 1;

  /// Applied filter
  FilterType filter = FilterType.allpass;

  /// The radio is playing
  bool get playing;

  /// Stream url
  String get url;

  /// The radio is on
  bool get running;
}
