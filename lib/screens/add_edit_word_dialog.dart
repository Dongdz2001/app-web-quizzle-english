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

  /// Mobile: ẩn các field tùy chọn trong phần thu gọn để dialog gọn, không mất chữ
  bool _showExtraFields = false;

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
    // Khi sửa và đã có dữ liệu tùy chọn → mở sẵn phần thêm thông tin
    final hasExtra = widget.word.wordForm.isNotEmpty ||
        (widget.word.englishDefinition ?? '').isNotEmpty ||
        (widget.word.synonym ?? '').isNotEmpty ||
        (widget.word.antonym ?? '').isNotEmpty;
    _showExtraFields = hasExtra;
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isMobile = screenWidth < 600;
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final spacing = isMobile ? 8.0 : 12.0;

    if (isMobile) {
      // Mobile xoay ngang: thêm height (95%, minHeight 360) để dialog đủ cao
      final maxH = isLandscape ? screenHeight * 0.95 : screenHeight * 0.85;
      final minH = isLandscape ? 360.0 : 0.0;
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isLandscape ? 12 : 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxH,
            minHeight: minH,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  widget.word.word.isEmpty ? 'Thêm Từ Vựng' : 'Sửa Từ Vựng',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildFormFields(context, spacing, true, _showExtraFields),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).dialogBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy', style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _onSave,
                      child: const Text('Lưu', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Text(
        widget.word.word.isEmpty ? 'Thêm Từ Vựng' : 'Sửa Từ Vựng',
        style: const TextStyle(fontSize: 20),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildFormFields(context, spacing, false),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(fontSize: 15)),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text('Lưu', style: TextStyle(fontSize: 15)),
        ),
      ],
    );
  }

  List<Widget> _buildFormFields(
    BuildContext context,
    double spacing,
    bool isMobile, [
    bool showExtra = true,
  ]) {
    final fields = <Widget>[
      TextField(
        controller: _wordController,
        decoration: InputDecoration(
          labelText: 'Word (Từ tiếng Anh) *',
          hintText: isMobile ? 'VD: family' : 'VD: family, career...',
          isDense: isMobile,
        ),
      ),
      SizedBox(height: spacing),
      TextField(
        controller: _meaningController,
        decoration: InputDecoration(
          labelText: 'Meaning (Nghĩa tiếng Việt) *',
          hintText: isMobile ? 'VD: gia đình' : 'VD: gia đình, sự nghiệp...',
          isDense: isMobile,
        ),
      ),
    ];

    // Mobile gọn: ẩn các field tùy chọn, chỉ hiện Word + Meaning
    if (!showExtra && isMobile) {
      fields.add(SizedBox(height: spacing));
      fields.add(
        TextButton.icon(
          onPressed: () => setState(() => _showExtraFields = true),
          icon: Icon(Icons.add_circle_outline, size: 18, color: Theme.of(context).colorScheme.primary),
          label: Text('Thêm thông tin (tùy chọn)', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary)),
        ),
      );
      return fields;
    }

    fields.addAll([
      SizedBox(height: spacing),
      DropdownButtonFormField<String>(
        initialValue: _wordFormOptions.contains(_wordFormController.text) &&
                _wordFormController.text.isNotEmpty
            ? _wordFormController.text
            : null,
        decoration: InputDecoration(labelText: 'Word form', isDense: isMobile),
        items: _wordFormOptions
            .where((e) => e.isNotEmpty)
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => _wordFormController.text = v ?? ''),
      ),
      SizedBox(height: spacing),
      TextField(
        controller: _englishDefController,
        decoration: InputDecoration(
          labelText: 'English definition (Tùy chọn)',
          hintText: isMobile ? '' : 'Giải nghĩa bằng tiếng Anh...',
          isDense: isMobile,
        ),
        maxLines: isMobile ? 1 : 2,
      ),
      SizedBox(height: spacing),
      TextField(
        controller: _synonymController,
        decoration: InputDecoration(
          labelText: isMobile ? 'Synonym' : 'Synonym - Từ đồng nghĩa (Tùy chọn)',
          hintText: isMobile ? '' : 'VD: household, profession...',
          isDense: isMobile,
        ),
      ),
      SizedBox(height: spacing),
      TextField(
        controller: _antonymController,
        decoration: InputDecoration(
          labelText: isMobile ? 'Antonym' : 'Antonym - Từ trái nghĩa (Tùy chọn)',
          hintText: isMobile ? '' : 'VD: children, boss...',
          isDense: isMobile,
        ),
      ),
    ]);
    return fields;
  }

  void _onSave() {
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
  }
}
