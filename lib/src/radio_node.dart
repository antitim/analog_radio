import 'dart:math';
import 'dart:web_audio';

class RadioNode {
  ScriptProcessorNode _node;
  final Random _random = Random(10);
  double signalStrength = 0;
  int _sawWaveI = 0;
  int _sawWave2I = 0;
  int _freq = 600;
  int _freq2 = 62;
  double _sawVolume1 = 0.25;
  double _sawVolume2 = 0.1;

  int _waveI = 0;
  int _period = 600000;

  RadioNode(AudioContext ctx) : _node = ctx.createScriptProcessor(1024, 2, 2) {
    _node.onAudioProcess.listen(onAudioProcessHandler);
  }

  AudioNode get node => _node;

  double _getNoise() {
    double signalStrengthRelative = pow(signalStrength, 1 / 2.5).toDouble();

    var rnd = _random.nextDouble() * 2 - 1;
    var noise = rnd * (1 - signalStrengthRelative) / 6;

    return noise;
  }

  double _cutSignal(double signal) {
    double signalStrengthRelative = pow(signalStrength, 1 / 2.5).toDouble();

    signal = signal + 1;
    var maxSignalStrength = signalStrengthRelative * 1.4;

    if (signal > maxSignalStrength) signal = maxSignalStrength;

    return signal - 1;
  }

  double _addNoise(double signal) {
    signal = signal + _getNoise();
    return signal;
  }

  double _addSawWave(double signal) {
    if (signalStrength == 1) return signal;

    if (_waveI > _period) {
      _freq = 200 + (_random.nextDouble() * 200).toInt();
      _period = 200000 + (_random.nextDouble() * 900000).toInt();
      _waveI = 0;
    }

    if (_waveI > 3000) {
      _freq = _freq + ((_random.nextDouble() - 0.5) * 10).toInt();
      if (_freq < 500) _freq = 500;
      if (_freq > 700) _freq = 700;
      _waveI = 0;
    }

    if (_waveI < _period) {
      _sawVolume1 = _sawVolume1 + (_random.nextDouble() - 0.5) / 1000;
    } else {
      _waveI = 0;
    }

    signal = signal + (_sawWaveI / _freq) * (1 - signalStrength) * _sawVolume1;
    if (_sawWaveI > _freq) _sawWaveI = 0;

    signal =
        signal + (_sawWave2I / _freq2) * (1 - signalStrength) * _sawVolume2;
    if (_sawWave2I > _freq2) _sawWave2I = 0;

    _sawWaveI++;
    _sawWave2I++;

    return signal;
  }

  double _changeSignal(double signal) {
    signal = _cutSignal(signal);
    signal = _addNoise(signal);
    signal = _addSawWave(signal);

    if (signal > 1) signal = 1;
    if (signal < -1) signal = -1;

    return signal;
  }

  void onAudioProcessHandler(AudioProcessingEvent event) {
    var inputBuffer = event.inputBuffer;
    var outputBuffer = event.outputBuffer;

    for (var ch = 0; ch < outputBuffer!.numberOfChannels!; ch++) {
      var inputData =
          inputBuffer!.getChannelData(signalStrength < 0.4 ? 0 : ch);
      var outputData = outputBuffer.getChannelData(ch);

      for (var sampleIdx = 0; sampleIdx < inputBuffer.length!; sampleIdx++) {
        outputData[sampleIdx] = _changeSignal(inputData[sampleIdx]);
      }
    }
  }
}
