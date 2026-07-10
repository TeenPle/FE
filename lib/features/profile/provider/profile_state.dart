import '../models/board_display_profile_model.dart';
import '../models/profile_model.dart';

class ProfileState {
  final ProfileModel? profile;
  final List<BoardDisplayProfileModel> boardProfiles;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final bool shouldGoToLogin;

  const ProfileState({
    this.profile,
    this.boardProfiles = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.shouldGoToLogin = false,
  });

  ProfileState copyWith({
    ProfileModel? profile,
    List<BoardDisplayProfileModel>? boardProfiles,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    bool? shouldGoToLogin,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      boardProfiles: boardProfiles ?? this.boardProfiles,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      shouldGoToLogin: shouldGoToLogin ?? this.shouldGoToLogin,
    );
  }
}
