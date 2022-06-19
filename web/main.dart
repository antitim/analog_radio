import 'dart:html';

import 'package:analog_radio/analog_radio.dart';

import 'ui/station.dart';
import 'ui/stations.dart';

void main() async {
  var $volume = document.querySelector('.volume') as RangeInputElement;
  var $freq = document.querySelector('.freq') as RangeInputElement;
  var $freqValue = document.querySelector('.frequency-value') as Element;
  var $stations = document.querySelector('.stations') as TextAreaElement;

  var radio = AnalogRadio();
  var stations = Stations();

  $freq.setAttribute('min', stations.frequencyMin);
  $freq.setAttribute('max', stations.frequencyMax);

  var freqHandler = (Event? event) {
    $freqValue.innerText = $freq.value!;
    var freq = int.tryParse($freq.value!) ?? 0;
    var station = stations.getStationByFreq(freq);

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
    if (val == 0) {
      radio.turnOff();
    } else {
      radio.turnOn();
    }
    radio.volume = val;
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

  $volume.value = '0';

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
}
