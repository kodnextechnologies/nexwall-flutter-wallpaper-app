import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

/// Thrown for any non-2xx response from the NexWall API.
class NexWallException implements Exception {
  NexWallException(this.statusCode, this.message, {this.retryAfter});

  final int statusCode;
  final String message;

  /// Seconds to wait before retrying (only set for HTTP 429).
  final int? retryAfter;

  bool get isQuotaExceeded => statusCode == 429;

  /// A short, user-facing explanation.
  String get friendlyMessage {
    switch (statusCode) {
      case 401:
        return 'Invalid or missing API key. Get a free key at '
            'https://nexwall.kodnextech.com/developers/register';
      case 404:
        return 'Not found, or not available on your plan.';
      case 422:
        return 'Invalid request: $message';
      case 429:
        final wait = retryAfter == null ? '' : ' Try again in ${retryAfter}s.';
        return 'API quota exceeded.$wait';
      default:
        return message;
    }
  }

  @override
  String toString() => 'NexWallException($statusCode): $message';
}

/// Minimal client for the NexWall Developer API v1.
///
/// Docs: https://nexwall.kodnextech.com/wallpaper-api/docs
class NexWallApi {
  NexWallApi({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey ?? AppConfig.apiKey;

  final http.Client _client;
  final String _apiKey;

  /// Requests left today, as reported by the last response
  /// (`remaining_requests_today`). `null` until the first call.
  final ValueNotifier<int?> remainingToday = ValueNotifier<int?>(null);

  /// Current plan (`free`, `pro`, `ultra`) from the last response.
  final ValueNotifier<String?> plan = ValueNotifier<String?>(null);

  Future<List<WallpaperCategory>> getCategories() async {
    final json = await _get('/categories');
    final data = json['data'] as List<dynamic>? ?? const [];
    return data
        .map((e) => WallpaperCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lists wallpapers. Pass [categoryId] to filter, [search] (2-100 chars)
  /// to match tags, and [sort] = newest | oldest | popular | random.
  Future<WallpaperPage> getWallpapers({
    int page = 1,
    int perPage = AppConfig.pageSize,
    int? categoryId,
    String? search,
    String sort = 'newest',
    String type = 'image',
  }) async {
    final json = await _get('/wallpapers', {
      'page': '$page',
      'per_page': '$perPage',
      'sort': sort,
      'type': type,
      if (categoryId != null) 'category_id': '$categoryId',
      if (search != null && search.trim().length >= 2) 'search': search.trim(),
    });
    final data = json['data'] as List<dynamic>? ?? const [];
    return WallpaperPage(
      items: data
          .map((e) => Wallpaper.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (json['current_page'] as num?)?.toInt() ?? page,
      lastPage: (json['last_page'] as num?)?.toInt() ?? page,
      total: (json['total'] as num?)?.toInt() ?? data.length,
    );
  }

  Future<Wallpaper> getWallpaper(int id) async {
    final json = await _get('/wallpapers/$id');
    final data = json['data'];
    return Wallpaper.fromJson((data is Map<String, dynamic> ? data : json));
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    if (_apiKey.isEmpty && !AppConfig.usesProxy) {
      throw NexWallException(
        401,
        'NEXWALL_API_KEY is not set. Run with '
        '--dart-define=NEXWALL_API_KEY=your_key',
      );
    }

    final uri = Uri.parse('${AppConfig.baseUrl}$path')
        .replace(queryParameters: query);
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
      },
    );

    Map<String, dynamic> body = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } on FormatException {
      // Non-JSON body (e.g. a proxy error page); handled below.
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final remaining = body['remaining_requests_today'];
      if (remaining is num) remainingToday.value = remaining.toInt();
      if (body['plan'] is String) plan.value = body['plan'] as String;
      return body;
    }

    if (response.statusCode == 429) remainingToday.value = 0;
    throw NexWallException(
      response.statusCode,
      body['message']?.toString() ?? 'HTTP ${response.statusCode}',
      retryAfter: int.tryParse(response.headers['retry-after'] ?? ''),
    );
  }

  void dispose() {
    _client.close();
    remainingToday.dispose();
    plan.dispose();
  }
}
