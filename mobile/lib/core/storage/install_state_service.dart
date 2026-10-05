import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';

abstract interface class InstallMarkerStore {
  Future<bool?> readInitialized();

  Future<void> markInitialized();
}

class SharedPreferencesInstallMarkerStore implements InstallMarkerStore {
  static const markerKey = 'bytesync_install_initialized';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  @override
  Future<bool?> readInitialized() async => (await _store).getBool(markerKey);

  @override
  Future<void> markInitialized() async {
    await (await _store).setBool(markerKey, true);
  }
}

/// Prepares persisted authentication state before a cold-start restore.
///
/// SharedPreferences is removed with the app, while iOS Keychain entries may
/// survive uninstall. A missing marker therefore means this installation must
/// not trust any secure-storage session left by an earlier installation.
class InstallStateService {
  InstallStateService(this._markerStore, this._secureStorage);

  final InstallMarkerStore _markerStore;
  final SecureStorageService _secureStorage;
  Future<void>? _preparation;

  Future<void> prepareForSessionRestore() =>
      _preparation ??= _prepareForSessionRestore();

  Future<void> _prepareForSessionRestore() async {
    if (await _markerStore.readInitialized() == true) return;

    // Mark the install only after all auth keys are gone. If either operation
    // fails, the next launch safely retries the cleanup.
    await _secureStorage.clearTokens();
    await _markerStore.markInitialized();
  }
}
