import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const Object _unset = Object();

class AppUpdateInfo {
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final int minSupportedBuild;
  final bool forceUpdate;
  final String title;
  final String releaseNotes;
  final String playStoreUrl;
  final String appStoreUrl;
  final String? directApkUrl;
  final bool isUpdateAvailable;
  final bool isForceUpdate;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.minSupportedBuild,
    required this.forceUpdate,
    required this.title,
    required this.releaseNotes,
    required this.playStoreUrl,
    required this.appStoreUrl,
    this.directApkUrl,
    required this.isUpdateAvailable,
    required this.isForceUpdate,
  });

  factory AppUpdateInfo.none({
    required String currentVersion,
    required int currentBuildNumber,
    String playStoreUrl =
        'https://play.google.com/store/apps/details?id=uz.zargo.xonadosh',
    String appStoreUrl = '',
  }) => AppUpdateInfo(
    currentVersion: currentVersion,
    currentBuildNumber: currentBuildNumber,
    latestVersion: currentVersion,
    latestBuildNumber: currentBuildNumber,
    minSupportedBuild: 1,
    forceUpdate: false,
    title: '',
    releaseNotes: '',
    playStoreUrl: playStoreUrl,
    appStoreUrl: appStoreUrl,
    isUpdateAvailable: false,
    isForceUpdate: false,
  );

  static bool isVersionHigher(String remoteVersion, String localVersion) {
    try {
      final sParts = remoteVersion
          .split('.')
          .map((e) => int.tryParse(e.trim()) ?? 0)
          .toList();
      final lParts = localVersion
          .split('.')
          .map((e) => int.tryParse(e.trim()) ?? 0)
          .toList();
      final len = sParts.length > lParts.length ? sParts.length : lParts.length;
      for (var i = 0; i < len; i++) {
        final s = i < sParts.length ? sParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (s > l) return true;
        if (s < l) return false;
      }
    } catch (_) {}
    return false;
  }
}

class AppUpdateState {
  final bool isChecking;
  final bool isUpdating;
  final String statusMessage;
  final AppUpdateInfo? updateInfo;
  final String? error;

  const AppUpdateState({
    this.isChecking = false,
    this.isUpdating = false,
    this.statusMessage = '',
    this.updateInfo,
    this.error,
  });

