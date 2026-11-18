import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_shortener/screens/auth_screen.dart';
import 'package:url_shortener/providers/providers.dart';

// Mock AuthNotifier that returns a loaded, non-authenticated state immediately
class MockAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState(isAuthenticated: false, isLoading: false);
  }
}

void main() {
  testWidgets('Verify AuthScreen form elements and tab switching', (WidgetTester tester) async {
    // Set larger surface size to prevent layout clipping in test window
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 1. Build our AuthScreen widget inside ProviderScope with overridden authProvider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthNotifier()),
        ],
        child: const MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );

    // 2. Verify that the AuthScreen starts on the Login tab
    expect(find.text('Login to Account'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Security Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // 3. Toggle to Signup Mode by tapping the toggle button
    await tester.tap(find.text('Need an account? Signup'));
    await tester.pumpAndSettle();

    // 4. Verify that the screen switches to Signup Mode
    expect(find.text('Create new Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Register Account'), findsOneWidget);

    // 5. Toggle back to Login Mode
    await tester.tap(find.text('Already have an account? Login'));
    await tester.pumpAndSettle();
    
    // Verify we are back on Login Screen
    expect(find.text('Login to Account'), findsOneWidget);
  });
}
