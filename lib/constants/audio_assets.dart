class AudioAssets {
  AudioAssets._();

  static const List<SoundOption> options = [
    SoundOption(label: '빗소리', path: 'assets/audio/rain.mp3'),
    SoundOption(label: '밤벌레', path: 'assets/audio/cricket.mp3'),
    SoundOption(label: '모닥불', path: 'assets/audio/fire.mp3'),
  ];

  static const String defaultPath = 'assets/audio/rain.mp3';
}

class SoundOption {
  final String label;
  final String path;
  const SoundOption({required this.label, required this.path});
}
