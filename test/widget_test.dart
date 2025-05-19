// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:applensys/main.dart';

void main() {
  testWidgets('LoaderScreen muestra spinner blanco', (WidgetTester tester) async {
    // Construir la app
    await tester.pumpWidget(const MyApp());
    // Procesar primer frame y callbacks
    await tester.pump();

    // Debe mostrar indicador de progreso en carga inicial
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Asegurar que no queden timers pendientes
    await tester.pumpAndSettle();
  });
}
