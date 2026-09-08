/// PascalCase membership statuses — exact contract strings.
class MembershipStatus {
  MembershipStatus._();

  static const String pending = 'Pending';
  static const String active = 'Active';
  static const String rejected = 'Rejected';
  static const String blocked = 'Blocked';
  static const String deactivated = 'Deactivated';

  /// Legacy docs without `status` are treated as Active.
  static String fromFirestore(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return active;
    return value;
  }

  static bool canAccessMemberHome(String status) => status == active;

  static bool canResubmit(String status) => status == rejected;
}

/// Allowed `reviewPlatform` values.
class ReviewPlatform {
  ReviewPlatform._();

  static const String google = 'google';
  static const String tripadvisor = 'tripadvisor';

  static const List<String> values = [google, tripadvisor];

  static bool isValid(String? value) =>
      value != null && values.contains(value);
}
