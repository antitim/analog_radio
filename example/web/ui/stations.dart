import 'dart:html';

import 'station.dart';
import 'tuned_station.dart';

class Stations {
  final frequencyMin = 520;
  final frequencyMax = 1710;
  final int sideWidth = 7;
  List<Station> stations = [];

  int get frequencyRangeLength => frequencyMax - frequencyMin;

  Stations() {
    var lsStations = window.localStorage['stations']?.split('\n') ??
        [
          'https://vip2.fastcast4u.com/proxy/classicrockdoug?mp=/1',
          'https://c5.radioboss.fm:18224/stream',
        ];

    updateStations(lsStations);
  }

  updateStations(List<String> stationsUrls) {
    window.localStorage['stations'] = stationsUrls.join('\n');
    var sectors = stationsUrls.length + 1;

    stations = stationsUrls
        .asMap()
        .keys
        .toList()
        .map((idx) => Station(
              url: stationsUrls[idx],
              freq: ((idx + 1) * frequencyRangeLength / sectors / 10).round() *
                      10 +
                  frequencyMin,
            ))
        .toList();
  }

  TunedStation? getStationByFreq(int freq) {
    for (final station in stations) {
      var min = station.freq - sideWidth;
      var max = station.freq + sideWidth;

      if (freq > min && freq < max) {
        var diff = (station.freq - freq).abs();
        var signalStrength = (sideWidth - diff) / sideWidth;

        if (signalStrength < 0) signalStrength = 0;

        return TunedStation(station: station, signalStrength: signalStrength);
      }
    }

    return null;
  }
}
