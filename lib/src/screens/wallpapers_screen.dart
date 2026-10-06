import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../nexwall_api.dart';
import '../widgets/common.dart';
import 'preview_screen.dart';

/// Paginated wallpaper grid with infinite scroll.
class WallpapersScreen extends StatefulWidget {
  const WallpapersScreen({super.key, required this.api, this.category});

  final NexWallApi api;

  /// `null` shows wallpapers from all categories on your plan.
  final WallpaperCategory? category;

  @override
  State<WallpapersScreen> createState() => _WallpapersScreenState();
}

class _WallpapersScreenState extends State<WallpapersScreen> {
  final _scroll = ScrollController();
  final _items = <Wallpaper>[];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 600) _loadMore();
  }

  Future<void> _loadMore() async {
    // Stop paging after an error (e.g. 429) until the user taps retry,
    // so we don't burn quota in a loop.
    if (_loading || !_hasMore || _error != null) return;
    setState(() => _loading = true);
    try {
      final page = await widget.api.getWallpapers(
        page: _page + 1,
        categoryId: widget.category?.id,
        sort: _sort,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.currentPage;
        _hasMore = page.hasMore && page.items.isNotEmpty;
      });
      // If the first page doesn't fill the screen there is nothing to
      // scroll, so request the next page right away.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _scroll.hasClients &&
            _scroll.position.maxScrollExtent <= 0) {
          _loadMore();
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _retry() {
    setState(() => _error = null);
    _loadMore();
  }

  void _changeSort(String sort) {
    setState(() {
      _sort = sort;
      _items.clear();
      _page = 0;
      _hasMore = true;
      _error = null;
    });
    _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category?.name ?? 'All wallpapers'),
        actions: [
          QuotaChip(api: widget.api),
          PopupMenuButton<String>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: _changeSort,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'newest', child: Text('Newest')),
              PopupMenuItem(value: 'popular', child: Text('Popular')),
              PopupMenuItem(value: 'random', child: Text('Random')),
              PopupMenuItem(value: 'oldest', child: Text('Oldest')),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_items.isEmpty) {
      if (_error != null) return ErrorView(error: _error!, onRetry: _retry);
      if (_loading) return const Center(child: CircularProgressIndicator());
      return const Center(child: Text('No wallpapers found.'));
    }

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 9 / 16,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final w = _items[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PreviewScreen(wallpaper: w),
                  ),
                ),
                child: Hero(
                  tag: 'wallpaper-${w.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: w.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => ColoredBox(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(child: _buildFooter()),
      ],
    );
  }

  Widget _buildFooter() {
    if (_error != null) {
      final message = _error is NexWallException
          ? (_error as NexWallException).friendlyMessage
          : '$_error';
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: _retry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox(height: 24);
  }
}