  AppUpdateState copyWith({
    bool? isChecking,
    bool? isUpdating,
    String? statusMessage,
    Object? updateInfo = _unset,
    Object? error = _unset,
  }) {
    return AppUpdateState(
      isChecking: isChecking ?? this.isChecking,
      isUpdating: isUpdating ?? this.isUpdating,
      statusMessage: statusMessage ?? this.statusMessage,
      updateInfo: identical(updateInfo, _unset)
          ? this.updateInfo
          : updateInfo as AppUpdateInfo?,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class _StoreAvailability {
  const _StoreAvailability({
    required this.hasUpdate,
    this.storeVersion,
    this.storeBuild,
    this.storeUrl,
  });

  final bool hasUpdate;
  final String? storeVersion;
  final int? storeBuild;
  final String? storeUrl;
}

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  final Dio _dio;

  AppUpdateNotifier([Dio? dio])
    : _dio = dio ?? Dio(),
      super(const AppUpdateState()) {
    checkForUpdate();
  }

  Future<AppUpdateInfo?> checkForUpdate() async {
    state = state.copyWith(
      isChecking: true,
      isUpdating: false,
      error: null,
      statusMessage: '',
    );
    try {
      final PackageInfo packageInfo;
      try {
        packageInfo = await PackageInfo.fromPlatform();
      } catch (e) {
        developer.log('PackageInfo failed: $e', name: 'AppUpdateService');
        state = state.copyWith(isChecking: false, updateInfo: null);
        return null;
      }

      final currentVersion = packageInfo.version.trim();
      final currentBuild = int.tryParse(packageInfo.buildNumber.trim()) ?? 0;
      if (currentVersion.isEmpty || currentBuild <= 0) {
        state = state.copyWith(isChecking: false, updateInfo: null);
        return null;
      }

      final store = await _checkStoreAvailability(
        currentVersion: currentVersion,
        currentBuild: currentBuild,
        packageName: packageInfo.packageName,
      );

      Map<String, dynamic> server = const {};
      try {
        server = await _fetchServerConfig(
          currentBuild: currentBuild,
          currentVersion: currentVersion,
        );
      } catch (e) {
        developer.log('app_version.php skipped: $e', name: 'AppUpdateService');
      }

      final playStoreUrl =
          (server['play_store_url'] as String?)?.trim().isNotEmpty == true
          ? server['play_store_url'] as String
          : 'https://play.google.com/store/apps/details?id=uz.zargo.xonadosh';
      final appStoreUrl = (store.storeUrl?.trim().isNotEmpty == true)
          ? store.storeUrl!
          : ((server['app_store_url'] as String?) ?? '');

      final storeHasUpdate = store.hasUpdate || (server['is_update_available'] == true);
      final forceFlag =
          server['force_update'] == true || server['force_update'] == 1;
      final isForce = storeHasUpdate && forceFlag;

      final latestVersion = (store.storeVersion?.trim().isNotEmpty == true)
          ? store.storeVersion!
          : (server['latest_version']?.toString() ?? currentVersion);
      final latestBuild = store.storeBuild ?? (int.tryParse(server['latest_build_number']?.toString() ?? '') ?? currentBuild);

      final info = AppUpdateInfo(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuild,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuild,
        minSupportedBuild: int.tryParse(server['min_supported_build']?.toString() ?? '1') ?? 1,
        forceUpdate: forceFlag,
        title: (server['title'] as String?)?.trim().isNotEmpty == true
            ? server['title'] as String
            : 'XonaDosh yangilanishi mavjud',
        releaseNotes: (server['release_notes'] as String?) ?? 'Yangi imkoniyatlar va yaxshilanishlar',
        playStoreUrl: playStoreUrl,
        appStoreUrl: appStoreUrl,
        directApkUrl: server['direct_apk_url']?.toString(),
        isUpdateAvailable: storeHasUpdate,
        isForceUpdate: isForce,
      );

      state = state.copyWith(
        isChecking: false,
        isUpdating: false,
        updateInfo: storeHasUpdate
            ? info
            : AppUpdateInfo.none(
                currentVersion: currentVersion,
                currentBuildNumber: currentBuild,
                playStoreUrl: playStoreUrl,
                appStoreUrl: appStoreUrl,
              ),
      );
      return storeHasUpdate ? info : state.updateInfo;
    } catch (e) {
      developer.log('Check for update error: $e', name: 'AppUpdateService');
      state = state.copyWith(
        isChecking: false,
        isUpdating: false,
        error: e.toString(),
        updateInfo: null,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchServerConfig({
    required int currentBuild,
    required String currentVersion,
  }) async {
    final response = await _dio.get(
      'https://hamyon-ai.uz/api/app_version.php',
      queryParameters: {
        'app': 'xonadosh',
        'build_number': currentBuild,
        'version': currentVersion,
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      },
      options: Options(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    if (response.statusCode == 200 && response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    return const {};
  }

  Future<_StoreAvailability> _checkStoreAvailability({
    required String currentVersion,
    required int currentBuild,
    required String packageName,
  }) async {
    if (kIsWeb) {
      return const _StoreAvailability(hasUpdate: false);
    }

    if (Platform.isAndroid) {
      try {
        final playInfo = await InAppUpdate.checkForUpdate();
        final storeCode = playInfo.availableVersionCode ?? 0;
        final available =
            playInfo.updateAvailability == UpdateAvailability.updateAvailable &&
            storeCode > currentBuild;
        return _StoreAvailability(
          hasUpdate: available,
          storeBuild: available ? storeCode : currentBuild,
        );
      } catch (e) {
        if (!kDebugMode) {
          developer.log('Play InAppUpdate: $e', name: 'AppUpdateService');
        }
        return const _StoreAvailability(hasUpdate: false);
      }
    }

    if (Platform.isIOS) {
      return _checkAppStore(
        currentVersion: currentVersion,
        bundleId: packageName.isNotEmpty ? packageName : 'uz.zargo.xonadosh',
      );
    }

    return const _StoreAvailability(hasUpdate: false);
  }

  Future<_StoreAvailability> _checkAppStore({
    required String currentVersion,
    required String bundleId,
  }) async {
    const countries = ['uz', 'us', 'ru', ''];
    for (final country in countries) {
      try {
        final uri = Uri.https('itunes.apple.com', '/lookup', {
          'bundleId': bundleId,
          if (country.isNotEmpty) 'country': country,
        });
        final response = await _dio.getUri(
          uri,
          options: Options(
            receiveTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 8),
          ),
        );
        final data = response.data;
        if (data is! Map) continue;
        final json = Map<String, dynamic>.from(data);
        final count = (json['resultCount'] as num?)?.toInt() ?? 0;
        if (count <= 0) continue;
        final results = json['results'];
        if (results is! List || results.isEmpty || results.first is! Map) {
          continue;
        }
        final row = Map<String, dynamic>.from(results.first as Map);
        final storeVersion = row['version']?.toString().trim() ?? '';
        if (storeVersion.isEmpty) continue;
        final storeUrl =
            (row['trackViewUrl'] ?? row['sellerUrl'])?.toString() ?? '';
        final hasUpdate = AppUpdateInfo.isVersionHigher(
          storeVersion,
          currentVersion,
        );
        return _StoreAvailability(
          hasUpdate: hasUpdate,
          storeVersion: storeVersion,
          storeUrl: storeUrl,
        );
      } catch (e) {
        developer.log(
          'App Store lookup ($country): $e',
          name: 'AppUpdateService',
        );
      }
    }
    return const _StoreAvailability(hasUpdate: false);
  }

  void dismissOptionalUpdate() {
    final info = state.updateInfo;
    if (info == null || info.isForceUpdate) return;
    state = state.copyWith(
      updateInfo: AppUpdateInfo.none(
        currentVersion: info.currentVersion,
        currentBuildNumber: info.currentBuildNumber,
        playStoreUrl: info.playStoreUrl,
        appStoreUrl: info.appStoreUrl,
      ),
    );
  }

  Future<void> startUpdate() async {
    final info = state.updateInfo;
    if (info == null || !info.isUpdateAvailable) return;

    state = state.copyWith(
      isUpdating: true,
      statusMessage: 'Do‘kon ochilmoqda...',
    );

    try {
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final playInfo = await InAppUpdate.checkForUpdate();
          final storeCode = playInfo.availableVersionCode ?? 0;
          if (playInfo.updateAvailability ==
                  UpdateAvailability.updateAvailable &&
              storeCode > info.currentBuildNumber) {
            state = state.copyWith(
              statusMessage: 'Google Play orqali yangilanmoqda...',
            );
            final result = await InAppUpdate.performImmediateUpdate();
            if (result == AppUpdateResult.success) {
              await checkForUpdate();
              return;
            }
          }
        } catch (e) {
          developer.log(
            'InAppUpdate immediate update fallback: $e',
            name: 'AppUpdateService',
          );
        }
      }

      final isIos = !kIsWeb && Platform.isIOS;
      final pageUrl = isIos && info.appStoreUrl.isNotEmpty
          ? info.appStoreUrl
          : info.playStoreUrl;
      final uri = Uri.parse(pageUrl);
      final marketUri = Uri.parse('market://details?id=uz.zargo.xonadosh');

      var launched = false;
      if (!kIsWeb && Platform.isAndroid) {
        try {
          if (await canLaunchUrl(marketUri)) {
            await launchUrl(marketUri, mode: LaunchMode.externalApplication);
            launched = true;
          }
        } catch (_) {}
      }

      if (!launched && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      state = state.copyWith(
        isUpdating: false,
        statusMessage: isIos
            ? 'App Store da yangilanish bo‘lsa o‘rnating, keyin ilovaga qayting.'
            : 'Play Marketda yangilanish bo‘lsa o‘rnating, keyin ilovaga qayting.',
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Yangilanishni boshlab bo‘lmadi: $e',
      );
    }
  }

  void resetUpdatingState() {
    state = state.copyWith(isUpdating: false, statusMessage: '');
  }
}

final appUpdateNotifierProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
      return AppUpdateNotifier();
    });
