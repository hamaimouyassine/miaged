import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miaged/main.dart';

void main() {
  testWidgets('Le login reste utilisable avec des champs vides', (
    tester,
  ) async {
    await tester.pumpWidget(const MiagedApp());

    expect(find.text('MIAGED'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    final password = tester.widget<TextField>(find.byType(TextField).last);
    expect(password.obscureText, isTrue);

    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(find.text('Veuillez remplir tous les champs.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField).first, 'user1');
    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(find.text('Veuillez remplir tous les champs.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('L’inscription vérifie les champs et la confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(const MiagedApp());
    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Créer mon compte'));
    await tester.tap(find.text('Créer mon compte'));
    await tester.pump();
    expect(find.text('Saisissez un login.'), findsOneWidget);
    expect(find.text('Saisissez un mot de passe.'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'testmiage1');
    await tester.enterText(fields.at(1), 'MiageTest1!');
    await tester.enterText(fields.at(2), 'different');
    await tester.ensureVisible(find.text('Créer mon compte'));
    await tester.tap(find.text('Créer mon compte'));
    await tester.pump();
    expect(
      find.text('Les mots de passe doivent être identiques.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Le login tient dans un écran mobile', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiagedApp());
    await tester.ensureVisible(find.text('Se connecter'));
    expect(tester.takeException(), isNull);
  });
}
