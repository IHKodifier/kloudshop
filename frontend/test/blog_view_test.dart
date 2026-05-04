import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/views/blog_view.dart';
import 'package:kloudshop/providers/blog_providers.dart';
import 'package:kloudshop/models/blog.dart';
import 'package:kloudshop/models/user_claims.dart';

void main() {
  final mockClaims = UserClaims(
    uid: 'test-user',
    email: 'test@example.com',
    tenantId: 'test-tenant',
    roles: ['admin'],
    isOwner: true,
    accountType: 'merchant',
  );

  testWidgets('BlogView displays posts correctly', (tester) async {
    final mockPosts = [
      BlogPost(
        id: '1',
        title: 'Test Post 1',
        slug: 'test-post-1',
        excerpt: 'Excerpt 1',
        createdAt: DateTime.now(),
        categories: [BlogCategory(id: 'c1', name: 'News', slug: 'news', sortOrder: 0)],
        tags: [],
      ),
      BlogPost(
        id: '2',
        title: 'Test Post 2',
        slug: 'test-post-2',
        excerpt: 'Excerpt 2',
        createdAt: DateTime.now(),
        categories: [],
        tags: [],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blogPostsProvider.overrideWith((ref) => Future.value(mockPosts)),
        ],
        child: MaterialApp(
          home: BlogView(claims: mockClaims),
        ),
      ),
    );

    // Wait for the loading state to finish
    await tester.pump();

    // Verify titles are displayed
    expect(find.text('Test Post 1'), findsOneWidget);
    expect(find.text('Test Post 2'), findsOneWidget);
    expect(find.text('Excerpt 1'), findsOneWidget);
    
    // Verify status badges (default to DRAFT in my mock logic or whatever the backend returns)
    // Actually my model has status: json['status'] which is null in mock if not set
    // My _StatusBadge defaults to DRAFT if null/draft
    expect(find.text('DRAFT'), findsNWidgets(2));
  });

  testWidgets('BlogView displays empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blogPostsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp(
          home: BlogView(claims: mockClaims),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('No blog posts yet'), findsOneWidget);
  });
}
