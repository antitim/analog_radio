import 'dart:html';

/// Wrapper on browser AudioElement
class AudioPlayer {
  AudioPlayer() : element = AudioElement() {
    prepareAudioElement(element);
  }
  AudioElement element;
  String _src = '';

  void prepareAudioElement(final AudioElement audioElement) {
    audioElement.setAttribute('crossorigin', 'anonymous');
  }

  ElementStream<Event> get onPlay => element.onPlay;
  ElementStream<Event> get onPlaying => element.onPlaying;
  TimeRanges get buffered => element.buffered;

  String get src => _src;
  set src(final String value) {
    _src = value;
    element.src = value;
  }

  /// Play the audio stream at [url] in the browser
  Future<void> play(final String url) async {
    _src = url;
    element.src = url;

    try {
      await element.play();
    } on DomException catch (err) {
      if (err.name == 'NotSupportedError') {
        rethrow;
      }

      // The error (AbortError) occurs when the player is decided to stop,
      // while it hasn't had time to start yet
      // https://developers.google.com/web/updates/2017/06/play-request-was-interrupted
      // We can't fix it right now.
      // Because then we will have to wait for the stream to load,
      // and this is not good for the user.
      // The stream may never load at all.
      // ignore: avoid_print
      print('DomException: $err');
    }
  }

  /// Stop playback
  void stop() {
    if (element.paused) return;
    if (element.src == '') return;

    element.pause();
    element.src = '';
  }
}
