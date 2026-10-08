import 'package:flutter/foundation.dart';

class PosSyncViewModel extends ChangeNotifier {
  static const String unavailableMessage =
      'Server order upload is unavailable until an authorized write path is provided.';

  String get message => unavailableMessage;
  bool get canSubmitOrders => false;
}
