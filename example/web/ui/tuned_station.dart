import 'station.dart';

class TunedStation extends Station {
  final double signalStrength;

  TunedStation({required Station station, required this.signalStrength})
      : super(url: station.url, freq: station.freq);
}
