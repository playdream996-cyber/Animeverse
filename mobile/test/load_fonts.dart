import 'package:flutter/services.dart';

Future<void> loadPreviewFonts() async {
  for (final entry in {
    'Inter': 'assets/fonts/inter.ttf',
    'Lora': 'assets/fonts/lora.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
  }.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}
