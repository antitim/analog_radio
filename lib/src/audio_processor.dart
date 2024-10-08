import 'dart:async';
import 'dart:web_audio';

import 'analog_radio.dart';
import 'audio_player.dart';
import 'audio_processor_state.dart';
import 'radio_node.dart';

/// Gathers all the audio nodes together
/// and gives an external interface for management
class AudioProcessor implements AnalogRadio {
  AudioProcessor({
    this.speedLevelChange = const Duration(milliseconds: 10),
    this.setCustomNode,
  }) {
    _audioContext = AudioContext();
    _audioPlayer = AudioPlayer();

    final source = _audioContext.createMediaElementSource(_audioPlayer.element);
    _radioNode = RadioNode(_audioContext);

    _gainNode = _audioContext.createGain();

    _preGainNode = _audioContext.createGain();
    _preGainNode.gain?.value = 1.8;

    source.connectNode(_preGainNode);
    _preGainNode.connectNode(_radioNode.node);
    _radioNode.node.connectNode(_gainNode);

    if (setCustomNode != null) {
      final customNode = setCustomNode!(_audioContext);
      _gainNode.connectNode(customNode);
      customNode.connectNode(_audioContext.destination!);
    } else {
      _gainNode.connectNode(_audioContext.destination!);
    }

    // Playback has started
    _audioPlayer.onPlaying.listen((final event) => _dispatchCurrentState());
    // Playback was started
    _audioPlayer.onPlay.listen((final event) => _dispatchCurrentState());
  }

  late AudioContext _audioContext;
  late AudioPlayer _audioPlayer;
  late RadioNode _radioNode;
  late GainNode _preGainNode;
  late GainNode _gainNode;
  double _signalStrength = 0;
  Timer? _watchingTimer;

  /// Speed of signal level change
  Duration speedLevelChange;

  /// Adding custom audio node
  AudioNode Function(AudioContext context)? setCustomNode;

  final StreamController<AudioProcessorState> _stateStreamCtrl =
      StreamController<AudioProcessorState>();

  @override
  Stream<AudioProcessorState> get state => _stateStreamCtrl.stream;

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
  Future<void> turnOn() async {
    if (running) return;
    await _audioContext.resume();
    _startWatching();
    if (url != '') {
      await _audioPlayer.play(url);
    }
    _dispatchCurrentState();
  }

  @override
  Future<void> turnOff() async {
    if (!running) return;

    _audioPlayer.stop();
    _stopWatching();
    await _audioContext.suspend();
    _dispatchCurrentState();
    _audioPlayer.src = '';
  }

  @override
  Future<void> tune(final String url, final double signalStrength) async {
    this.signalStrength = signalStrength;

    if (_audioContext.state == 'suspended') {
      _audioPlayer.src = url;
      return;
    }
    await _audioPlayer.play(url);
  }

  @override
  void tuning() {
    _radioNode.resetNoise();
  }

  void _startWatching() {
    _watchingTimer = Timer.periodic(speedLevelChange, (final _) {
      final diff = (playing ? _signalStrength : 0) - _radioNode.signalStrength;

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
  set signalStrength(final double signalStrength) {
    _signalStrength = signalStrength;
    _dispatchCurrentState();
  }

  @override
  set internalSignalStrength(final double signalStrength) {
    _signalStrength = signalStrength;
    _radioNode.signalStrength = signalStrength;
    _dispatchCurrentState();
  }

  @override
  set volume(final double value) {
    _gainNode.gain!.value = value;
    _dispatchCurrentState();
  }

  @override
  double get signalStrength => _signalStrength;
  @override
  double get internalSignalStrength => _radioNode.signalStrength;
  @override
  double get volume => _gainNode.gain!.value!.toDouble();
  @override
  bool get playing => _audioPlayer.buffered.length > 0;
  @override
  String get url => _audioPlayer.src;
  @override
  bool get running => _audioContext.state == 'running';
  @override
  void dispose() {
    unawaited(_audioContext.close());
  }
}
