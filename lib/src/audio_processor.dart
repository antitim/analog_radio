import 'dart:async';
import 'dart:web_audio';

import 'audio_player.dart';
import 'audio_processor_state.dart';
import 'filter_type.dart';
import 'analog_radio.dart';
import 'radio_node.dart';

/// Gathers all the audio nodes together and gives an external interface for management
class AudioProcessor implements AnalogRadio {
  late AudioContext _audioContext;
  late AudioPlayer _audioPlayer;
  late RadioNode _radioNode;
  late GainNode _gainNode;
  late BiquadFilterNode _filterNode;
  double _signalStrength = 0;
  Timer? _watchingTimer;

  /// Speed of signal level change
  Duration speedLevelChange;

  StreamController<AudioProcessorState> _stateStreamCtrl =
      StreamController<AudioProcessorState>();

  Stream<AudioProcessorState> get state => _stateStreamCtrl.stream;

  AudioProcessor({
    this.speedLevelChange = const Duration(milliseconds: 10),
  }) {
    _audioContext = AudioContext();
    _audioPlayer = AudioPlayer();

    var source = _audioContext.createMediaElementSource(_audioPlayer.element);
    _radioNode = RadioNode(_audioContext);

    _filterNode = _audioContext.createBiquadFilter();
    _filterNode.type = 'allpass';
    _filterNode.frequency?.value = 3500;
    _filterNode.Q?.value = 1.7;

    _gainNode = _audioContext.createGain();

    source.connectNode(_radioNode.node);
    _radioNode.node.connectNode(_filterNode);
    _filterNode.connectNode(_gainNode);
    _gainNode.connectNode(_audioContext.destination!);

    // Playback has started
    _audioPlayer.onPlaying.listen((event) => _dispatchCurrentState());
    // Playback was started
    _audioPlayer.onPlay.listen((event) => _dispatchCurrentState());
  }

  void _dispatchCurrentState() {
    _stateStreamCtrl.add(AudioProcessorState(
      url: url,
      volume: volume,
      signalStrength: signalStrength,
      running: running,
      playing: playing,
    ));
  }

  @override
  void turnOn() async {
    if (running) return;
    await _audioContext.resume();
    if (url != '') {
      _audioPlayer.play(url);
    }
    _startWatching();
    _dispatchCurrentState();
  }

  @override
  void turnOff() async {
    if (!running) return;

    _audioPlayer.stop();
    _stopWatching();
    await _audioContext.suspend();
    _dispatchCurrentState();
    _audioPlayer.src = '';
  }

  @override
  void tune(String url, double signalStrength) {
    this.signalStrength = signalStrength;

    if (_audioContext.state == 'suspended') {
      _audioPlayer.src = url;
      return;
    }
    _audioPlayer.play(url);
  }

  void _startWatching() {
    _watchingTimer = Timer.periodic(speedLevelChange, (_) {
      var diff = (playing ? _signalStrength : 0) - _radioNode.signalStrength;

      if (diff * diff.sign < 0.01) {
        return;
      }

      _radioNode.signalStrength = _radioNode.signalStrength + 0.01 * diff.sign;
      if (_radioNode.signalStrength < 0) _radioNode.signalStrength = 0;
      if (_radioNode.signalStrength > 1) _radioNode.signalStrength = 1;
    });
  }

  void _stopWatching() {
    _watchingTimer?.cancel();
  }

  @override
  set signalStrength(double signalStrength) {
    _signalStrength = signalStrength;
    _dispatchCurrentState();
  }

  @override
  set internalSignalStrength(double signalStrength) {
    _signalStrength = signalStrength;
    _radioNode.signalStrength = signalStrength;
    _dispatchCurrentState();
  }

  @override
  set volume(double value) {
    _gainNode.gain!.value = value;
    _dispatchCurrentState();
  }

  @override
  set filter(FilterType value) {
    switch (value) {
      case FilterType.allpass:
        _filterNode.type = 'allpass';
        break;
      case FilterType.bandpass:
        _filterNode.type = 'bandpass';
        break;
    }

    _dispatchCurrentState();
  }

  @override
  double get signalStrength => _signalStrength;
  @override
  double get internalSignalStrength => _radioNode.signalStrength;
  @override
  double get volume => _gainNode.gain!.value!.toDouble();
  @override
  FilterType get filter {
    switch (_filterNode.type) {
      case 'allpass':
        return FilterType.allpass;
      case 'bandpass':
        return FilterType.bandpass;
      default:
        return FilterType.allpass;
    }
  }

  @override
  bool get playing => _audioPlayer.buffered.length > 0;
  @override
  String get url => _audioPlayer.src;
  @override
  bool get running => _audioContext.state == 'running';
  @override
  void dispose() {
    _audioContext.close();
  }
}
