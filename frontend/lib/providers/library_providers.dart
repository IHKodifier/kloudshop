import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryAsset {
  final String url;
  final String name;
  final String type;
  final Uint8List? localBytes;

  LibraryAsset({
    required this.url,
    required this.name,
    required this.type,
    this.localBytes,
  });

  LibraryAsset copyWith({
    String? url,
    String? name,
    String? type,
    Uint8List? localBytes,
  }) {
    return LibraryAsset(
      url: url ?? this.url,
      name: name ?? this.name,
      type: type ?? this.type,
      localBytes: localBytes ?? this.localBytes,
    );
  }
}

final libraryImagesProvider = NotifierProvider<LibraryImagesNotifier, List<LibraryAsset>>(
  LibraryImagesNotifier.new,
);

class LibraryImagesNotifier extends Notifier<List<LibraryAsset>> {
  @override
  List<LibraryAsset> build() {
    return [
      LibraryAsset(
        url: 'https://images.unsplash.com/photo-1542496658-e33a6d0d50f6',
        name: 'brand logo',
        type: 'PNG',
      ),
      LibraryAsset(
        url: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8',
        name: 'main banner',
        type: 'PNG',
      ),
      LibraryAsset(
        url: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
        name: 'headphones',
        type: 'PNG',
      ),
      LibraryAsset(
        url: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30',
        name: 'Fav icon',
        type: 'PNG',
      ),
      LibraryAsset(
        url: 'https://images.unsplash.com/photo-1572635196237-14b3f281503f',
        name: 'sunglasses',
        type: 'PNG',
      ),
      LibraryAsset(
        url: 'https://images.unsplash.com/photo-1560343090-f0409e92791a',
        name: 'footer image',
        type: 'PNG',
      ),
    ];
  }

  void addImage(String url, {String? name, String? type, Uint8List? localBytes}) {
    if (!state.any((asset) => asset.url == url)) {
      final fileName = url.split('/').last.split('?').first;
      final extension = fileName.split('.').last.toUpperCase();
      state = [
        ...state,
        LibraryAsset(
          url: url,
          name: name ?? fileName.replaceAll('%20', ' '),
          type: type ?? (extension.length > 4 ? 'PNG' : extension),
          localBytes: localBytes,
        ),
      ];
    }
  }

  void renameAsset(String url, String newName) {
    state = state.map((asset) {
      if (asset.url == url) {
        return asset.copyWith(name: newName);
      }
      return asset;
    }).toList();
  }

  void removeAsset(String url) {
    state = state.where((asset) => asset.url != url).toList();
  }
}

class SavedViewConfig {
  final String name;
  final String searchQuery;
  final List<String> selectedUrls;

  SavedViewConfig({
    required this.name,
    required this.searchQuery,
    required this.selectedUrls,
  });
}

final savedViewsProvider = NotifierProvider<SavedViewsNotifier, List<SavedViewConfig>>(
  SavedViewsNotifier.new,
);

class SavedViewsNotifier extends Notifier<List<SavedViewConfig>> {
  @override
  List<SavedViewConfig> build() {
    return [
      SavedViewConfig(name: 'All images', searchQuery: '', selectedUrls: []),
      SavedViewConfig(name: 'Logos', searchQuery: 'logo', selectedUrls: []),
      SavedViewConfig(name: 'Banners', searchQuery: 'banner', selectedUrls: []),
    ];
  }

  void saveView(String name, String searchQuery, List<String> selectedUrls) {
    state = [
      ...state.where((v) => v.name != name),
      SavedViewConfig(name: name, searchQuery: searchQuery, selectedUrls: selectedUrls),
    ];
  }

  void removeView(String name) {
    state = state.where((v) => v.name != name).toList();
  }

  void renameView(String oldName, String newName) {
    state = state.map((view) {
      if (view.name == oldName) {
        return SavedViewConfig(
          name: newName,
          searchQuery: view.searchQuery,
          selectedUrls: view.selectedUrls,
        );
      }
      return view;
    }).toList();
  }

  void clearAllCustomViews() {
    state = [
      SavedViewConfig(name: 'All images', searchQuery: '', selectedUrls: []),
      SavedViewConfig(name: 'Logos', searchQuery: 'logo', selectedUrls: []),
      SavedViewConfig(name: 'Banners', searchQuery: 'banner', selectedUrls: []),
    ];
  }
}
