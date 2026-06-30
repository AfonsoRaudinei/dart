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

class ReportBrandingState {
  final String? brandName;
  final String? logoPath;

  const ReportBrandingState({this.brandName, this.logoPath});

  bool get hasCustomBrandName => (brandName ?? '').trim().isNotEmpty;
  bool get hasCustomLogo => (logoPath ?? '').trim().isNotEmpty;
  bool get isCustomized => hasCustomBrandName || hasCustomLogo;

  ReportBrandingState copyWith({String? brandName, String? logoPath}) {
    return ReportBrandingState(
      brandName: brandName ?? this.brandName,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}
