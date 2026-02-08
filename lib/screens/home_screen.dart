import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/categories.dart';
import '../providers/vocab_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _showProfileDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          String userName = 'Đang tải...';
          String email = user.email ?? 'Không có email';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            userName = data?['userName'] ?? 'Chưa cập nhật';
          } else if (snapshot.hasError) {
            userName = 'Lỗi khi tải';
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                SizedBox(width: 10),
                Text('Thông tin tài khoản'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Họ và tên:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(userName),
                const SizedBox(height: 12),
                const Text('Email:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(email),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi Nhớ Từ Vựng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Tiến trình',
            onPressed: () => Navigator.pushNamed(context, '/progress'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Thông tin cá nhân',
            onPressed: () => _showProfileDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Consumer<VocabProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final isNarrow = MediaQuery.of(context).size.width < 600;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: EdgeInsets.all(isNarrow ? 16 : 24),
                child: isNarrow ? _buildMobileGrid(context, provider) : _buildWebGrid(context, provider),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileGrid(BuildContext context, VocabProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.95,
      padding: const EdgeInsets.only(bottom: 24),
      children: kCategories.map((cat) => _CategoryCard(
        category: cat,
        topicCount: cat.id == CategoryIds.grade
            ? provider.filteredTopics.where((t) => t.categoryId == CategoryIds.grade).length
            : provider.getTopicsByCategory(cat.id).length,
        onTap: () {
          if (cat.id == CategoryIds.grade) {
            Navigator.pushNamed(context, '/grade-levels');
          } else {
            Navigator.pushNamed(
              context,
              '/category-topics',
              arguments: cat.id,
            );
          }
        },
      )).toList(),
    );
  }

  Widget _buildWebGrid(BuildContext context, VocabProvider provider) {
    return GridView.count(
      crossAxisCount: kIsWeb ? 3 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      padding: const EdgeInsets.only(bottom: 24),
      children: kCategories.map((cat) => _CategoryCard(
        category: cat,
        topicCount: cat.id == CategoryIds.grade
            ? provider.filteredTopics.where((t) => t.categoryId == CategoryIds.grade).length
            : provider.getTopicsByCategory(cat.id).length,
        onTap: () {
          if (cat.id == CategoryIds.grade) {
            Navigator.pushNamed(context, '/grade-levels');
          } else {
            Navigator.pushNamed(
              context,
              '/category-topics',
              arguments: cat.id,
            );
          }
        },
      )).toList(),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AppCategory category;
  final int topicCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.topicCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '$topicCount topic',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
