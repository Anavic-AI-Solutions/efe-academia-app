import 'package:efe_mobile/core/widgets/status_badge.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/features/students/screens/widgets/student_card.dart';
import 'package:efe_mobile/features/students/screens/widgets/student_detail_header.dart';
import 'package:efe_mobile/features/students/screens/widgets/student_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

void main() {
  testWidgets('StudentCard muestra el estado normalizado', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: StudentCard(
            student: const StudentModel(id: 's1', status: 'approved'),
          ),
        ),
      ),
    );

    expect(find.text('Aprobado'), findsOneWidget);
    expect(find.text('approved'), findsNothing);
  });

  testWidgets('StudentCard oculta el badge si el estado está vacío',
      (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: StudentCard(student: const StudentModel(id: 's1')),
        ),
      ),
    );

    expect(find.byType(StatusBadge), findsNothing);
  });

  testWidgets('StudentCard muestra un estado desconocido crudo y sin romper',
      (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: StudentCard(
            student: const StudentModel(id: 's1', status: 'active'),
          ),
        ),
      ),
    );

    expect(find.text('active'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StudentTile muestra el estado normalizado', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: StudentTile(
            student: const StudentModel(id: 's1', status: 'pending'),
          ),
        ),
      ),
    );

    expect(find.text('Pendiente'), findsOneWidget);
  });

  testWidgets('StudentDetailHeader muestra el estado normalizado',
      (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: StudentDetailHeader(
            student: const StudentModel(id: 's1', status: 'rejected'),
          ),
        ),
      ),
    );

    expect(find.text('Rechazado'), findsOneWidget);
  });
}