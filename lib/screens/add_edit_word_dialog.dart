import 'package:flutter/material.dart';

import '../models/vocabulary.dart';

class AddEditWordDialog extends StatefulWidget {
  final Vocabulary word;

  const AddEditWordDialog({super.key, required this.word});

  @override
  State<AddEditWordDialog> createState() => _AddEditWordDialogState();
}

class _AddEditWordDialogState extends State<AddEditWordDialog> {
  late TextEditingController _wordController;
  late TextEditingController _meaningController;
  late TextEditingController _wordFormController;
  late TextEditingController _englishDefController;
  late TextEditingController _synonymController;
  late TextEditingController _antonymController;

  // Các dạng từ hỗ trợ trong dropdown (không dùng giá trị rỗng trong items)
  final _wordFormOptions = ['noun', 'verb', 'adjective', 'adverb', 'phrase'];

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.word.word);
    _meaningController = TextEditingController(text: widget.word.meaning);
    _wordFormController = TextEditingController(text: widget.word.wordForm);
    _englishDefController = TextEditingController(text: widget.word.englishDefinition ?? '');
    _synonymController = TextEditingController(text: widget.word.synonym ?? '');
    _antonymController = TextEditingController(text: widget.word.antonym ?? '');
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _wordFormController.dispose();
    _englishDefController.dispose();
    _synonymController.dispose();
    _antonymController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.word.word.isEmpty ? 'Thêm Từ Vựng' : 'Sửa Từ Vựng'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 450 : double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _wordController,
                decoration: const InputDecoration(
                  labelText: 'Word (Từ tiếng Anh) *',
                  hintText: 'VD: family, career...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _meaningController,
                decoration: const InputDecoration(
                  labelText: 'Meaning (Nghĩa tiếng Việt) *',
                  hintText: 'VD: gia đình, sự nghiệp...',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _wordFormOptions.contains(_wordFormController.text) &&
                        _wordFormController.text.isNotEmpty
                    ? _wordFormController.text
                    : null,
                decoration: const InputDecoration(labelText: 'Word form'),
                items: _wordFormOptions
                    .where((e) => e.isNotEmpty)
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _wordFormController.text = v ?? '');
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _englishDefController,
                decoration: const InputDecoration(
                  labelText: 'English definition (Tùy chọn)',
                  hintText: 'Giải nghĩa bằng tiếng Anh...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _synonymController,
                decoration: const InputDecoration(
                  labelText: 'Synonym - Từ đồng nghĩa (Tùy chọn)',
                  hintText: 'VD: household, profession...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _antonymController,
                decoration: const InputDecoration(
                  labelText: 'Antonym - Từ trái nghĩa (Tùy chọn)',
                  hintText: 'VD: children, boss...',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            final word = _wordController.text.trim();
            final meaning = _meaningController.text.trim();
            if (word.isEmpty || meaning.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập Word và Meaning')),
              );
              return;
            }
            Navigator.pop(
              context,
              widget.word.copyWith(
                word: word,
                meaning: meaning,
                wordForm: _wordFormController.text.trim(),
                englishDefinition: _englishDefController.text.trim().isEmpty
                    ? null
                    : _englishDefController.text.trim(),
                synonym: _synonymController.text.trim().isEmpty
                    ? null
                    : _synonymController.text.trim(),
                antonym: _antonymController.text.trim().isEmpty
                    ? null
                    : _antonymController.text.trim(),
              ),
            );
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
