import 'package:efe_mobile/features/dashboard/domain/parent_home_data.dart';
import 'package:efe_mobile/features/dashboard/screens/widgets/parent_child_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

const _ana = ParentChildSummary(
  userId: 11,
  studentId: 's-ana',
  name: 'Ana Pérez',
  classroomName: '3G X',
  classroomsCount: 1,
  year: '3',
  averageGrade: 7.9,
  attendanceRate: 95.0,
);

void main() {
  testWidgets('renders name, subtitle and stats', (tester) async {
    await tester.pumpWidget(localizedApp(
      home: Scaffold(
        body: ParentChildCard(name: 'Ana Pérez', summary: _ana, onTap: () {}),
      ),
    ));
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('3G X · 3° año'), findsOneWidget);
    expect(find.text('7.9'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.text('Promedio'), findsOneWidget);
    expect(find.text('Asistencia'), findsOneWidget);
  });

  testWidgets('shows dashes and hides subtitle without summary data',
      (tester) async {
    await tester.pumpWidget(localizedApp(
      home: Scaffold(
        body: ParentChildCard(name: 'Bruno Pérez', summary: null, onTap: () {}),
      ),
    ));
    expect(find.text('—'), findsNWidgets(2));
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('tapping triggers the callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(localizedApp(
      home: Scaffold(
        body: ParentChildCard(
          name: 'Ana Pérez',
          summary: _ana,
          onTap: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.text('Ana Pérez'));
    expect(taps, 1);
  });
}
