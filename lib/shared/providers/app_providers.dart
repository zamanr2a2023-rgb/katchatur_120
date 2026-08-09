import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';

/// Example provider — add feature providers under each feature folder.
final appNameProvider = Provider<String>((ref) {
  return AppConstants.appName;
});
