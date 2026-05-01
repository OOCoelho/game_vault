import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const int _chunkSize = 450;
  static final Map<String, String> _cache = {};

  static Future<String> translate(String text) async {
    if (text.isEmpty) return text;
    if (_cache.containsKey(text)) return _cache[text]!;

    final chunks = _splitIntoChunks(text.trim());
    final translated = <String>[];

    for (final chunk in chunks) {
      try {
        translated.add(await _translateChunk(chunk));
        await Future.delayed(const Duration(milliseconds: 200)); // evita rate limit
      } catch (_) {
        translated.add(chunk); // fallback: mantém original
      }
    }

    final result = translated.join(' ');
    _cache[text] = result;
    return result;
  }

  static List<String> _splitIntoChunks(String text) {
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    final chunks = <String>[];
    var current = '';

    for (final s in sentences) {
      if ('$current $s'.length > _chunkSize && current.isNotEmpty) {
        chunks.add(current.trim());
        current = s;
      } else {
        current = current.isEmpty ? s : '$current $s';
      }
    }
    if (current.isNotEmpty) chunks.add(current.trim());
    return chunks;
  }

  static Future<String> _translateChunk(String text) async {
    // Tentativa 1: MyMemory
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=en|pt-BR',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final translated = data['responseData']['translatedText'] as String?;
        if (translated != null &&
            !translated.startsWith('QUERY LENGTH') &&
            !translated.toUpperCase().startsWith('MYMEMORY WARNING')) {
          return translated;
        }
      }
    } catch (_) {}

    // Tentativa 2: Google Translate (endpoint não oficial, sem chave)
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
        '?client=gtx&sl=en&tl=pt-BR&dt=t&q=${Uri.encodeComponent(text)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final buffer = StringBuffer();
        for (final part in (data[0] as List)) {
          final seg = part[0];
          if (seg is String) buffer.write(seg);
        }
        final result = buffer.toString().trim();
        if (result.isNotEmpty) return result;
      }
    } catch (_) {}

    return text; // fallback: retorna original
  }
}