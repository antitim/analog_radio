import 'dart:math';
import 'dart:web_audio';

class RadioNode {
  ScriptProcessorNode _node;
  final Random _random = Random(10);

  /// From 0 to 1
  double signalStrength = 0;

  // For saw wave
  int _sawWaveI = 0;
  int _sawWave2I = 0;
  int _freq = 600;
  int _freq2 = 62;
  double _sawVolume1 = 0.2;
  double _sawVolume2 = 0.4;

  // For pink noise
  double _b0 = 0;
  double _b1 = 0;
  double _b2 = 0;
  double _b3 = 0;
  double _b4 = 0;
  double _b5 = 0;
  double _b6 = 0;

  resetNoise() {
    _sawWaveI = _random.nextInt(_freq);
    _sawWave2I = _random.nextInt(_freq2);
    _sawVolume1 = _random.nextDouble() / 5;
    _sawVolume2 = _random.nextDouble();

    _b0 = _random.nextDouble();
    _b1 = _random.nextDouble();
    _b2 = _random.nextDouble();
    _b3 = _random.nextDouble();
    _b4 = _random.nextDouble();
    _b5 = _random.nextDouble();
    _b6 = _random.nextDouble();
  }

  RadioNode(AudioContext ctx) : _node = ctx.createScriptProcessor(4096, 2, 2) {
    _node.onAudioProcess.listen(onAudioProcessHandler);
  }

  AudioNode get node => _node;

  double _cutSignal(double signal) {
    var signalStrengthRelative = pow(signalStrength, 0.6);
    var maxSignalStrength = (signalStrengthRelative - 0.5) * 2;
    if (signal > maxSignalStrength) signal = maxSignalStrength;

    var waveShift = (1 - maxSignalStrength) / 2;

    return signal + waveShift;
  }

  /// https://www.firstpr.com.au/dsp/pink-noise/
  double _addPinkNoise(double signal) {
    var signalStrengthRelative = pow(signalStrength, 0.4);

    var white = _random.nextDouble() * 2 - 1;
    _b0 = 0.99886 * _b0 + white * 0.0555179;
    _b1 = 0.99332 * _b1 + white * 0.0750759;
    _b2 = 0.96900 * _b2 + white * 0.1538520;
    _b3 = 0.86650 * _b3 + white * 0.3104856;
    _b4 = 0.55000 * _b4 + white * 0.5329522;
    _b5 = -0.7616 * _b5 - white * 0.0168980;
    var pink = _b0 + _b1 + _b2 + _b3 + _b4 + _b5 + _b6 + white * 0.5362;
    pink *= 0.24;
    _b6 = white * 0.115926;

    var crackle = 0.0;
    var crackleFrom = 0.8; // For 0 signalStrength
    var crackleTo = 1.4; // For 1 signalStrength

    var pinkNoiseGateLevel =
        signalStrength * (crackleTo - crackleFrom) + crackleFrom;

    if (pink.abs() > pinkNoiseGateLevel) {
      crackle = pink;
    }

    return signal + pink * (1 - signalStrengthRelative) + crackle;
  }

  double _addSawWave(double signal) {
    if (signalStrength == 1) return signal;

    _sawVolume1 = _sawVolume1 + (_random.nextDouble() - 0.5) * 0.002;

    if (_sawVolume1 > 1 || _sawVolume1 < -1) {
      _sawVolume1 = 0;
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
    signal = _addPinkNoise(signal);
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
