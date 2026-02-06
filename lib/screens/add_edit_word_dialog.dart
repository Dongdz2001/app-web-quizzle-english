import 'package:antd_flutter_mobile/index.dart';
import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../styles/app_buttons.dart';

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
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isMobile = screenWidth < 600;
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final spacing = isMobile ? 8.0 : 12.0;

    // Kích thước card theo kiểu web React/Ant Design
    final maxCardWidth = isMobile ? screenWidth - 32 : 520.0;
    final maxCardHeight = isMobile
        ? (isLandscape ? screenHeight * 0.95 : screenHeight * 0.85)
        : screenHeight * 0.8;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? (isLandscape ? 12 : 24) : 32,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxCardWidth,
          maxHeight: maxCardHeight,
          minHeight: isMobile && isLandscape ? 360 : 0,
        ),
        child: AntdCard(
          title: Text(
            widget.word.word.isEmpty ? 'Thêm Từ Vựng' : 'Sửa Từ Vựng',
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
                onPressed: _onSave,
                child: const Text('Lưu'),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: isMobile ? 4 : 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildFormFields(
                  context,
                  spacing,
                  isMobile,
                  _showExtraFields,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields(
    BuildContext context,
    double spacing,
    bool isMobile, [
    bool showExtra = true,
  ]) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    InputDecoration _fieldDecoration({
      required String label,
      String? hint,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: isMobile,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
          borderSide: BorderSide(
            color: primary,
            width: 1.6,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isMobile ? 10 : 12,
        ),
      );
    }

    final fields = <Widget>[
      TextField(
        controller: _wordController,
        decoration: _fieldDecoration(
          label: 'Word (Từ tiếng Anh) *',
          hint: isMobile ? 'VD: mother' : 'VD: mother, career...',
        ),
      ),
      SizedBox(height: spacing),
      TextField(
        controller: _meaningController,
        decoration: _fieldDecoration(
          label: 'Meaning (Nghĩa tiếng Việt) *',
          hint: isMobile ? 'VD: mẹ' : 'VD: mẹ, gia đình, sự nghiệp...',
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
        decoration: _fieldDecoration(label: 'Word form'),
        items: _wordFormOptions
            .where((e) => e.isNotEmpty)
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => _wordFormController.text = v ?? ''),
      ),
      SizedBox(height: spacing),
      TextField(
        controller: _englishDefController,
        decoration: _fieldDecoration(
          label: 'Nhập phiên âm (Tùy chọn)',
          hint: isMobile ? '' : 'VD: /twɪn/, phiên âm IPA...',
        ),
        maxLines: isMobile ? 2 : 3,
      ),
      SizedBox(height: spacing),
      TextField(
        controller: _synonymController,
        decoration: _fieldDecoration(
          label: isMobile ? 'Synonym' : 'Synonym - Từ đồng nghĩa (Tùy chọn)',
          hint: isMobile ? '' : 'VD: mom, household, profession...',
        ),
      ),
      SizedBox(height: spacing),
      TextField(
        controller: _antonymController,
        decoration: _fieldDecoration(
          label: isMobile ? 'Antonym' : 'Antonym - Từ trái nghĩa (Tùy chọn)',
          hint: isMobile ? '' : 'VD: father, children, boss...',
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
