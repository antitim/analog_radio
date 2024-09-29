import 'station.dart';

class TunedStation extends Station {
  TunedStation({required final Station station, required this.signalStrength})
      : super(url: station.url, freq: station.freq);

  final double signalStrength;
}
