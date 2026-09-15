import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/user_providers.dart';
import '../data/user_repository.dart';
import '../domain/user_profile.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileFailure extends ProfileState {
  const ProfileFailure(this.message);

  final String message;
}

class ProfileReady extends ProfileState {
  const ProfileReady({required this.profile, this.saving = false});

  final UserProfile profile;
  final bool saving;
}

class ProfileSaveResult {
  const ProfileSaveResult.success() : errorMessage = null;
  const ProfileSaveResult.failure(this.errorMessage);

  final String? errorMessage;
  bool get isSuccess => errorMessage == null;
}

final profileControllerProvider =
    NotifierProvider.autoDispose<ProfileController, ProfileState>(
      ProfileController.new,
    );

class ProfileController extends AutoDisposeNotifier<ProfileState> {
  late final UserRepository _repository;

  @override
  ProfileState build() {
    _repository = ref.watch(userRepositoryProvider);
    _load();
    return const ProfileLoading();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      state = ProfileReady(profile: await _repository.getProfile());
    } catch (error) {
      state = ProfileFailure(_message(error, '用户资料加载失败，请重试'));
    }
  }

  Future<ProfileSaveResult> save({required String? displayName}) async {
    final current = state;
    if (current is! ProfileReady || current.saving) {
      return const ProfileSaveResult.failure('当前无法保存，请稍后重试');
    }
    state = ProfileReady(profile: current.profile, saving: true);
    try {
      final profile = await _repository.updateProfile(displayName: displayName);
      state = ProfileReady(profile: profile);
      return const ProfileSaveResult.success();
    } catch (error) {
      state = ProfileReady(profile: current.profile);
      return ProfileSaveResult.failure(_message(error, '用户资料保存失败，请重试'));
    }
  }

  String _message(Object error, String fallback) {
    return error is ApiException ? error.message : fallback;
  }
}
