import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/repositories/client_profile_repository.dart';
import '../core/network/dio_client.dart';

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
    state = await AsyncValue.guard(() => repository.updateProfile(
          fullName: fullName,
          phoneNumber: phoneNumber,
          location: location,
        ));
  }

  Future<void> uploadProfileImage(XFile imageFile) async {
    final repository = ref.read(clientProfileRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final bytes = await imageFile.readAsBytes();
      return repository.uploadProfileImage(
        imageFile.path,
        imageFile.name,
        bytes,
      );
    });
  }
}
