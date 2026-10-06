import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexwall_wallpaper_app/src/nexwall_api.dart';

void main() {
  test('parses categories and tracks remaining quota', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-key');
      expect(request.url.path, endsWith('/categories'));
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 5,
              'name': 'Nature',
              'slug': 'nature',
              'cover_image_url': 'https://example.com/c.jpg',
              'wallpaper_count': 42,
              'is_premium': false,
            },
          ],
          'plan': 'free',
          'remaining_requests_today': 99,
        }),
        200,
      );
    });

    final api = NexWallApi(client: client, apiKey: 'test-key');
    final categories = await api.getCategories();

    expect(categories.single.name, 'Nature');
    expect(categories.single.wallpaperCount, 42);
    expect(api.remainingToday.value, 99);
    expect(api.plan.value, 'free');
  });

  test('throws a quota error on 429 with Retry-After', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'message': 'Daily quota exceeded'}),
        429,
        headers: {'retry-after': '3600'},
      ),
    );

    final api = NexWallApi(client: client, apiKey: 'test-key');

    await expectLater(
      api.getWallpapers(),
      throwsA(
        isA<NexWallException>()
            .having((e) => e.isQuotaExceeded, 'isQuotaExceeded', true)
            .having((e) => e.retryAfter, 'retryAfter', 3600),
      ),
    );
    expect(api.remainingToday.value, 0);
  });
}
