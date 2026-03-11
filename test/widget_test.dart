import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alarma_comunitaria/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AlarmaComunitariaApp());
    expect(find.byType(MaterialApp), findsNothing); // router-based app
  });
}
