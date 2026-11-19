import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miaged/activity_card.dart';

void main() {
  testWidgets('La carte reste lisible sur mobile avec un texte agrandi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SizedBox(
              height: 477,
              child: ActivityCard(
                title: 'Atelier de cuisine et découverte des pâtes fraîches',
                location: 'Atelier cuisine, centre-ville de Nice',
                category: 'Gastronomie',
                imageUrl: 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
                price: 35,
                onTap: () => opened = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Voir le détail'));
    expect(opened, isTrue);
  });
}
