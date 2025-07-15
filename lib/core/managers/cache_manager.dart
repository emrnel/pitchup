import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../theme/app_colors.dart';
import '../../presentation/widgets/animations/shimmer_loading.dart';

class ImageCacheManager {
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int maxCacheAge = 7; // days

  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  static final customCacheManager = CacheManager(
    Config(
      'pitchup_cache',
      stalePeriod: const Duration(days: maxCacheAge),
      maxNrOfCacheObjects: 200,
    ),
  );

  static void configureCacheSettings() {
    PaintingBinding.instance.imageCache.maximumSizeBytes = maxCacheSize;
    PaintingBinding.instance.imageCache.maximumSize = 100;
  }

  static Future<void> clearCache() async {
    await customCacheManager.emptyCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  static Widget buildCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: customCacheManager,
      placeholder: (context, url) =>
          placeholder ??
          ShimmerLoading(
            width: width ?? double.infinity,
            height: height ?? double.infinity,
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: AppColors.dividerColor,
            child: const Icon(
              Icons.error_outline,
              color: AppColors.textTertiary,
              size: 32,
            ),
          ),
    );
  }

  static Future<void> preloadImage(String imageUrl) async {
    await customCacheManager.downloadFile(imageUrl);
  }

  static Future<File?> getCachedFile(String imageUrl) async {
    final fileInfo = await customCacheManager.getFileFromCache(imageUrl);
    return fileInfo?.file;
  }
}
