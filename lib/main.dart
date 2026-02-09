import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase/firebase_init.dart';
import 'providers/vocab_provider.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/category_topics_screen.dart';
import 'screens/grade_levels_screen.dart';
import 'screens/home_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/login_screen.dart';
import 'screens/name_setup_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/topic_detail_screen.dart';
import 'styles/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  bool firebaseInitialized = false;
  try {
    await initializeFirebase();
    firebaseInitialized = true;
    print('Firebase initialized successfully');
  } catch (e) {
    print('Warning: Firebase initialization failed: $e');
    print('App will continue without Firebase authentication');
    // Continue app execution even if Firebase fails
  }
  
  runApp(VocabApp(firebaseInitialized: firebaseInitialized));
}

class VocabApp extends StatelessWidget {
  final bool firebaseInitialized;
  
  const VocabApp({super.key, this.firebaseInitialized = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VocabProvider()..loadData(),
      child: MaterialApp(
        title: 'Vocab Web App - Ghi Nhớ Từ Vựng',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: '/',
        routes: {
          '/': (_) => firebaseInitialized ? const AuthWrapper() : const HomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/admin/login': (_) => const LoginScreen(isAdminLogin: true),
          '/admin': (_) => const AdminDashboardScreen(),
          '/home': (_) => const HomeScreen(),
          '/grade-levels': (_) => const GradeLevelsScreen(),
          '/category-topics': (_) => const CategoryTopicsScreen(),
          '/topic': (_) => const TopicDetailScreen(),
          '/learn': (_) => const LearnScreen(),
          '/practice': (_) => const PracticeScreen(),
          '/quiz': (_) => const QuizScreen(),
          '/progress': (_) => const ProgressScreen(),
        },
      ),
    );
  }
}

/// Widget wrapper để kiểm tra authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      // Kiểm tra Firebase Auth có sẵn sàng không
      final auth = FirebaseAuth.instance;
      
      return StreamBuilder<User?>(
        stream: auth.authStateChanges(),
        builder: (context, snapshot) {
          // Xử lý lỗi
          if (snapshot.hasError) {
            print('Auth error: ${snapshot.error}');
            // Nếu có lỗi, hiển thị login screen
            return const LoginScreen();
          }

          // Đang kiểm tra authentication
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Chưa đăng nhập -> hiển thị login screen
          if (snapshot.data == null) {
            return const LoginScreen();
          }

          // Đã đăng nhập -> kiểm tra admin
          final user = snapshot.data!;
          final isAdmin = user.email?.toLowerCase() == 'adminchi@gmail.com';

          if (isAdmin) {
            // Cập nhật profile admin vào provider
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<VocabProvider>(context, listen: false).setUserProfile(null, true);
            });
            return const AdminDashboardScreen();
          }

          // User thường -> kiểm tra trạng thái isLogin và userName trong Firestore
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasError) {
                return const LoginScreen();
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                
                // Cập nhật profile vào provider
                final classCode = userData['classCode'] as String?;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Provider.of<VocabProvider>(context, listen: false).setUserProfile(classCode, false);
                });

                // 1. Kiểm tra quyền đăng nhập
                final isLogin = userData['isLogin'] ?? true;
                if (!isLogin) {
                  // Tự động đăng xuất nếu bị vô hiệu hóa
                  Future.microtask(() => FirebaseAuth.instance.signOut());
                  return const LoginScreen();
                }

                // 2. Kiểm tra thông tin tên (User Profile)
                final userName = userData['userName'] as String?;
                if (userName == null || userName.trim().isEmpty) {
                  return NameSetupScreen(uid: user.uid);
                }
                
                // Nếu mọi thứ OK -> Home
                return const HomeScreen();
              }
              
              // Trong khi chờ snapshot đầu tiên
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Fallback mặc định
              return const HomeScreen();
            },
          );
        },
      );
    } catch (e) {
      print('Error in AuthWrapper: $e');
      // Nếu có lỗi, hiển thị login screen
      return const LoginScreen();
    }
  }
}
