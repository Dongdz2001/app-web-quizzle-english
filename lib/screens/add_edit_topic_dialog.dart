import 'package:flutter/material.dart';

import '../models/topic.dart';

class AddEditTopicDialog extends StatefulWidget {
  final Topic topic;

  const AddEditTopicDialog({super.key, required this.topic});

  @override
  State<AddEditTopicDialog> createState() => _AddEditTopicDialogState();
}

class _AddEditTopicDialogState extends State<AddEditTopicDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.topic.name);
    _descController = TextEditingController(text: widget.topic.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final spacing = isMobile ? 10.0 : 16.0;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 40 : 24,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 16 : 20,
        isMobile ? 16 : 24,
        isMobile ? 4 : 24,
      ),
      title: Text(
        widget.topic.name.isEmpty ? 'Thêm Topic' : 'Sửa Topic',
        style: TextStyle(fontSize: isMobile ? 18 : 20),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: isMobile ? double.infinity : 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên topic *',
                  hintText: isMobile ? 'VD: Gia đình' : 'VD: Gia đình, Công việc...',
                  isDense: isMobile,
                ),
              ),
              SizedBox(height: spacing),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Mô tả (tùy chọn)',
                  isDense: isMobile,
                ),
                maxLines: isMobile ? 1 : 2,
              ),
              // Thêm padding dưới để nội dung không bị che bởi nút
              if (isMobile) const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        isMobile ? 12 : 8,
        isMobile ? 12 : 24,
        isMobile ? 12 : 16,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy', style: TextStyle(fontSize: isMobile ? 14 : 15)),
        ),
        ElevatedButton(
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
              ),
            );
          },
          child: Text('Lưu', style: TextStyle(fontSize: isMobile ? 14 : 15)),
        ),
      ],
    );
  }
}
