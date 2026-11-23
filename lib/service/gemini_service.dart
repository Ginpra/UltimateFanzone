import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../core/gemini_parser.dart';

/// Error AI yang pesannya aman ditampilkan ke pengguna.
class GeminiException implements Exception {
  const GeminiException(this.message, {this.modelUnavailable = false});

  final String message;

  /// true bila model tidak ditemukan (kode 404), supaya model lain dicoba.
  final bool modelUnavailable;

  @override
  String toString() => message;
}

/// Satu giliran percakapan. [role] berisi 'user' atau 'model'.
class ChatTurn {
  const ChatTurn({required this.role, required this.text});

  final String role;
  final String text;
}

/// Memanggil Gemini lewat HTTP POST (Modul V).
class GeminiService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Model bawaan, dicoba berurutan bila model sebelumnya tidak ditemukan.
  static const _defaultModels = ['gemini-3.8-flash', 'gemini-flash-latest'];

  List<String> _models() {
    final result = <String>[];
    for (final raw in [AppConfig.geminiModel, ..._defaultModels]) {
      final model = raw.trim();
      if (model.isNotEmpty && !result.contains(model)) result.add(model);
    }
    return result;
  }

  /// Kirim percakapan, kembalikan jawaban AI. Giliran terakhir harus 'user'.
  Future<String> ask({
    required String systemInstruction,
    required List<ChatTurn> turns,
  }) async {
    if (!AppConfig.hasGeminiKey) {
      throw const GeminiException('GEMINI_API_KEY belum diisi di env.json.');
    }
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': [
        for (final t in turns)
          {
            'role': t.role,
            'parts': [
              {'text': t.text},
            ],
          },
      ],
    });

    for (final model in _models()) {
      try {
        return await _call(model, body);
      } on GeminiException catch (e) {
        if (!e.modelUnavailable) rethrow;
      }
    }
    throw const GeminiException(
      'Model AI tidak ditemukan. Isi GEMINI_MODEL di env.json dengan model yang aktif.',
    );
  }

  Future<String> _call(String model, String body) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/$model:generateContent'),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': AppConfig.geminiApiKey,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const GeminiException(
        'Tidak ada koneksi internet atau server AI tidak menjawab.',
      );
    }

    final code = response.statusCode;
    if (code == 404) {
      throw const GeminiException(
        'Model tidak tersedia',
        modelUnavailable: true,
      );
    }
    if (code == 401 || code == 403) {
      throw const GeminiException(
        'API key AI ditolak. Periksa GEMINI_API_KEY.',
      );
    }
    if (code == 429) {
      throw const GeminiException(
        'Batas permintaan AI tercapai. Coba lagi nanti.',
      );
    }
    if (code >= 500) {
      throw const GeminiException('Server AI sedang sibuk. Coba lagi nanti.');
    }
    if (code != 200) {
      throw GeminiException('Permintaan AI gagal (kode $code).');
    }

    Object? json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      throw const GeminiException('Jawaban AI tidak terbaca.');
    }
    final text = parseGeminiText(json);
    if (text == null) {
      throw const GeminiException(
        'AI tidak memberi jawaban. Coba pertanyaan lain.',
      );
    }
    return text;
  }
}
