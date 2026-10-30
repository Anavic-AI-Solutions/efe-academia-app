import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hijo seleccionado por el padre para filtrar aulas/cuotas.
/// `null` = ningún hijo seleccionado todavía.
final parentSelectedStudentProvider = StateProvider<String?>((ref) => null);
