import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miaged/add_activity_screen.dart';

void main() {
  for (final width in [360.0, 1100.0]) {
    testWidgets('Le formulaire reste utilisable à une largeur de $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: AddActivityScreen()));

      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Informations de l’activité'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(2), '12abc');
      await tester.enterText(fields.at(3), '35xyz');
      expect(tester.widget<TextFormField>(fields.at(2)).controller!.text, '12');
      expect(tester.widget<TextFormField>(fields.at(3)).controller!.text, '35');
      final save = tester.widget<ElevatedButton>(
        find.byWidgetPredicate((widget) => widget is ElevatedButton),
      );
      expect(save.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
