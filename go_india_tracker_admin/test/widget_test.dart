import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:go_india_tracker_admin/main.dart';

void main() {
  testWidgets('App boots into a router-driven MaterialApp', (tester) async {
    // No stored auth token → app should start at the login route.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}