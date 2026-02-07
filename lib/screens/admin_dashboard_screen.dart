import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Controllers cho tạo tài khoản đơn lẻ
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  // Controllers cho tạo hàng loạt
  final _bulkQuantityController = TextEditingController(text: '10');
  final _bulkPrefixController = TextEditingController(text: 'user');
  final _bulkSuffixController = TextEditingController(text: 'quizzle.com');
  
  // Filter và selection
  final _filterController = TextEditingController();
  final _prefixFilterController = TextEditingController();
  Set<String> _selectedUserIds = {};
  DateTime? _startDate;
  DateTime? _endDate;
  
  bool _isLoading = false;
  bool _isBulkLoading = false;
  bool _isCheckingUser = true; // Đang kiểm tra user
  String? _errorMessage;
  String? _successMessage;
  String? _bulkErrorMessage;
  String? _bulkSuccessMessage;

  @override
  void initState() {
    super.initState();
    _checkUserExists();
  }

  /// Xóa user khỏi Firebase Auth thông qua Cloud Function
  /// Sử dụng Firebase Cloud Functions callable function
  Future<void> _deleteUserFromAuth(String userId) async {
    try {
      // Gọi Cloud Function 'deleteUser'
      final callable = FirebaseFunctions.instance.httpsCallable('deleteUser');
      
      // Gọi function với userId
      final result = await callable.call({'userId': userId});
      
      // Kiểm tra kết quả
      final data = result.data as Map<String, dynamic>;
      if (data['success'] == true) {
        print('Successfully deleted user $userId from Firebase Auth');
      } else {
        print('Warning: User deletion may have failed: ${data['message']}');
      }
    } catch (e) {
      // Xử lý lỗi từ Cloud Function
      // Kiểm tra error code từ exception
      final errorString = e.toString().toLowerCase();
      
      // Nếu là lỗi permission-denied hoặc unauthenticated, log và tiếp tục
      // Vì user đã được xóa khỏi Firestore rồi
      if (errorString.contains('permission-denied') || 
          errorString.contains('unauthenticated')) {
        print('Warning: Cannot delete user from Auth due to permission issue: $e');
      } else {
        // Các lỗi khác
        print('Error calling deleteUser Cloud Function: $e');
      }
      // Không rethrow để không làm gián đoạn việc xóa trong Firestore
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
    _bulkQuantityController.dispose();
    _bulkPrefixController.dispose();
    _bulkSuffixController.dispose();
    _filterController.dispose();
    _prefixFilterController.dispose();
    super.dispose();
  }

  /// Tạo mật khẩu random 12 ký tự (chữ và số)
  Future<void> _createUser() async {
    if (_emailController.text.trim().isEmpty) {
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

    final email = _emailController.text.trim();
    
    try {
      // Tự động tạo mật khẩu ngẫu nhiên
      final password = _generateRandomPasswordString();

      // Tạo user trong Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lưu thông tin user vào Firestore (chưa có thông tin cá nhân, người dùng sẽ nhập sau)
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'userId': userCredential.user?.uid,
        'userName': null, // Người dùng sẽ nhập sau khi đăng nhập
        'userEmail': email,
        'password': password, // Lưu mật khẩu để hiển thị cho admin
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': {
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'userEmail': FirebaseAuth.instance.currentUser?.email,
        },
      });

      setState(() {
        _successMessage = 'Tạo tài khoản thành công cho $email. Mật khẩu đã được tự động tạo.';
        _emailController.clear();
        _isLoading = false;
      });

      // Ẩn thông báo sau 3 giây
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
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

    setState(() {
      _isBulkLoading = true;
      _bulkErrorMessage = null;
      _bulkSuccessMessage = null;
    });

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

          // Tạo user trong Firebase Auth
          final userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Lưu thông tin user vào Firestore
          await _firestore.collection('users').doc(userCredential.user?.uid).set({
            'userId': userCredential.user?.uid,
            'userName': email.split('@')[0],
            'userEmail': email,
            'password': password, // Lưu mật khẩu để hiển thị cho admin
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': {
              'userId': FirebaseAuth.instance.currentUser?.uid,
              'userEmail': FirebaseAuth.instance.currentUser?.email,
            },
          });

          successCount++;
        } on FirebaseAuthException catch (e) {
          final email = '$prefix$i@$suffix';
          if (e.code == 'email-already-in-use') {
            // Email đã tồn tại - bỏ qua và tiếp tục
            skipCount++;
            skippedEmails.add(email);
          } else {
            // Lỗi khác
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
    _errorMessage = null;
    _successMessage = null;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm tài khoản mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  hintText: 'Nhập email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!value.contains('@')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
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
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Không cần setState ở đây để tránh rebuild danh sách
            },
            child: const Text('Hủy'),
          ),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                    // Đóng dialog ngay lập tức
                    Navigator.of(dialogContext).pop();
                    
                    // Hiển thị loading
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
                    
                    // Tạo user
                    await _createUser();
                    
                    // Ẩn loading và hiển thị kết quả
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
                        setState(() {
                          _successMessage = null;
                        });
                      } else if (_errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_errorMessage!),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    }
                  },
            child: const Text('Tạo tài khoản'),
          ),
        ],
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
                        }
                        
                        // Reset messages
                        setState(() {
                          _bulkErrorMessage = null;
                          _bulkSuccessMessage = null;
                        });
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
      // Nếu không có Cloud Function, user vẫn còn trong Auth và cần xóa thủ công
      try {
        await _deleteUserFromAuth(userId);
      } catch (authError) {
        print('Warning: Could not delete user from Auth: $authError');
        // Vẫn tiếp tục vì đã xóa khỏi Firestore thành công
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa tài khoản $email khỏi Firestore'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
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

  Future<void> _deleteMultipleUsers(BuildContext context) async {
    if (_selectedUserIds.isEmpty) return;

    // Xác nhận trước khi xóa
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa ${_selectedUserIds.length} tài khoản đã chọn?'),
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

    // Hiển thị loading
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
              Text('Đang xóa tài khoản...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    int successCount = 0;
    int failCount = 0;
    final List<String> failedUserIds = [];

    // Lấy danh sách userIds để xóa (copy để tránh modify trong khi iterate)
    final userIdsToDelete = List<String>.from(_selectedUserIds);

    try {
      for (var userId in userIdsToDelete) {
        try {
          // Lấy thông tin user để kiểm tra admin
          final doc = await _firestore.collection('users').doc(userId).get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final email = data['userEmail'] as String? ?? '';
            
            // Không cho xóa admin
            if (email == 'adminchi@gmail.com') {
              failCount++;
              continue;
            }

            // Xóa user trong Firestore
            await _firestore.collection('users').doc(userId).delete();
            
            // Thử xóa user khỏi Firebase Auth
            try {
              await _deleteUserFromAuth(userId);
            } catch (authError) {
              print('Warning: Could not delete user $userId from Auth: $authError');
              // Vẫn tiếp tục vì đã xóa khỏi Firestore thành công
            }
            
            _selectedUserIds.remove(userId);
            successCount++;
          }
        } catch (e) {
          failCount++;
          failedUserIds.add(userId);
        }
      }
    } finally {
      // Ẩn loading và hiển thị kết quả
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        String message = '';
        if (successCount > 0) {
          message = 'Đã xóa thành công $successCount tài khoản';
          if (failCount > 0) {
            message += '. $failCount tài khoản thất bại';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể xóa tài khoản. ${failCount > 0 ? "$failCount thất bại" : ""}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Update UI
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị loading trong khi đang kiểm tra user
    if (_isCheckingUser) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Quản Trị'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
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
                        ElevatedButton.icon(
                          onPressed: () => _showCreateUserDialog(context),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Thêm tài khoản mới'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    Row(
                      children: [
                        SizedBox(
                          width: 250,
                          child: TextField(
                            controller: _filterController,
                            decoration: InputDecoration(
                              labelText: 'Tìm kiếm',
                              hintText: 'Email, Tên...',
                              prefixIcon: const Icon(Icons.search, size: 18),
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
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: _prefixFilterController,
                            decoration: InputDecoration(
                              labelText: 'Tiền tố email',
                              hintText: 'VD: user...',
                              prefixIcon: const Icon(Icons.filter_alt, size: 18),
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
                        const SizedBox(width: 12),
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
                        const SizedBox(width: 8),
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
                        const SizedBox(width: 16),
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
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _selectedUserIds.isEmpty
                              ? null
                              : () => _deleteMultipleUsers(context),
                          icon: const Icon(Icons.delete_sweep),
                          label: const Text('Xóa nhiều'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            backgroundColor: Colors.red,
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
                              const DataColumn(label: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.bold))),
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
                                    isAdmin
                                        ? const Text('-', style: TextStyle(color: Colors.grey))
                                        : IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteUser(userId, email),
                                            tooltip: 'Xóa tài khoản',
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
