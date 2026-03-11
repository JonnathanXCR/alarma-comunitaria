import 'package:flutter/foundation.dart';

/// Variable global que indica si hay una alerta activa.
/// Puede ser modificada de forma global desde un handler de Firebase Messages.
final ValueNotifier<bool> globalHasActiveAlert = ValueNotifier<bool>(false);
