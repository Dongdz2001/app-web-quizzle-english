import 'package:antd_flutter_mobile/index.dart';
import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/topic.dart';
import '../styles/app_buttons.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.topic.name);
    _descController = TextEditingController(text: widget.topic.description ?? '');
    _selectedCategoryId = widget.topic.categoryId;
    _selectedGradeLevel = widget.topic.gradeLevel;
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
          title: Text(
            widget.topic.name.isEmpty ? 'Thêm Topic' : 'Sửa Topic',
          ),
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
                  AntdInput(
                    value: _nameController.text,
                    placeholder: Text(
                      isMobile ? 'VD: Gia đình' : 'VD: Gia đình, Công việc...',
                    ),
                    onChange: (val) =>
                        setState(() => _nameController.text = val ?? ''),
                  ),
                  SizedBox(height: spacing),
                  AntdTextArea(
                    value: _descController.text,
                    placeholder: const Text('Mô tả (tuỳ chọn)'),
                    maxLines: isMobile ? 2 : 3,
                    showCount: false,
                    onChange: (val) =>
                        setState(() => _descController.text = val ?? ''),
                  ),
                  SizedBox(height: spacing),
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
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
                          } else if (_selectedGradeLevel == null) {
                            _selectedGradeLevel = 1;
                          }
                        });
                      }
                    },
                  ),
                  if (_selectedCategoryId == CategoryIds.grade) ...[
                    SizedBox(height: spacing),
                    DropdownButtonFormField<int>(
                      value: _selectedGradeLevel,
                      decoration: InputDecoration(
                        labelText: 'Lớp',
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
