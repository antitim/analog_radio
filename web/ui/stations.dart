import 'dart:html';

import 'station.dart';
import 'tuned_station.dart';

class Stations {
  Stations() {
    final lsStations = window.localStorage['stations']?.split('\n') ??
        [
          'https://vip2.fastcast4u.com/proxy/classicrockdoug?mp=/1',
          'https://c5.radioboss.fm:18224/stream',
        ];

    updateStations(lsStations);
  }

  final frequencyMin = 520;
  final frequencyMax = 1710;
  final int sideWidth = 10;
  List<Station> stations = [];

  int get frequencyRangeLength => frequencyMax - frequencyMin;

  void updateStations(final List<String> stationsUrls) {
    window.localStorage['stations'] = stationsUrls.join('\n');
    final sectors = stationsUrls.length + 1;

    stations = stationsUrls
        .asMap()
        .keys
        .toList()
        .map((final idx) => Station(
              url: stationsUrls[idx],
              freq: ((idx + 1) * frequencyRangeLength / sectors / 10).round() *
                      10 +
                  frequencyMin,
            ))
        .toList();
  }

  TunedStation? getStationByFreq(final int freq) {
    for (final station in stations) {
      final min = station.freq - sideWidth;
      final max = station.freq + sideWidth;

      if (freq > min && freq < max) {
        final diff = (station.freq - freq).abs();
        var signalStrength = (sideWidth - diff) / sideWidth;

        if (signalStrength < 0) signalStrength = 0;

        return TunedStation(station: station, signalStrength: signalStrength);
      }
    }

    return null;
  }
}
