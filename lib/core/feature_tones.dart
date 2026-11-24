import 'package:flutter/material.dart';

/// Kategori fitur dan warnanya. Warna hanya dipakai pada ikon menu supaya
/// kelompok fitur mudah dibedakan; emas tetap khusus untuk aksi utama dan skor.
enum FeatureTone { info, play, personal, safety }

extension FeatureToneColor on FeatureTone {
  Color get color {
    switch (this) {
      case FeatureTone.info:
        return const Color(0xFF4FC3F7);
      case FeatureTone.play:
        return const Color(0xFFFF8A65);
      case FeatureTone.personal:
        return const Color(0xFFB39DDB);
      case FeatureTone.safety:
        return const Color(0xFFEF5350);
    }
  }
}
