import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:foodbank/features/food_post/domain/entities/food_recognition_suggestion.dart';
import 'food_recognition_remote_datasource.dart';

class GeminiFoodRecognitionException implements Exception {
  final String message;

  const GeminiFoodRecognitionException(this.message);

  @override
  String toString() => 'GeminiFoodRecognitionException: $message';
}

class GeminiFoodRecognitionRemoteDatasourceImpl
    implements FoodRecognitionRemoteDatasource {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash-lite',
  );
  static const _baseUrl = String.fromEnvironment(
    'GEMINI_BASE_URL',
    defaultValue: 'https://generativelanguage.googleapis.com/v1beta',
  );

  final http.Client _client;

  const GeminiFoodRecognitionRemoteDatasourceImpl({required http.Client client})
    : _client = client;

  @override
  Future<FoodRecognitionSuggestion> recognizeFoodImage(File image) async {
    if (_apiKey.isEmpty) {
      throw const GeminiFoodRecognitionException(
        'API key Gemini belum diset. Jalankan dengan --dart-define=GEMINI_API_KEY=key_kamu',
      );
    }

    final bytes = await image.readAsBytes();
    final mimeType = _mimeTypeFromPath(image.path);
    final uri = Uri.parse(
      '$_baseUrl/models/$_model:generateContent',
    ).replace(queryParameters: {'key': _apiKey});

    final response = await _client.post(
      uri,
      headers: const {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': _prompt},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Encode(bytes),
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'response_mime_type': 'application/json',
        },
      }),
    );

    if (response.statusCode != 200) {
      throw GeminiFoodRecognitionException(_errorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractResponseText(body);
    if (text == null || text.trim().isEmpty) {
      throw const GeminiFoodRecognitionException(
        'Gemini tidak mengembalikan hasil deteksi makanan',
      );
    }

    final result = _parseJsonText(text);
    final foodName =
        _asString(result['nama_makanan']) ??
        _asString(result['detected_food']) ??
        _asString(result['food_name']);

    if (foodName == null || foodName.trim().isEmpty) {
      throw const GeminiFoodRecognitionException(
        'Makanan tidak terdeteksi dari foto ini. Coba gunakan foto yang lebih jelas.',
      );
    }

    final category = _asString(result['kategori']);
    final type = _asString(result['jenis']);
    final foodGroups = category == null ? const <String>[] : [category];
    final foodTypes = type == null ? const <String>[] : [type];

    return FoodRecognitionSuggestion(
      candidates: [
        FoodRecognitionCandidate(
          name: foodName.trim(),
          confidence: _asDouble(result['confidence']),
        ),
      ],
      suggestedTitle: _asString(result['judul_postingan']),
      suggestedDescription: _asString(result['deskripsi_postingan']),
      category: category,
      estimatedCalories: _asString(result['estimasi_kalori']),
      ingredients: _asStringList(result['bahan']),
      foodGroups: foodGroups,
      foodTypes: foodTypes,
    );
  }

  String get _prompt {
    return '''
Analisis foto makanan ini untuk aplikasi donasi makanan Indonesia.

Fokus utama:
- Kenali makanan Indonesia jika memungkinkan, misalnya nasi goreng, rendang, soto ayam, bakso, gado-gado, sate, ayam geprek, nasi padang, pecel, rawon, mie ayam, pempek, martabak, nasi uduk, atau makanan lokal lain.
- Jika tidak yakin, berikan nama makanan paling mendekati dalam Bahasa Indonesia.
- Jangan mengklaim makanan aman dikonsumsi hanya dari foto.

Balas hanya JSON valid tanpa markdown:
{
  "nama_makanan": "nama makanan dalam Bahasa Indonesia",
  "confidence": 0.0,
  "kategori": "makanan utama/lauk/snack/minuman/lainnya",
  "jenis": "siap saji/bahan mentah/makanan kemasan/lainnya",
  "bahan": ["bahan yang terlihat atau kemungkinan utama"],
  "estimasi_kalori": "rentang kkal per porsi, jika bisa diperkirakan",
  "judul_postingan": "judul pendek untuk posting donasi",
  "deskripsi_postingan": "deskripsi singkat donor-friendly dalam Bahasa Indonesia, termasuk catatan agar penerima mengecek kondisi makanan saat pickup"
}
''';
  }

  String? _extractResponseText(Map<String, dynamic> json) {
    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final content = candidates.first['content'];
    if (content is! Map<String, dynamic>) return null;

    final parts = content['parts'];
    if (parts is! List) return null;

    for (final part in parts) {
      if (part is Map<String, dynamic>) {
        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) return text;
      }
    }
    return null;
  }

  Map<String, dynamic> _parseJsonText(String text) {
    final cleaned = text
        .trim()
        .replaceFirst(RegExp(r'^```json\s*'), '')
        .replaceFirst(RegExp(r'^```\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();

    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      throw const GeminiFoodRecognitionException(
        'Format respons Gemini tidak valid',
      );
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is String && message.trim().isNotEmpty) return message;
      }
    } catch (_) {
      // Fall through to generic message.
    }

    return switch (response.statusCode) {
      400 => 'Request Gemini tidak valid. Cek format gambar atau API key',
      401 || 403 => 'API key Gemini tidak valid atau belum punya akses',
      429 => 'Limit gratis Gemini tercapai. Coba lagi nanti',
      _ => 'Gagal menghubungi Gemini (${response.statusCode})',
    };
  }

  String _mimeTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String? _asString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
