class ProfileState {
  final String? imagePath;
  final bool useAsAppIcon;

  const ProfileState({this.imagePath, this.useAsAppIcon = false});

  ProfileState copyWith({String? imagePath, bool? useAsAppIcon}) {
    return ProfileState(
      imagePath: imagePath ?? this.imagePath,
      useAsAppIcon: useAsAppIcon ?? this.useAsAppIcon,
    );
  }
}
