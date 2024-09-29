import 'dart:html';
import 'dart:math';
import 'dart:typed_data';
import 'dart:web_audio';

import 'package:analog_radio/analog_radio.dart';

import 'ui/station.dart';
import 'ui/stations.dart';

void main() async {
  final $volume = document.querySelector('.volume') as RangeInputElement;
  final $freq = document.querySelector('.freq') as RangeInputElement;
  final $freqValue = document.querySelector('.frequency-value') as Element;
  final $stations = document.querySelector('.stations') as TextAreaElement;
  final $visual = document.getElementById('visual') as CanvasElement;
  late AnalyserNode analyser;

  final radio = AnalogRadio(setCustomNode: (final context) {
    analyser = context.createAnalyser();
    return analyser;
  });
  final stations = Stations();

  $freq.setAttribute('min', stations.frequencyMin);
  $freq.setAttribute('max', stations.frequencyMax);

  void freqHandler(final Event? event) {
    $freqValue.innerText = $freq.value!;
    final freq = int.tryParse($freq.value!) ?? 0;
    final station = stations.getStationByFreq(freq);

    radio.tuning();

    if (station == null) {
      radio.signalStrength = 0;
      radio.internalSignalStrength = 0;
    } else if (station.url == radio.url) {
      radio.signalStrength = station.signalStrength;
      if (radio.playing) {
        radio.internalSignalStrength = station.signalStrength;
      }
    } else {
      radio.tune(station.url, station.signalStrength);
    }
  }

  void volumeHandler(final Event event) {
    final val = double.parse((event.target as InputElement).value!);
    if (val == -30) {
      radio.turnOff();
    } else {
      radio.turnOn();
    }
    radio.volume = pow(10, val / 20).toDouble();
  }

  void drawStationsFrequency(final List<Station> stations) {
    final $freq = document.querySelector('.freq') as RangeInputElement;
    final $stationsFrequency =
        document.querySelector('.stations-frequency') as Element;
    $stationsFrequency.innerHtml = '';

    for (final i in stations) {
      final $a = document.createElement('a');
      $a.innerText = '${i.freq} kHz';
      $a.setAttribute('href', '#${i.freq}');
      $a.onClick.listen((final event) {
        $freq.value = i.freq.toString();
        freqHandler(null);
      });

      $stationsFrequency.append($a);
      $stationsFrequency.append(document.createElement('br'));
    }
  }

  void stationsChangeHandler(final Event event) {
    stations.updateStations($stations.value!.split('\n'));
    drawStationsFrequency(stations.stations);
  }

  $volume.value = '-30';

  final initialFreq = window.location.hash.replaceAll('#', '');

  if (initialFreq != '') {
    $freq.value = initialFreq;
  }

  freqHandler(null);

  $stations.value = stations.stations.map((final i) => i.url).join('\n');
  drawStationsFrequency(stations.stations);

  $volume.onInput.listen(volumeHandler);
  $freq.onInput.listen(freqHandler);
  $stations.onChange.listen(stationsChangeHandler);

  // Draw visualization
  final width = 600;
  final height = 200;
  analyser.fftSize = 2048;
  final ctx = $visual.getContext('2d') as CanvasRenderingContext2D;
  ctx.clearRect(0, 0, width, height);
  final bufferLength = analyser.frequencyBinCount;
  final dataArray = Uint8List(bufferLength!);

  void drawVisual(final _) {
    analyser.getByteTimeDomainData(dataArray);
    ctx.fillStyle = 'rgb(33, 33, 33)';
    ctx.fillRect(0, 0, width, height);
    ctx.lineWidth = 2;
    ctx.strokeStyle = 'rgb(220, 220, 220)';
    ctx.beginPath();
    final sliceWidth = width / bufferLength;
    var x = 0.0;

    for (var i = 0; i < bufferLength; i++) {
      final v = dataArray[i] / 128.0;
      final y = height - v * (height / 2);

      if (i == 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }

      x += sliceWidth;
    }

    ctx.lineTo(width, height / 2);
    ctx.stroke();

    window.requestAnimationFrame(drawVisual);
  }

  window.requestAnimationFrame(drawVisual);
}
