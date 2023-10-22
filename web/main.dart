import 'dart:html';
import 'dart:math';
import 'dart:typed_data';
import 'dart:web_audio';

import 'package:analog_radio/analog_radio.dart';

import 'ui/station.dart';
import 'ui/stations.dart';

void main() async {
  var $volume = document.querySelector('.volume') as RangeInputElement;
  var $freq = document.querySelector('.freq') as RangeInputElement;
  var $freqValue = document.querySelector('.frequency-value') as Element;
  var $stations = document.querySelector('.stations') as TextAreaElement;
  var $visual = document.getElementById('visual') as CanvasElement;
  late AnalyserNode analyser;

  var radio = AnalogRadio(setCustomNode: (context) {
    analyser = context.createAnalyser();
    return analyser;
  });
  var stations = Stations();

  $freq.setAttribute('min', stations.frequencyMin);
  $freq.setAttribute('max', stations.frequencyMax);

  var freqHandler = (Event? event) {
    $freqValue.innerText = $freq.value!;
    var freq = int.tryParse($freq.value!) ?? 0;
    var station = stations.getStationByFreq(freq);

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
  };

  var volumeHandler = (Event event) {
    var val = double.parse((event.target as InputElement).value!);
    if (val == -30) {
      radio.turnOff();
    } else {
      radio.turnOn();
    }
    radio.volume = pow(10, (val / 20)).toDouble();
  };

  void drawStationsFrequency(List<Station> stations) {
    var $freq = document.querySelector('.freq') as RangeInputElement;
    var $stationsFrequency =
        document.querySelector('.stations-frequency') as Element;
    $stationsFrequency.innerHtml = '';

    stations.forEach((i) {
      var $a = document.createElement('a');
      $a.innerText = '${i.freq} kHz';
      $a.setAttribute('href', '#${i.freq}');
      $a.onClick.listen((event) {
        $freq.value = i.freq.toString();
        freqHandler(null);
      });

      $stationsFrequency.append($a);
      $stationsFrequency.append(document.createElement('br'));
    });
  }

  var stationsChangeHandler = (Event event) {
    stations.updateStations($stations.value!.split('\n'));
    drawStationsFrequency(stations.stations);
  };

  $volume.value = '-30';

  var initialFreq = window.location.hash.replaceAll('#', '');

  if (initialFreq != '') {
    $freq.value = initialFreq;
  }

  freqHandler(null);

  $stations.value = stations.stations.map((i) => i.url).join('\n');
  drawStationsFrequency(stations.stations);

  $volume.onInput.listen(volumeHandler);
  $freq.onInput.listen(freqHandler);
  $stations.onChange.listen(stationsChangeHandler);

  // Draw visualization
  var WIDTH = 600;
  var HEIGHT = 200;
  analyser.fftSize = 2048;
  var ctx = $visual.getContext('2d') as CanvasRenderingContext2D;
  ctx.clearRect(0, 0, WIDTH, HEIGHT);
  var bufferLength = analyser.frequencyBinCount;
  var dataArray = Uint8List(bufferLength!);

  void drawVisual(_) {
    analyser.getByteTimeDomainData(dataArray);
    ctx.fillStyle = "rgb(33, 33, 33)";
    ctx.fillRect(0, 0, WIDTH, HEIGHT);
    ctx.lineWidth = 2;
    ctx.strokeStyle = "rgb(220, 220, 220)";
    ctx.beginPath();
    var sliceWidth = WIDTH / bufferLength;
    double x = 0;

    for (var i = 0; i < bufferLength; i++) {
      var v = dataArray[i] / 128.0;
      var y = HEIGHT - v * (HEIGHT / 2);

      if (i == 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }

      x += sliceWidth;
    }

    ctx.lineTo(WIDTH, HEIGHT / 2);
    ctx.stroke();

    window.requestAnimationFrame(drawVisual);
  }

  window.requestAnimationFrame(drawVisual);
}
