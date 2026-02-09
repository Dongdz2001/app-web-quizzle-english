import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      builder: (dialogContext) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          String userName = 'Đang tải...';
          String email = user.email ?? 'Không có email';
          String? classCode;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            userName = data?['userName'] as String? ?? 'Chưa cập nhật';
            classCode = data?['classCode'] as String?;
          } else if (snapshot.hasError) {
            userName = 'Lỗi khi tải';
          }

          final classCodeDisplay = classCode?.isNotEmpty == true ? classCode! : 'Chưa có';

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                SizedBox(width: 10),
                Text('Thông tin tài khoản'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Họ và tên:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(userName)),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Sửa họ và tên',
                        onPressed: () => _showEditNameDialog(dialogContext, user.uid, userName),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Email:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(email),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Mã lớp:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(classCodeDisplay)),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        tooltip: 'Sao chép mã lớp',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: classCode ?? ''));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã sao chép mã lớp')),
                            );
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditNameDialog(BuildContext context, String uid, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa họ và tên'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Họ và tên',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && context.mounted) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'userName': result});
        if (context.mounted) {
          Navigator.of(context).pop(); // đóng dialog thông tin tài khoản
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật họ và tên'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
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
        title: Consumer<VocabProvider>(
          builder: (context, provider, _) {
            if (provider.isAdmin) {
              return Row(
                children: [
                  const Text('Admin'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: provider.adminViewingClassCode,
                        hint: const Text('Xem tất cả lớp', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        dropdownColor: Theme.of(context).colorScheme.primary,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tất cả các lớp'),
                          ),
                          ...provider.availableClasses.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('Lớp $c'),
                          )),
                        ],
                        onChanged: (value) {
                          provider.setAdminViewingClass(value);
                        },
                      ),
                    ),
                  ),
                ],
              );
            }
            return const Text('Ghi Nhớ Từ Vựng');
          },
        ),
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
