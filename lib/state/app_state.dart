import 'package:flutter/foundation.dart';

class AppState {
  static int? currentUserId;
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);
}
