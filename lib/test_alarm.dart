import 'package:alarm/alarm.dart';
void main() {
  final a = AlarmSettings(
    id: 1,
    dateTime: DateTime.now(),
    assetAudioPath: 'assets/audio/alarma.mp3',
    volumeSettings: const AlarmVolumeSettings(volume: 1.0),
    notificationSettings: const AlarmNotificationSettings(
      title: 'Title',
      body: 'Body',
      stopButton: 'Stop',
    ),
  );
}
