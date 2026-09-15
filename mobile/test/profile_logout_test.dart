import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/core/network/dio_error_mapper.dart';
import 'package:bytesync/core/network/auth_event_bus.dart';
import 'package:bytesync/core/network/auth_session_manager.dart';
import 'package:bytesync/core/storage/secure_storage_service.dart';
import 'package:bytesync/features/auth/data/google_auth_client.dart';
import 'package:bytesync/features/auth/data/remote_auth_repository.dart';
import 'package:bytesync/features/profile/data/dto/user_profile_dto.dart';

class _MemorySecureStorage extends SecureStorageService {
  String? accessToken;
  String? refreshToken;
  DateTime? refreshedAt;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<DateTime?> readLastSuccessfulRefreshAt() async => refreshedAt;

  @override
  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
    required DateTime refreshedAt,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.refreshedAt = refreshedAt;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    refreshedAt = null;
  }
}

void main() {
  test('profile DTO and update request map display name and avatar URL', () {
    final profile = UserProfileDto.fromJson({
      'id': 'user-1',
      'email': 'one@example.com',
      'provider': 'google',
      'display_name': 'One',
      'avatar_url': 'https://example.com/one.png',
      'goals': {'calories': 2000, 'protein': 90, 'carbs': 250, 'fat': 60},
    }).toDomain();
    expect(profile.displayName, 'One');
    expect(profile.avatarUrl, 'https://example.com/one.png');
    expect(
      const UpdateUserProfileRequestDto(
        displayName: 'New Name',
        avatarUrl: null,
      ).toJson(),
      {'display_name': 'New Name', 'avatar_url': null},
    );
  });

  test('logout clears the locally persisted JWT', () async {
    final storage = _MemorySecureStorage();
    await storage.saveTokenPair(
      accessToken: 'local-jwt',
      refreshToken: 'local-refresh',
      refreshedAt: DateTime.now().toUtc(),
    );
    final bus = AuthEventBus();
    final sessionManager = AuthSessionManager(
      refreshDio: Dio(),
      storage: storage,
      eventBus: bus,
    );
    final repository = RemoteAuthRepository(
      dio: Dio(),
      storage: storage,
      googleAuthClient: GoogleAuthClient(),
      errorMapper: const DioErrorMapper(),
      sessionManager: sessionManager,
    );

    await repository.signOut();

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
    bus.dispose();
  });
}
