import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';

class ClientProfile {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? location;
  final String? profileImageUrl;
  final String createdAt;

  ClientProfile({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.location,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    final rawImageUrl = json['profileImageUrl'] as String?;
    return ClientProfile(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      location: json['location'],
      profileImageUrl: rawImageUrl != null && rawImageUrl.isNotEmpty
          ? ApiEndpoints.rewriteImageUrl(rawImageUrl)
          : null,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class ClientProfileRepository {
  final DioClient _dioClient;

  ClientProfileRepository(this._dioClient);

  Future<ClientProfile> getProfile() async {
    try {
      final response = await _dioClient.dio.get('/client/profile');
      if (response.statusCode == 200) {
        return ClientProfile.fromJson(response.data['data']);
      }
      throw Exception('Failed to fetch profile');
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<ClientProfile> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String location,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        '/client/profile',
        data: {
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'location': location,
        },
      );
      if (response.statusCode == 200) {
        return ClientProfile.fromJson(response.data['data']);
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<ClientProfile> uploadProfileImage(String filePath, String fileName, List<int> bytes) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dioClient.dio.post(
        '/client/profile/image',
        data: formData,
      );
      if (response.statusCode == 200) {
        return ClientProfile.fromJson(response.data['data']);
      }
      throw Exception('Failed to upload profile image');
    } catch (e) {
      throw Exception('Error uploading profile image: $e');
    }
  }
}
