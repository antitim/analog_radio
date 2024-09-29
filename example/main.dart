import 'package:analog_radio/analog_radio.dart';

void main() {
  final radio = AnalogRadio();
  radio.turnOn();
  radio.tune('https://vip2.fastcast4u.com/proxy/classicrockdoug?mp=/1', 0.9);
}
