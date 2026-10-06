/// Data models for the NexWall Developer API responses.
library;

class WallpaperCategory {
  const WallpaperCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.coverImageUrl,
    required this.wallpaperCount,
    required this.isPremium,
  });

  final int id;
  final String name;
  final String slug;
  final String? coverImageUrl;
  final int wallpaperCount;
  final bool isPremium;

  factory WallpaperCategory.fromJson(Map<String, dynamic> json) =>
      WallpaperCategory(
        id: _asInt(json['id']),
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        coverImageUrl: json['cover_image_url'] as String?,
        wallpaperCount: _asInt(json['wallpaper_count']),
        isPremium: json['is_premium'] == true,
      );
}

class Wallpaper {
  const Wallpaper({
    required this.id,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.type,
    required this.isPremium,
    required this.tags,
    this.resolution,
    this.fileSize,
    this.categoryName,
  });

  final int id;
  final String imageUrl;
  final String thumbnailUrl;

  /// `image` or `live`. Live (video) wallpapers require the Ultra plan.
  final String type;
  final bool isPremium;
  final List<String> tags;
  final String? resolution;
  final int? fileSize;
  final String? categoryName;

  bool get isImage => type == 'image';

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    final image = json['image_url']?.toString() ?? '';
    final category = json['category'];
    final rawTags = json['tags'];
    return Wallpaper(
      id: _asInt(json['id']),
      imageUrl: image,
      thumbnailUrl: json['thumbnail_url']?.toString() ?? image,
      type: json['type']?.toString() ?? 'image',
      isPremium: json['is_premium'] == true,
      tags: rawTags is List
          ? rawTags.map((t) => t.toString()).toList()
          : rawTags is String && rawTags.isNotEmpty
          ? rawTags.split(',').map((t) => t.trim()).toList()
          : const [],
      resolution: json['resolution']?.toString(),
      fileSize: json['file_size'] == null ? null : _asInt(json['file_size']),
      categoryName: category is Map<String, dynamic>
          ? category['name']?.toString()
          : null,
    );
  }
}

/// One page of results from `GET /wallpapers` or
/// `GET /categories/{id}/wallpapers`.
class WallpaperPage {
  const WallpaperPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<Wallpaper> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
