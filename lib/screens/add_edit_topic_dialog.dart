import 'package:antd_flutter_mobile/index.dart';
import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/topic.dart';
import '../styles/app_buttons.dart';
import '../services/firebase_service.dart';
import 'package:provider/provider.dart';
import '../providers/vocab_provider.dart';

class AddEditTopicDialog extends StatefulWidget {
  final Topic topic;

  const AddEditTopicDialog({super.key, required this.topic});

  @override
  State<AddEditTopicDialog> createState() => _AddEditTopicDialogState();
}

class _AddEditTopicDialogState extends State<AddEditTopicDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedCategoryId;
  int? _selectedGradeLevel;
  String? _selectedClassCode;
  List<String> _classes = [];
  final _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.topic.name);
    _descController = TextEditingController(
      text: widget.topic.description ?? '',
    );
    _selectedCategoryId = widget.topic.categoryId;
    _selectedGradeLevel = widget.topic.gradeLevel;
    _selectedClassCode = widget.topic.classCode;
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    _firebaseService.getAvailableClassesStream().first.then((classes) {
      if (mounted) {
        setState(() {
          _classes = classes;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final spacing = isMobile ? 10.0 : 16.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 32 : 40,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenSize.width - 32 : 480,
          maxHeight: screenSize.height * (isMobile ? 0.9 : 0.8),
        ),
        child: AntdCard(
          title: Text(widget.topic.name.isEmpty ? 'Thêm Topic' : 'Sửa Topic'),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: AppButtons.cancle(context),
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: AppButtons.standas(context),
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập tên topic')),
                    );
                    return;
                  }
                  Navigator.pop(
                    context,
                    widget.topic.copyWith(
                      name: name,
                      description: _descController.text.trim().isEmpty
                          ? null
                          : _descController.text.trim(),
                      categoryId: _selectedCategoryId,
                      gradeLevel: _selectedCategoryId == CategoryIds.grade
                          ? _selectedGradeLevel
                          : null,
                      classCode: _selectedClassCode,
                    ),
                  );
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    enableSuggestions: false,
                    autocorrect: false,
                    spellCheckConfiguration:
                        const SpellCheckConfiguration.disabled(),
                    decoration: InputDecoration(
                      labelText: 'Tên Topic',
                      hintText: isMobile
                          ? 'VD: Gia đình'
                          : 'VD: Gia đình, Công việc...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing),
                  TextField(
                    controller: _descController,
                    enableSuggestions: false,
                    autocorrect: false,
                    spellCheckConfiguration:
                        const SpellCheckConfiguration.disabled(),
                    maxLines: isMobile ? 2 : 3,
                    decoration: InputDecoration(
                      labelText: 'Mô tả (tuỳ chọn)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Nhóm',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: kCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 20),
                            const SizedBox(width: 8),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategoryId = value;
                          if (value != CategoryIds.grade) {
                            _selectedGradeLevel = null;
                          } else
                            _selectedGradeLevel ??= 1;
                        });
                      }
                    },
                  ),
                  SizedBox(height: spacing),
                  Consumer<VocabProvider>(
                    builder: (context, provider, _) {
                      if (provider.isAdmin) {
                        return DropdownButtonFormField<String?>(
                          initialValue: _selectedClassCode,
                          decoration: InputDecoration(
                            labelText: 'Giao cho lớp (Tất cả nếu trống)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tất cả các lớp'),
                            ),
                            ..._classes.map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text('Lớp $c'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedClassCode = value);
                          },
                        );
                      } else {
                        // Nếu là user thường, khóa mã lớp theo profile của họ
                        _selectedClassCode = provider.userClassCode;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.class_outlined,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Lớp học: ${provider.userClassCode ?? "Chung"}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  if (_selectedCategoryId == CategoryIds.grade) ...[
                    SizedBox(height: spacing),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedGradeLevel,
                      decoration: InputDecoration(
                        labelText: 'Cấp độ lớp (1-12)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: List.generate(12, (index) {
                        final grade = index + 1;
                        return DropdownMenuItem<int>(
                          value: grade,
                          child: Text('Lớp $grade'),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGradeLevel = value);
                        }
                      },
                    ),
                  ],
                  if (isMobile) const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
