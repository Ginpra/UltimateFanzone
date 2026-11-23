/// Mengambil teks jawaban dari respons Gemini `generateContent`.
///
/// Bentuk respons: `candidates[0].content.parts[].text`. Bagian "thought"
/// (proses berpikir model) dilewati. Mengembalikan null bila tidak ada teks.
String? parseGeminiText(Object? body) {
  if (body is! Map) return null;
  final candidates = body['candidates'];
  if (candidates is! List || candidates.isEmpty) return null;
  final first = candidates.first;
  if (first is! Map) return null;
  final content = first['content'];
  if (content is! Map) return null;
  final parts = content['parts'];
  if (parts is! List) return null;

  final buffer = StringBuffer();
  for (final part in parts) {
    if (part is! Map) continue;
    if (part['thought'] == true) continue;
    final text = part['text'];
    if (text is String) buffer.write(text);
  }
  final result = buffer.toString().trim();
  return result.isEmpty ? null : result;
}
