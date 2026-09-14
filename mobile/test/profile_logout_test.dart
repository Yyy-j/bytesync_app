import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/core/network/dio_error_mapper.dart';
import 'package:bytesync/core/storage/secure_storage_service.dart';
import 'package:bytesync/features/auth/data/google_auth_client.dart';
import 'package:bytesync/features/auth/data/remote_auth_repository.dart';
import 'package:bytesync/features/profile/data/dto/user_profile_dto.dart';

class _MemorySecureStorage extends SecureStorageService {
  String? token;

  @override
  Future<String?> readAuthToken() async => token;

  @override
  Future<void> saveAuthToken(String value) async => token = value;

  @override
  Future<void> clearAuthToken() async => token = null;
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
    await storage.saveAuthToken('local-jwt');
    final repository = RemoteAuthRepository(
      dio: Dio(),
      storage: storage,
      googleAuthClient: GoogleAuthClient(),
      errorMapper: const DioErrorMapper(),
    );

    await repository.signOut();

    expect(await storage.readAuthToken(), isNull);
  });
}
