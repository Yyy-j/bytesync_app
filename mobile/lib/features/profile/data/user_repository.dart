import '../domain/user_profile.dart';

abstract interface class UserRepository {
  Future<UserProfile> getProfile();

  Future<UserProfile> updateNutritionGoals(NutritionGoals goals);

  Future<UserProfile> updateProfile({required String? displayName});
}
