import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/vocab_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _classCodeController = TextEditingController(); // Vẫn giữ để fallback hoặc dùng class selection thay thế
  
  // Controllers cho tạo hàng loạt
  final _bulkQuantityController = TextEditingController(text: '10');
  final _bulkPrefixController = TextEditingController(text: 'user');
  final _bulkSuffixController = TextEditingController(text: 'quizzle.com');
  final _bulkClassCodeController = TextEditingController();
  
  // Filter và selection
  final _filterController = TextEditingController();
  final _prefixFilterController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  DateTime? _startDate;
  DateTime? _endDate;
  
  bool _isLoading = false;
  bool _isBulkLoading = false;
  bool _isCheckingUser = true; // Đang kiểm tra user
  String? _errorMessage;
  String? _successMessage;
  String? _bulkErrorMessage;
  String? _bulkSuccessMessage;
  
  List<String> _classes = [];
  String? _selectedClassInDialog;

  @override
  void initState() {
    super.initState();
    _checkUserExists();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final snapshot = await _firestore.collection('classes').get();
      setState(() {
        _classes = snapshot.docs.map((doc) => doc.id).toList();
        _classes.sort();
      });
    } catch (e) {
      print('Lỗi tải danh sách lớp: $e');
    }
  }

  Future<void> _createClass(String classCode) async {
    if (classCode.isEmpty) return;
    try {
      await _firestore.collection('classes').doc(classCode).set({
        'classCode': classCode,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _loadClasses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tạo lớp $classCode thành công')),
        );
      }
    } catch (e) {
      print('Lỗi tạo lớp: $e');
    }
  }

  void _showCreateClassDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo lớp mới'),
        content: TextField(
          controller: controller,
          enableSuggestions: false,
          autocorrect: false,
          spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
          decoration: const InputDecoration(
            labelText: 'Mã lớp',
            hintText: 'VD: 12A1, K8...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim().toUpperCase();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _createClass(code);
              }
            },
            child: const Text('Tạo lớp'),
          ),
        ],
      ),
    );
  }

  /// Xóa user khỏi Firebase Auth thông qua Cloud Function
  /// Sử dụng Firebase Cloud Functions callable function
  /// Trả về true nếu xóa thành công, false nếu thất bại
  Future<bool> _deleteUserFromAuth(String userId) async {
    try {
      // Gọi Cloud Function 'deleteUserByUid'
      final callable = FirebaseFunctions.instance.httpsCallable('deleteUserByUid');
      
      // Gọi function với uid
      final result = await callable.call({'uid': userId});
      
      // Kiểm tra kết quả
      final data = result.data as Map<String, dynamic>;
      if (data['success'] == true) {
        print('Successfully deleted user $userId from Firebase Auth');
        return true;
      } else {
        print('Warning: User deletion may have failed: ${data['message']}');
        return false;
      }
    } catch (e) {
      // Xử lý lỗi từ Cloud Function
      print('Error calling deleteUserByUid Cloud Function: $e');
      return false;
    }
  }

  Future<void> _checkUserExists() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Không có user -> logout và redirect
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Kiểm tra xem có phải admin không
      final isAdmin = user.email?.toLowerCase() == 'adminchi@gmail.com';

      // Kiểm tra userId có tồn tại trong Firestore không
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Nếu là admin, tự động tạo document trong Firestore
        if (isAdmin) {
          try {
            await _firestore.collection('users').doc(user.uid).set({
              'userId': user.uid,
              'userEmail': user.email,
              'userName': null,
              'createdAt': FieldValue.serverTimestamp(),
              'isAdmin': true,
            });
            print('Auto-created admin user document in Firestore');
          } catch (e) {
            print('Error creating admin user document: $e');
            // Tiếp tục cho phép admin truy cập dù có lỗi tạo document
          }
        } else {
          // User thường không tồn tại trong Firestore -> logout và redirect
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tài khoản không tồn tại trong hệ thống'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.of(context).pushReplacementNamed('/login');
          }
          return;
        }
      }

      // User tồn tại hoặc đã được tạo -> cho phép truy cập
      if (mounted) {
        setState(() {
          _isCheckingUser = false;
        });
      }
    } catch (e) {
      print('Error checking user existence: $e');
      // Nếu có lỗi, kiểm tra lại xem có phải admin không
      final user = FirebaseAuth.instance.currentUser;
      final isAdmin = user?.email?.toLowerCase() == 'adminchi@gmail.com';
      
      if (isAdmin) {
        // Nếu là admin, vẫn cho phép truy cập dù có lỗi
        if (mounted) {
          setState(() {
            _isCheckingUser = false;
          });
        }
      } else {
        // Nếu không phải admin, logout để đảm bảo an toàn
        try {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        } catch (_) {
          // Ignore logout errors
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _classCodeController.dispose();
    _bulkQuantityController.dispose();
    _bulkPrefixController.dispose();
    _bulkSuffixController.dispose();
    _bulkClassCodeController.dispose();
    _filterController.dispose();
    _prefixFilterController.dispose();
    super.dispose();
  }

  /// Kiểm tra mã lớp có tồn tại không
  Future<bool> _checkClassCode(String classCode) async {
    if (classCode.isEmpty) return true; // Nếu để trống thì không cần kiểm tra
    
    try {
      final doc = await _firestore.collection('classes').doc(classCode).get();
      return doc.exists;
    } catch (e) {
      print('Lỗi kiểm tra mã lớp: $e');
      return false;
    }
  }

  /// Tạo mật khẩu random 12 ký tự (chữ và số)
  Future<void> _createUser() async {
    final email = _emailController.text.trim();
    final classCode = _selectedClassInDialog ?? '';

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập email';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // Bỏ qua việc check mã lớp, chỉ lưu trực tiếp
    
    try {
      // Lưu thông tin admin hiện tại
      final currentAdmin = FirebaseAuth.instance.currentUser;
      if (currentAdmin == null) {
        throw Exception('Admin chưa đăng nhập');
      }
      final adminEmail = currentAdmin.email;
      
      // Tự động tạo mật khẩu ngẫu nhiên
      final password = _generateRandomPasswordString();

      // GIẢI PHÁP: Tạo một Firebase App instance thứ 2 để tạo user
      // mà không ảnh hưởng đến session admin hiện tại
      final secondaryApp = await Firebase.initializeApp(
        name: 'Secondary',
        options: Firebase.app().options,
      );
      
      try {
        // Tạo user bằng instance thứ 2
        final userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Lưu thông tin user vào Firestore (dùng instance chính)
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'userId': userCredential.user?.uid,
          'userName': null,
          'userEmail': email,
          'password': password,
          'classCode': classCode.isNotEmpty ? classCode : null,
          'createdAt': FieldValue.serverTimestamp(),
          'isLogin': true,
          'createdBy': {
            'userId': currentAdmin.uid,
            'userEmail': adminEmail,
          },
        });

        // Đăng xuất user mới khỏi instance thứ 2
        await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
        
        // Xóa app thứ 2
        await secondaryApp.delete();

        setState(() {
          _successMessage = 'Tạo tài khoản thành công!\nEmail: $email\nMật khẩu: $password${classCode.isNotEmpty ? '\nMã lớp: $classCode' : ''}';
          _emailController.clear();
          _classCodeController.clear();
          _isLoading = false;
        });

        // Ẩn thông báo sau 8 giây (để admin copy mật khẩu)
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      } catch (e) {
        // Đảm bảo xóa secondary app nếu có lỗi
        await secondaryApp.delete();
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() {
          _errorMessage = 'Email $email đã tồn tại. Vui lòng sử dụng email khác.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      default:
        return 'Lỗi: $code';
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }


  /// Tạo hàng loạt tài khoản
  Future<void> _createBulkUsers() async {
    final quantity = int.tryParse(_bulkQuantityController.text) ?? 0;
    final prefix = _bulkPrefixController.text.trim();
    final suffix = _bulkSuffixController.text.trim();
    final classCode = _selectedClassInDialog ?? '';
    // Xóa dòng gán classCode cũ từ controller vì đã dùng Dropdown

    // Validation
    if (_bulkQuantityController.text.isEmpty ||
        prefix.isEmpty ||
        suffix.isEmpty) {
      setState(() {
        _bulkErrorMessage = 'Vui lòng điền đầy đủ thông tin';
      });
      return;
    }

    if (quantity <= 0 || quantity > 100) {
      setState(() {
        _bulkErrorMessage = 'Số lượng phải từ 1 đến 100';
      });
      return;
    }

    // Bỏ qua việc check mã lớp, chỉ lưu trực tiếp

    final currentAdmin = FirebaseAuth.instance.currentUser;
    if (currentAdmin == null) return;
    final adminEmail = currentAdmin.email;

    int successCount = 0;
    int skipCount = 0; // Số tài khoản bị bỏ qua (trùng email)
    int failCount = 0; // Số tài khoản thất bại (lỗi khác)
    final List<String> skippedEmails = []; // Email đã tồn tại
    final List<String> failedEmails = []; // Email lỗi khác

    try {
      for (int i = 1; i <= quantity; i++) {
        try {
          final email = '$prefix$i@$suffix';
          final password = _generateRandomPasswordString();

          // GIẢI PHÁP: Tạo một Firebase App instance riêng cho mỗi user (hoặc dùng 1 instance duy nhất cho batch)
          // Để đơn giản và an toàn, ta dùng 1 instance phụ cho toàn bộ batch
          final secondaryApp = await Firebase.initializeApp(
            name: 'BulkApp_$i', // Phải có tên duy nhất nếu loop nhanh
            options: Firebase.app().options,
          );

          try {
            // Tạo user trong Firebase Auth (dùng secondary app)
            final userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
                .createUserWithEmailAndPassword(
              email: email,
              password: password,
            );

            // Lưu thông tin user vào Firestore (dùng instance chính)
            await _firestore.collection('users').doc(userCredential.user?.uid).set({
              'userId': userCredential.user?.uid,
              'userName': email.split('@')[0],
              'userEmail': email,
              'password': password,
              'classCode': classCode.isNotEmpty ? classCode : null,
              'createdAt': FieldValue.serverTimestamp(),
              'isLogin': true,
              'createdBy': {
                'userId': currentAdmin.uid,
                'userEmail': adminEmail,
              },
            });

            await secondaryApp.delete();
            successCount++;
          } catch (e) {
            await secondaryApp.delete();
            rethrow;
          }
        } on FirebaseAuthException catch (e) {
          final email = '$prefix$i@$suffix';
          if (e.code == 'email-already-in-use') {
            skipCount++;
            skippedEmails.add(email);
          } else {
            failCount++;
            failedEmails.add('$email: ${_getErrorMessage(e.code)}');
          }
        } catch (e) {
          failCount++;
          final email = '$prefix$i@$suffix';
          failedEmails.add('$email: ${e.toString()}');
        }
      }
    } finally {
      setState(() {
        _isBulkLoading = false;
        _bulkClassCodeController.clear();
      });
    }

    // Cập nhật thông báo kết quả
    String resultMessage = '';
    if (successCount > 0) {
      resultMessage = 'Đã tạo thành công $successCount tài khoản';
      if (skipCount > 0) {
        resultMessage += '. Bỏ qua $skipCount tài khoản (email đã tồn tại)';
      }
      if (failCount > 0) {
        resultMessage += '. $failCount tài khoản thất bại';
      }
      setState(() {
        _bulkSuccessMessage = resultMessage;
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _bulkSuccessMessage = null;
          });
        }
      });
    } else if (skipCount > 0) {
      // Chỉ có email trùng, không có tài khoản nào được tạo
      setState(() {
        _bulkSuccessMessage = 'Đã bỏ qua $skipCount tài khoản (email đã tồn tại)';
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _bulkSuccessMessage = null;
          });
        }
      });
    }

    if (failCount > 0 && successCount == 0 && skipCount == 0) {
      setState(() {
        _bulkErrorMessage = 'Tạo thất bại: ${failedEmails.first}';
      });
    }
  }

  /// Tạo chuỗi mật khẩu random 12 ký tự
  String _generateRandomPasswordString() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random();
    return List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void _showCreateUserDialog(BuildContext context) {
    _emailController.clear();
    _selectedClassInDialog = _classes.isNotEmpty ? _classes.first : null;
    _errorMessage = null;
    _successMessage = null;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm tài khoản mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enableSuggestions: false,
                  autocorrect: false,
                  spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    hintText: 'Nhập email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedClassInDialog,
                  decoration: InputDecoration(
                    labelText: 'Chọn lớp học',
                    prefixIcon: const Icon(Icons.class_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Không chọn lớp'),
                    ),
                    ..._classes.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedClassInDialog = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mật khẩu sẽ được tự động tạo. Người dùng sẽ nhập thông tin cá nhân khi đăng nhập lần đầu.',
                          style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 16),
                                Text('Đang tạo tài khoản...'),
                              ],
                            ),
                            duration: Duration(seconds: 30),
                          ),
                        );
                      }
                      await _createUser();
                      if (mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        if (_successMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_successMessage!),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          setState(() { _successMessage = null; });
                        } else if (_errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_errorMessage!),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          setState(() { _errorMessage = null; });
                        }
                      }
                    },
              child: const Text('Tạo tài khoản'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateBulkUsersDialog(BuildContext context) {
    _bulkQuantityController.text = '10';
    _bulkPrefixController.text = 'user';
    _bulkSuffixController.text = 'quizzle.com';
    _bulkErrorMessage = null;
    _bulkSuccessMessage = null;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm nhiều tài khoản'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _bulkQuantityController,
                  keyboardType: TextInputType.number,
                  enableSuggestions: false,
                  autocorrect: false,
                  spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                  decoration: InputDecoration(
                    labelText: 'Số lượng tài khoản *',
                    hintText: 'VD: 10 (tối đa 100)',
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bulkPrefixController,
                  enableSuggestions: false,
                  autocorrect: false,
                  spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                  decoration: InputDecoration(
                    labelText: 'Tiền tố email *',
                    hintText: 'VD: user, student',
                    prefixIcon: const Icon(Icons.text_fields),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bulkSuffixController,
                  enableSuggestions: false,
                  autocorrect: false,
                  spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                  decoration: InputDecoration(
                    labelText: 'Hậu tố email (domain) *',
                    hintText: 'VD: quizzle.com, example.com',
                    prefixIcon: const Icon(Icons.domain),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedClassInDialog,
                  decoration: InputDecoration(
                    labelText: 'Chọn lớp học cho cả đoàn',
                    prefixIcon: const Icon(Icons.class_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Không chọn lớp'),
                    ),
                    ..._classes.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedClassInDialog = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preview email:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_bulkPrefixController.text.isNotEmpty &&
                          _bulkSuffixController.text.isNotEmpty)
                        ...List.generate(
                          math.min(3, int.tryParse(_bulkQuantityController.text) ?? 0),
                          (i) => Text(
                            '${_bulkPrefixController.text}${i + 1}@${_bulkSuffixController.text}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        )
                      else
                        const Text(
                          'Nhập thông tin để xem preview',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      if ((int.tryParse(_bulkQuantityController.text) ?? 0) > 3)
                        Text(
                          '... và ${(int.tryParse(_bulkQuantityController.text) ?? 0) - 3} email khác',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                if (_bulkErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _bulkErrorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_bulkSuccessMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _bulkSuccessMessage!,
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Không cần setState ở đây để tránh rebuild danh sách
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: _isBulkLoading
                  ? null
                  : () async {
                      // Đóng dialog ngay khi bắt đầu tạo
                      Navigator.of(dialogContext).pop();
                      
                      // Hiển thị SnackBar loading
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 16),
                                Text('Đang tạo tài khoản hàng loạt...'),
                              ],
                            ),
                            duration: Duration(seconds: 30), // Thời gian dài để chờ quá trình tạo
                          ),
                        );
                      }
                      
                      // Thực hiện tạo tài khoản
                      await _createBulkUsers();
                      
                      // Ẩn SnackBar loading và hiển thị kết quả
                      if (mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        if (_bulkSuccessMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_bulkSuccessMessage!),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } else if (_bulkErrorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_bulkErrorMessage!),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                          setState(() {
                            _bulkErrorMessage = null;
                            _bulkSuccessMessage = null;
                          });
                        }
                      }
                    },
                icon: const Icon(Icons.batch_prediction),
                label: const Text('Tạo hàng loạt'),
              ),
            ],
          ),
      ),
    );
  }

  Future<void> _copyAllSelectedAccountsFromIds() async {
    if (_selectedUserIds.isEmpty) return;

    try {
      final accounts = <String>[];
      
      // Lấy thông tin từ Firestore cho các user đã chọn
      for (var userId in _selectedUserIds) {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final email = data['userEmail'] as String? ?? '';
          final password = data['password'] as String? ?? '';
          if (email.isNotEmpty && password.isNotEmpty) {
            accounts.add('$email-$password');
          }
        }
      }

      if (accounts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có tài khoản nào để sao chép')),
          );
        }
        return;
      }

      final textToCopy = accounts.join('\n');
      Clipboard.setData(ClipboardData(text: textToCopy));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã sao chép ${accounts.length} tài khoản'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi sao chép: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId, String email) async {
    // Xác nhận trước khi xóa
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa tài khoản $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Xóa user trong Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Thử xóa user khỏi Firebase Auth thông qua Cloud Function
      final authDeleted = await _deleteUserFromAuth(userId);

      if (mounted) {
        if (authDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa tài khoản $email thành công (Firestore + Auth)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa $email khỏi Firestore, nhưng KHÔNG XÓA ĐƯỢC khỏi Firebase Auth. Vui lòng kiểm tra Cloud Function hoặc quyền admin.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa tài khoản: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleMultipleUsersStatus(bool disable) async {
    if (_selectedUserIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(disable ? 'Vô hiệu hóa tài khoản' : 'Kích hoạt tài khoản'),
        content: Text('Bạn có chắc chắn muốn ${disable ? "vô hiệu hóa" : "kích hoạt"} ${_selectedUserIds.length} tài khoản đã chọn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: disable ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(disable ? 'Vô hiệu hóa' : 'Kích hoạt'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang ${disable ? "vô hiệu hóa" : "kích hoạt"} tài khoản...'),
        ),
      );
    }

    try {
      final batch = _firestore.batch();
      for (var userId in _selectedUserIds) {
        batch.update(_firestore.collection('users').doc(userId), {
          'isLogin': !disable,
        });
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ${disable ? "vô hiệu hóa" : "kích hoạt"} ${_selectedUserIds.length} tài khoản thành công'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedUserIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi cập nhật trạng thái'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isLogin': !currentStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ${!currentStatus ? "kích hoạt" : "vô hiệu hóa"} tài khoản thành công'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi cập nhật trạng thái'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _bulkChangeClass(String? newClassCode) async {
    if (_selectedUserIds.isEmpty) return;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang cập nhật lớp học...'),
          duration: Duration(seconds: 30),
        ),
      );
    }

    int successCount = 0;

    try {
      final batch = _firestore.batch();
      for (var userId in _selectedUserIds) {
        final docRef = _firestore.collection('users').doc(userId);
        batch.update(docRef, {
          'classCode': newClassCode?.isNotEmpty == true ? newClassCode : null,
        });
      }
      await batch.commit();
      successCount = _selectedUserIds.length;
    } catch (e) {
      print('Lỗi cập nhật lớp học hàng loạt: $e');
    } finally {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã chuyển $successCount tài khoản sang lớp ${newClassCode?.isEmpty == true ? "Trống" : newClassCode}'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _selectedUserIds.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi cập nhật lớp học'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showChangeClassDialog(BuildContext context) {
    String? localSelectedClass = _classes.isNotEmpty ? _classes.first : '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chuyển lớp hàng loạt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Đang chọn ${_selectedUserIds.length} tài khoản'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: localSelectedClass,
                decoration: const InputDecoration(
                  labelText: 'Chọn lớp mới',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('Không chọn lớp'),
                  ),
                  ..._classes.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  )),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    localSelectedClass = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _bulkChangeClass(localSelectedClass);
              },
              child: const Text('Lưu & Thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHomeClassSelector() {
    final vocabProvider = Provider.of<VocabProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn lớp để xem'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _classes.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.apps, color: Colors.blue),
                  title: const Text('Tất cả các lớp'),
                  onTap: () {
                    vocabProvider.setAdminViewingClass(null);
                    Navigator.pop(context);
                    Navigator.of(this.context).pushNamed('/home');
                  },
                );
              }
              final classCode = _classes[index - 1];
              return ListTile(
                leading: const Icon(Icons.class_outlined, color: Colors.blue),
                title: Text('Lớp $classCode'),
                onTap: () {
                  vocabProvider.setAdminViewingClass(classCode);
                  Navigator.pop(context);
                  Navigator.of(this.context).pushNamed('/home');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingUser) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Quản Trị'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _showHomeClassSelector,
            tooltip: 'Trang chủ',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: isMobile
          ? _buildMobileLayout(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildDesktopContent(context),
            ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showMobileActionMenu(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showMobileActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_home_work),
            title: const Text('Tạo lớp mới'),
            onTap: () {
              Navigator.pop(context);
              _showCreateClassDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Thêm tài khoản mới'),
            onTap: () {
              Navigator.pop(context);
              _showCreateUserDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.batch_prediction),
            title: const Text('Thêm nhiều tài khoản'),
            onTap: () {
              Navigator.pop(context);
              _showCreateBulkUsersDialog(context);
            },
          ),
          if (_selectedUserIds.isNotEmpty) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.copy_all),
              title: const Text('Copy All Selected'),
              onTap: () {
                Navigator.pop(context);
                _copyAllSelectedAccountsFromIds();
              },
            ),
             ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text('Vô hiệu hóa đã chọn', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                _toggleMultipleUsersStatus(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outline, color: Colors.orange),
              title: const Text('Chuyển lớp đã chọn', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                _showChangeClassDialog(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Filters section - textbox full width trên mobile để dễ thấy, dễ chọn
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedUserIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Đã chọn: ${_selectedUserIds.length}', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => setState(() => _selectedUserIds.clear()),
                        child: const Text('Bỏ chọn'),
                      ),
                    ],
                  ),
                ),
              // Hai ô nhập full width, dễ thấy và dễ chọn trên mobile
              TextField(
                controller: _filterController,
                enableSuggestions: false,
                autocorrect: false,
                spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                decoration: InputDecoration(
                  labelText: 'Tìm kiếm học sinh',
                  hintText: 'Email, Tên...',
                  prefixIcon: const Icon(Icons.search, size: 22),
                  suffixIcon: _filterController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _filterController.clear();
                            setState(() {});
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _prefixFilterController,
                enableSuggestions: false,
                autocorrect: false,
                spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                decoration: InputDecoration(
                  labelText: 'Lọc theo đầu số',
                  hintText: 'VD: user...',
                  prefixIcon: const Icon(Icons.filter_list, size: 22),
                  suffixIcon: _prefixFilterController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _prefixFilterController.clear();
                            setState(() {});
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              // Date + nút hành động wrap xuống dòng
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    child: _buildDateChip(
                      context,
                      date: _startDate,
                      label: 'Từ ngày',
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      onClear: () => setState(() => _startDate = null),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: _buildDateChip(
                      context,
                      date: _endDate,
                      label: 'Đến ngày',
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      onClear: () => setState(() => _endDate = null),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectedUserIds.isEmpty ? null : _copyAllSelectedAccountsFromIds,
                    icon: const Icon(Icons.copy_all),
                    label: const Text('Copy All'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectedUserIds.isEmpty ? null : () => _toggleMultipleUsersStatus(true),
                    icon: const Icon(Icons.block),
                    label: const Text('Vô hiệu hóa'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectedUserIds.isEmpty ? null : () => _showChangeClassDialog(context),
                    icon: const Icon(Icons.drive_file_move_outline),
                    label: const Text('Chuyển lớp'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // List content
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Chưa có người dùng nào'));

              // Filter logic (same as desktop)
              final filterText = _filterController.text.toLowerCase();
              final prefixFilter = _prefixFilterController.text.toLowerCase();
              
              final filteredDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final email = ((data['userEmail'] as String? ?? '').isEmpty
                    ? (data['email'] as String? ?? '')
                    : (data['userEmail'] as String? ?? '')).toLowerCase();
                final name = (data['userName'] as String? ?? '').toLowerCase();
                final createdAt = data['createdAt'] as dynamic;
                
                if (email.isEmpty || email == 'adminchi@gmail.com') return false;
                
                bool matchesSearch = true;
                if (filterText.isNotEmpty) {
                  matchesSearch = email.contains(filterText) || name.contains(filterText);
                }
                
                bool matchesPrefix = true;
                if (prefixFilter.isNotEmpty) {
                  final emailPrefix = email.split('@').first;
                  matchesPrefix = emailPrefix.startsWith(prefixFilter);
                }
                
                bool matchesDate = true;
                if (createdAt != null && createdAt is Timestamp) {
                  final createdDate = createdAt.toDate();
                  if (_startDate != null) {
                    final startOfDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
                    matchesDate = matchesDate && createdDate.isAfter(startOfDay.subtract(const Duration(days: 1)));
                  }
                  if (_endDate != null) {
                    final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
                    matchesDate = matchesDate && createdDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
                  }
                } else {
                  if (_startDate != null || _endDate != null) matchesDate = false;
                }
                
                return matchesSearch && matchesPrefix && matchesDate;
              }).toList();

              if (filteredDocs.isEmpty) return const Center(child: Text('Không tìm thấy kết quả'));

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final userId = (data['userId'] as String? ?? '').isEmpty ? doc.id : (data['userId'] as String? ?? '');
                  final email = (data['userEmail'] as String? ?? '').isEmpty ? (data['email'] as String? ?? '') : (data['userEmail'] as String? ?? '');
                  final name = data['userName'] as String? ?? 'Chưa đặt tên';
                  final classCode = data['classCode'] as String? ?? '-';
                  final isLogin = data['isLogin'] ?? true;
                  final isSelected = _selectedUserIds.contains(userId);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
                    ),
                    elevation: 2,
                    child: InkWell(
                      onLongPress: () {
                         setState(() {
                            if (isSelected) {
                              _selectedUserIds.remove(userId);
                            } else {
                              _selectedUserIds.add(userId);
                            }
                          });
                      },
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedUserIds.remove(userId);
                          } else {
                            _selectedUserIds.add(userId);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedUserIds.add(userId);
                                      } else {
                                        _selectedUserIds.remove(userId);
                                      }
                                    });
                                  },
                                  activeColor: Colors.blue,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 20,
                                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : email[0].toUpperCase()),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text('Lớp: $classCode'),
                                  backgroundColor: Colors.blue[50], 
                                  labelStyle: TextStyle(color: Colors.blue[800], fontSize: 12),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(isLogin ? Icons.block : Icons.check_circle_outline, color: isLogin ? Colors.orange : Colors.green),
                                      onPressed: () => _toggleUserStatus(userId, isLogin),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteUser(userId, email),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Users List
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Danh sách người dùng',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (_selectedUserIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          'Đã chọn: ${_selectedUserIds.length}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showCreateClassDialog,
                      icon: const Icon(Icons.add_home_work),
                      label: const Text('Tạo lớp mới'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateUserDialog(context),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Thêm tài khoản mới'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateBulkUsersDialog(context),
                      icon: const Icon(Icons.batch_prediction),
                      label: const Text('Thêm nhiều tài khoản'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filter và Copy All
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _filterController,
                        enableSuggestions: false,
                        autocorrect: false,
                        spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                        decoration: InputDecoration(
                          labelText: 'Tìm kiếm học sinh',
                          hintText: 'Email, Tên...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _filterController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _filterController.clear();
                                    setState(() {});
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _prefixFilterController,
                        enableSuggestions: false,
                        autocorrect: false,
                        spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                        decoration: InputDecoration(
                          labelText: 'Lọc theo đầu số',
                          hintText: 'VD: user...',
                          prefixIcon: const Icon(Icons.filter_list, size: 20),
                          suffixIcon: _prefixFilterController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _prefixFilterController.clear();
                                    setState(() {});
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    // Date picker - Từ ngày
                    SizedBox(
                      width: 140,
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _startDate != null
                                      ? _formatDateOnly(_startDate!)
                                      : 'Từ ngày',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _startDate != null ? Colors.black : Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_startDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      _startDate = null;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Date picker - Đến ngày
                    SizedBox(
                      width: 140,
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _endDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _endDate != null
                                      ? _formatDateOnly(_endDate!)
                                      : 'Đến ngày',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _endDate != null ? Colors.black : Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_endDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      _endDate = null;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectedUserIds.isEmpty
                          ? null
                          : _copyAllSelectedAccountsFromIds,
                      icon: const Icon(Icons.copy_all),
                      label: const Text('Copy All'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectedUserIds.isEmpty
                          ? null
                          : () => _toggleMultipleUsersStatus(true),
                      icon: const Icon(Icons.block),
                      label: const Text('Vô hiệu hóa'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectedUserIds.isEmpty
                          ? null
                          : () => _showChangeClassDialog(context),
                      icon: const Icon(Icons.drive_file_move_outline),
                      label: const Text('Chuyển lớp'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Lỗi: ${snapshot.error}');
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'Chưa có người dùng nào',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    // Filter users
                    final filterText = _filterController.text.toLowerCase();
                    final prefixFilter = _prefixFilterController.text.toLowerCase();
                    final filteredDocs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      // Lấy email từ userEmail hoặc email (fallback)
                      final email = ((data['userEmail'] as String? ?? '').isEmpty
                          ? (data['email'] as String? ?? '')
                          : (data['userEmail'] as String? ?? '')).toLowerCase();
                      final name = (data['userName'] as String? ?? '').toLowerCase();
                      final createdAt = data['createdAt'] as Timestamp?;
                      
                      // Bỏ qua các document không có email
                      if (email.isEmpty) {
                        return false;
                      }
                      
                      // Bỏ qua tài khoản admin
                      if (email == 'adminchi@gmail.com') {
                        return false;
                      }
                      
                      // Filter theo tìm kiếm (email hoặc tên)
                      bool matchesSearch = true;
                      if (filterText.isNotEmpty) {
                        matchesSearch = email.contains(filterText) || name.contains(filterText);
                      }
                      
                      // Filter theo tiền tố email
                      bool matchesPrefix = true;
                      if (prefixFilter.isNotEmpty) {
                        // Lấy phần trước @ của email để so sánh tiền tố
                        final emailPrefix = email.split('@').first;
                        matchesPrefix = emailPrefix.startsWith(prefixFilter);
                      }
                      
                      // Filter theo ngày tạo
                      bool matchesDate = true;
                      if (createdAt != null) {
                        final createdDate = createdAt.toDate();
                        if (_startDate != null) {
                          // So sánh từ đầu ngày (00:00:00)
                          final startOfDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
                          matchesDate = matchesDate && createdDate.isAfter(startOfDay.subtract(const Duration(days: 1)));
                        }
                        if (_endDate != null) {
                          // So sánh đến cuối ngày (23:59:59)
                          final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
                          matchesDate = matchesDate && createdDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
                        }
                      } else {
                        // Nếu không có createdAt và có filter date thì không match
                        if (_startDate != null || _endDate != null) {
                          matchesDate = false;
                        }
                      }
                      
                      return matchesSearch && matchesPrefix && matchesDate;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'Không tìm thấy người dùng nào',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    // Check if all filtered users are selected
                    final allFilteredSelected = filteredDocs.isNotEmpty &&
                        filteredDocs.every((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          // Lấy userId từ field hoặc document ID
                          final userId = (data['userId'] as String? ?? '').isEmpty 
                              ? doc.id 
                              : (data['userId'] as String? ?? '');
                          return userId.isNotEmpty && _selectedUserIds.contains(userId);
                        });

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(
                            label: Checkbox(
                              value: allFilteredSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    // Select all filtered users
                                    for (var doc in filteredDocs) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      // Lấy userId từ field hoặc document ID
                                      final userId = (data['userId'] as String? ?? '').isEmpty 
                                          ? doc.id 
                                          : (data['userId'] as String? ?? '');
                                      if (userId.isNotEmpty) {
                                        _selectedUserIds.add(userId);
                                      }
                                    }
                                  } else {
                                    // Deselect all filtered users
                                    for (var doc in filteredDocs) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      // Lấy userId từ field hoặc document ID
                                      final userId = (data['userId'] as String? ?? '').isEmpty 
                                          ? doc.id 
                                          : (data['userId'] as String? ?? '');
                                      _selectedUserIds.remove(userId);
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Mã lớp', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filteredDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          // Lấy userId từ field hoặc document ID
                          final userId = (data['userId'] as String? ?? '').isEmpty 
                              ? doc.id 
                              : (data['userId'] as String? ?? '');
                          // Lấy email từ userEmail hoặc email (fallback)
                          final email = (data['userEmail'] as String? ?? '').isEmpty
                              ? (data['email'] as String? ?? '')
                              : (data['userEmail'] as String? ?? '');
                          final name = data['userName'] as String? ?? '';
                          final password = data['password'] as String? ?? '';
                          final createdAt = data['createdAt'] as Timestamp?;
                          final isAdmin = email.toLowerCase() == 'adminchi@gmail.com';

                          // Bỏ qua các document không có email hoặc userId hợp lệ
                          if (email.isEmpty || userId.isEmpty) {
                            return null;
                          }

                          final isSelected = _selectedUserIds.contains(userId);

                          return DataRow(
                            selected: isSelected,
                            cells: [
                              DataCell(
                                Checkbox(
                                  value: isSelected,
                                  onChanged: isAdmin
                                      ? null
                                      : (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedUserIds.add(userId);
                                            } else {
                                              _selectedUserIds.remove(userId);
                                            }
                                          });
                                        },
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : email.isNotEmpty
                                                ? email[0].toUpperCase()
                                                : '?',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SelectableText(
                                                  email,
                                                  style: const TextStyle(fontFamily: 'monospace'),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.copy, size: 18),
                                                onPressed: () {
                                                  Clipboard.setData(ClipboardData(text: email));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Đã sao chép email')),
                                                  );
                                                },
                                                tooltip: 'Sao chép email',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                          if (isAdmin)
                                            Chip(
                                              label: const Text('Admin', style: TextStyle(fontSize: 10)),
                                              backgroundColor: Colors.orange[100],
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  data['classCode'] as String? ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ),
                              DataCell(Text(name.isNotEmpty ? name : '-')),
                              DataCell(
                                Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        password,
                                        style: const TextStyle(fontFamily: 'monospace'),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 18),
                                      onPressed: () {
                                        // Copy password to clipboard
                                        Clipboard.setData(ClipboardData(text: password));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Đã sao chép mật khẩu')),
                                        );
                                      },
                                      tooltip: 'Sao chép mật khẩu',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  createdAt != null
                                      ? _formatDate(createdAt.toDate())
                                      : '-',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (data['isLogin'] ?? true) ? Colors.green[50] : Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: (data['isLogin'] ?? true) ? Colors.green[300]! : Colors.red[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    (data['isLogin'] ?? true) ? 'Hoạt động' : 'Đã khóa',
                                    style: TextStyle(
                                      color: (data['isLogin'] ?? true) ? Colors.green[700] : Colors.red[700],
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                isAdmin
                                    ? const Text('-', style: TextStyle(color: Colors.grey))
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              (data['isLogin'] ?? true) ? Icons.block : Icons.check_circle_outline,
                                              color: (data['isLogin'] ?? true) ? Colors.orange : Colors.green,
                                            ),
                                            onPressed: () => _toggleUserStatus(userId, data['isLogin'] ?? true),
                                            tooltip: (data['isLogin'] ?? true) ? 'Vô hiệu hóa' : 'Kích hoạt',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteUser(userId, email),
                                            tooltip: 'Xóa tài khoản',
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          );
                        }).where((row) => row != null).cast<DataRow>().toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip(
    BuildContext context, {
    required DateTime? date,
    required String label,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                date != null ? _formatDateOnly(date) : label,
                style: TextStyle(
                  fontSize: 12,
                  color: date != null ? Colors.black : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (date != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateOnly(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
