import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unifind_flutter/main.dart';

void main() {
  testWidgets('app opens on landing page before login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniFindApp());

    expect(find.text('Your Campus.\nYour Marketplace.'), findsOneWidget);
    expect(find.text('Welcome back!'), findsNothing);
  });

  testWidgets('landing login button opens sign in screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniFindApp());
    await tester.tap(find.text('Log In').first);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Sign in to your UniFind account'), findsOneWidget);
  });

  testWidgets('invalid login input keeps user on login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniFindApp());

    await tester.tap(find.text('Log In').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Welcome back!'), findsOneWidget);
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
      sellerEmail: 'tester@example.com',
      createdAt: DateTime(2026, 2, 26),
      location: 'Blanton Hall',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarketplaceScreen(
            items: [item],
            onListItem: _noop,
            currentUserEmail: 'tester@example.com',
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
            currentUserEmail: '',
          ),
        ),
      ),
    );

    expect(find.text('No items found'), findsOneWidget);
    expect(find.text('List an Item'), findsOneWidget);
  });

  testWidgets('my listings view includes New Post action',
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
            onEditMarketplace: (_, __) async {},
            onEditLostFound: (_, __) async {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('New Post'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}

void _noop() {}
