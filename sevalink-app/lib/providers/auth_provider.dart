import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../data/repositories/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/auth_models.dart';
import '../data/models/user.dart';

//  SharedPreferences keys
const _kName      = 'profile_name';
const _kPhone     = 'profile_phone';
const _kLocation  = 'profile_location';
const _kBio       = 'profile_bio';
const _kRate      = 'profile_rate';
const _kImagePath = 'profile_image_path';

// ProfileExtra
class ProfileExtra {
  final String location;
  final String bio;
  final String hourlyRate;
  final String? profileImagePath;

  const ProfileExtra({
    this.location = 'Colombo, Sri Lanka',
    this.bio = 'Experienced electrician with 8+ years working on residential and commercial projects.',
    this.hourlyRate = '2,500',
    this.profileImagePath,
  });

  ProfileExtra copyWith({
    String? location,
    String? bio,
    String? hourlyRate,
    String? profileImagePath,
    bool clearProfileImage = false,
  }) {
    return ProfileExtra(
      location: location ?? this.location,
      bio: bio ?? this.bio,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      profileImagePath:
          clearProfileImage ? null : (profileImagePath ?? this.profileImagePath),
    );
  }
}

//  Providers
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
final dioClientProvider = Provider((ref) => DioClient());
final authRepositoryProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRepository(dioClient);
});

//  AuthState
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final ProfileExtra profileExtra;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    ProfileExtra? profileExtra,
  }) : profileExtra = profileExtra ?? const ProfileExtra();

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    ProfileExtra? profileExtra,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profileExtra: profileExtra ?? this.profileExtra,
    );
  }
}

//  AuthNotifier
class AuthNotifier extends Notifier<AuthState> {
  late AuthRepository _repository;
  late FlutterSecureStorage _secureStorage;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _secureStorage = ref.watch(secureStorageProvider);
    _loadUser();
    return AuthState(isLoading: true);
  }

  //  Load user from API + restore saved profile from disk
  Future<void> _loadUser() async {
    try {
      final token = await _secureStorage.read(key: 'access_token');
      if (token != null) {
        final user = await _repository.getCurrentUser();

        // Restore saved profile overrides from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final savedName  = prefs.getString(_kName);
        final savedPhone = prefs.getString(_kPhone);
        final extra = ProfileExtra(
          location:         prefs.getString(_kLocation)  ?? 'Colombo, Sri Lanka',
          bio:              prefs.getString(_kBio)        ?? 'Experienced electrician with 8+ years working on residential and commercial projects.',
          hourlyRate:       prefs.getString(_kRate)       ?? '2,500',
          profileImagePath: prefs.getString(_kImagePath),
        );

        // Apply local name/phone overrides if user previously edited them
        final effectiveUser = User(
          id:          user.id,
          fullName:    savedName  ?? user.fullName,
          email:       user.email,
          phoneNumber: savedPhone ?? user.phoneNumber,
          role:        user.role,
        );

        state = state.copyWith(
          user: effectiveUser,
          profileExtra: extra,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      await logout();
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  //  Save all profile fields to disk
  Future<void> _saveProfileToPrefs({
    required String fullName,
    required String phoneNumber,
    required String location,
    required String bio,
    required String hourlyRate,
    String? imagePath,
    bool clearImage = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName,     fullName);
    await prefs.setString(_kPhone,    phoneNumber);
    await prefs.setString(_kLocation, location);
    await prefs.setString(_kBio,      bio);
    await prefs.setString(_kRate,     hourlyRate);
    if (clearImage) {
      await prefs.remove(_kImagePath);
    } else if (imagePath != null) {
      await prefs.setString(_kImagePath, imagePath);
    }
  }


  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String identifier, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final req = LoginRequest(identifier: identifier, password: password);
      final data = await _repository.login(req);
      await _secureStorage.write(key: 'access_token',  value: data['accessToken']);
      await _secureStorage.write(key: 'refresh_token', value: data['refreshToken']);
      final user = User.fromJson(data['user']);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<bool> register(RegisterRequest request) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await _repository.register(request);
      await _secureStorage.write(key: 'access_token',  value: data['accessToken']);
      await _secureStorage.write(key: 'refresh_token', value: data['refreshToken']);
      final user = User.fromJson(data['user']);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Update profile (in-memory + disk) ────────────────────────────────────
  void updateProfile({
    required String fullName,
    required String phoneNumber,
    required String location,
    required String bio,
    required String hourlyRate,
  }) {
    final updatedUser = state.user == null
        ? null
        : User(
            id:          state.user!.id,
            fullName:    fullName,
            email:       state.user!.email,
            phoneNumber: phoneNumber,
            role:        state.user!.role,
          );
    state = state.copyWith(
      user: updatedUser,
      profileExtra: state.profileExtra.copyWith(
        location:   location,
        bio:        bio,
        hourlyRate: hourlyRate,
      ),
    );
    // Persist to disk
    _saveProfileToPrefs(
      fullName:    fullName,
      phoneNumber: phoneNumber,
      location:    location,
      bio:         bio,
      hourlyRate:  hourlyRate,
      imagePath:   state.profileExtra.profileImagePath,
    );
  }

  // ── Update profile image (in-memory + disk) ───────────────────────────────
  void updateProfileImage(String? imagePath) {
    state = state.copyWith(
      profileExtra: imagePath == null
          ? state.profileExtra.copyWith(clearProfileImage: true)
          : state.profileExtra.copyWith(profileImagePath: imagePath),
    );
    // Persist to disk
    _saveProfileToPrefs(
      fullName:    state.user?.fullName    ?? '',
      phoneNumber: state.user?.phoneNumber ?? '',
      location:    state.profileExtra.location,
      bio:         state.profileExtra.bio,
      hourlyRate:  state.profileExtra.hourlyRate,
      imagePath:   imagePath,
      clearImage:  imagePath == null,
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  // Note: profile prefs are intentionally NOT cleared on logout so the
  // user's edits are restored when they log back in.
  Future<bool> logout() async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.logout();
      await _secureStorage.deleteAll();
      state = AuthState();
      return true;
    } catch (e) {
      await _secureStorage.deleteAll();
      state = AuthState();
      return true;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
