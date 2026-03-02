import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unifind_flutter/main.dart';

void main() {
  testWidgets('browsing is restricted until user logs in',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniFindApp());

    expect(find.text('UniFind Login'), findsOneWidget);
    expect(find.text('Sign in to browse listings'), findsOneWidget);
    expect(find.text('List an Item'), findsNothing);
  });

  testWidgets('login with valid credentials opens marketplace listings',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniFindApp());

    await tester.enterText(
        find.byType(TextFormField).at(0), 'student@montclair.edu');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Search marketplace...'), findsOneWidget);
    expect(find.text('List an Item'), findsOneWidget);
    expect(find.text('Chemistry Textbook - 11th Edition'), findsOneWidget);
  });

  testWidgets('invalid login input keeps user on login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniFindApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Sign in to browse listings'), findsOneWidget);
  });

  testWidgets('marketplace cards show name, price, category, and image',
      (WidgetTester tester) async {
    final item = MarketplaceItem(
      id: 't1',
      title: 'Demo Listing',
      price: 99,
      description: 'desc',
      category: 'UniqueCategory',
      condition: 'Good',
      image: 'https://example.com/image.png',
      seller: 'tester',
      createdAt: DateTime(2026, 2, 26),
      location: 'Blanton Hall',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarketplaceScreen(
            items: [item],
            onListItem: _noop,
          ),
        ),
      ),
    );

    expect(find.text('Demo Listing'), findsOneWidget);
    expect(find.text('\$99'), findsOneWidget);
    expect(find.text('UniqueCategory'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('marketplace handles empty listings',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarketplaceScreen(
            items: [],
            onListItem: _noop,
          ),
        ),
      ),
    );

    expect(find.text('No listings yet'), findsOneWidget);
    expect(find.text('List an Item'), findsNWidgets(2));
  });

  testWidgets('my listings view includes List an Item action',
      (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyListingsScreen(
            marketplaceItems: const [],
            lostFoundItems: const [],
            onListItem: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('List an Item'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}

void _noop() {}
