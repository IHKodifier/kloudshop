import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/blog.dart';
import 'package:kloudshop/services/api_service.dart';

final blogPostsProvider = FutureProvider<List<BlogPost>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.listBlogPosts();
});
