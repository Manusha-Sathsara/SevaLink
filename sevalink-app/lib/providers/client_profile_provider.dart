import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/repositories/client_profile_repository.dart';
import '../core/network/dio_client.dart';
import 'auth_provider.dart';

final clientProfileRepositoryProvider = Provider<ClientProfileRepository>((ref) {
  final dioClient = DioClient();
  return ClientProfileRepository(dioClient);
});

final clientProfileProvider = AsyncNotifierProvider<ClientProfileNotifier, ClientProfile>(() {
  return ClientProfileNotifier();
});

class ClientProfileNotifier extends AsyncNotifier<ClientProfile> {
  @override
  Future<ClientProfile> build() async {
    final repository = ref.watch(clientProfileRepositoryProvider);
    return repository.getProfile();
  }

  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String location,
  }) async {
    final repository = ref.read(clientProfileRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedProfile = await repository.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        location: location,
      );

      // Synchronize with authProvider to enable real-time dashboard updates
      final auth = ref.read(authProvider);
      ref.read(authProvider.notifier).updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        location: location,
        bio: auth.profileExtra.bio,
        hourlyRate: auth.profileExtra.hourlyRate,
      );

      return updatedProfile;
    });
  }

  Future<void> uploadProfileImage(XFile imageFile) async {
    final repository = ref.read(clientProfileRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final bytes = await imageFile.readAsBytes();
      final updatedProfile = await repository.uploadProfileImage(
        imageFile.path,
        imageFile.name,
        bytes,
      );

      // Synchronize profile image with authProvider
      ref.read(authProvider.notifier).updateProfileImage(updatedProfile.profileImageUrl);

      return updatedProfile;
    });
  }
}
