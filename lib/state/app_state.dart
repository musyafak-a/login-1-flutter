import 'package:flutter/foundation.dart';

class AppState {
  static int? currentUserId;
  static String? currentUserName;
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);
}
