class AudioProcessorState {
  const AudioProcessorState({
    required this.url,
    required this.volume,
    required this.signalStrength,
    required this.running,
    required this.playing,
  });

  final String? url;
  final double volume;
  final double signalStrength;
  final bool running;
  final bool playing;

  @override
  String toString() {
    return 'Url: $url, Volume: $volume, Signal Strength: $signalStrength, '
        'Running: $running, Playing: $playing';
  }
}
