// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmoney/main.dart';
import 'package:medmoney/screens/home_page.dart';

void main() {
  testWidgets('Home page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: HomePage(),
    ));

    // Verificar se elementos importantes da página inicial estão presentes
    expect(find.text('Simplifique suas Finanças'), findsOneWidget);
    expect(find.text('Começar Agora'), findsOneWidget);
    expect(find.text('Benefícios Principais'), findsOneWidget);
    expect(find.text('Como Funciona'), findsOneWidget);
    expect(find.text('Planos e Preços'), findsOneWidget);
  });
}
