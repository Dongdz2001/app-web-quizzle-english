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
  late TextEditingController _englishDefController;
  late TextEditingController _synonymController;
  late TextEditingController _antonymController;
  late TextEditingController _nounController;
  late TextEditingController _verbController;
  late TextEditingController _adjController;
  late TextEditingController _advController;
  late TextEditingController _vEdController;
  late TextEditingController _vIngController;
  late TextEditingController _vSesController;

  /// Mobile: ẩn các field tùy chọn trong phần thu gọn để dialog gọn, không mất chữ
  bool _showExtraFields = false;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.word.word);
    _meaningController = TextEditingController(text: widget.word.meaning);
    _englishDefController = TextEditingController(
      text: widget.word.englishDefinition ?? '',
    );
    _synonymController = TextEditingController(text: widget.word.synonym ?? '');
    _antonymController = TextEditingController(text: widget.word.antonym ?? '');
    _nounController = TextEditingController(text: widget.word.noun ?? '');
    _verbController = TextEditingController(text: widget.word.verb ?? '');
    _adjController = TextEditingController(text: widget.word.adjective ?? '');
    _advController = TextEditingController(text: widget.word.adverb ?? '');
    _vEdController = TextEditingController(text: widget.word.vEd ?? '');
    _vIngController = TextEditingController(text: widget.word.vIng ?? '');
    _vSesController = TextEditingController(text: widget.word.vSes ?? '');

    // Khi sửa và đã có dữ liệu tùy chọn → mở sẵn phần thêm thông tin
    final hasExtra =
        (widget.word.englishDefinition ?? '').isNotEmpty ||
        (widget.word.synonym ?? '').isNotEmpty ||
        (widget.word.antonym ?? '').isNotEmpty ||
        (widget.word.noun ?? '').isNotEmpty ||
        (widget.word.verb ?? '').isNotEmpty ||
        (widget.word.adjective ?? '').isNotEmpty ||
        (widget.word.adverb ?? '').isNotEmpty ||
        (widget.word.vEd ?? '').isNotEmpty ||
        (widget.word.vIng ?? '').isNotEmpty ||
        (widget.word.vSes ?? '').isNotEmpty;
    _showExtraFields = hasExtra;
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _englishDefController.dispose();
    _synonymController.dispose();
    _antonymController.dispose();
    _nounController.dispose();
    _verbController.dispose();
    _adjController.dispose();
    _advController.dispose();
    _vEdController.dispose();
    _vIngController.dispose();
    _vSesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isMobile = screenWidth < 600;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final spacing = isMobile ? 8.0 : 12.0;

    // Trên điện thoại: card rộng bằng màn hình (padding tối thiểu). Web/tablet: giữ max width 520.
    final maxCardWidth = isMobile ? screenWidth : 520.0;
    final maxCardHeight = isMobile
        ? (isLandscape ? screenHeight * 0.95 : screenHeight * 0.85)
        : screenHeight * 0.8;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 0 : 40,
        vertical: isMobile ? (isLandscape ? 8 : 16) : 32,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth;
              // Luôn giới hạn chiều cao vùng cuộn (mobile + web): trừ chỗ title + footer để không bị overflow.
              final bodyMaxHeight = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : maxCardHeight - 140;
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: bodyMaxHeight),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isMobile ? 4 : 8,
                      bottom: isMobile ? 16 : 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildFormFields(
                        context,
                        spacing,
                        isMobile,
                        contentWidth,
                        _showExtraFields,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// [contentWidth] Trên mobile là chiều rộng khả dụng của card (từ LayoutBuilder).
  List<Widget> _buildFormFields(
    BuildContext context,
    double spacing,
    bool isMobile,
    double contentWidth, [
    bool showExtra = true,
  ]) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    InputDecoration fieldDecoration({required String label, String? hint}) {
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
          borderSide: BorderSide(color: primary, width: 1.6),
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
        enableSuggestions: false,
        autocorrect: false,
        spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
        decoration: fieldDecoration(
          label: 'Word (Từ tiếng Anh) *',
          hint: isMobile ? 'VD: mother' : 'VD: mother, career...',
        ),
      ),
      SizedBox(height: spacing),
      TextField(
        controller: _meaningController,
        enableSuggestions: false,
        autocorrect: false,
        spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
        decoration: fieldDecoration(
          label:
              'Meaning (Nghĩa tiếng Việt)', // Bỏ bắt buộc nhập meaning theo yêu cầu mới là chỉ bắt buộc Word
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
          icon: Icon(
            Icons.add_circle_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: Text(
            'Thêm thông tin (tùy chọn)',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
      return fields;
    }

    fields.addAll([
      SizedBox(height: spacing),
      TextField(
        controller: _englishDefController,
        enableSuggestions: false,
        autocorrect: false,
        spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
        decoration: fieldDecoration(
          label: 'Nhập phiên âm (Tùy chọn)',
          hint: isMobile ? '' : 'VD: /twɪn/, phiên âm IPA...',
        ),
      ),
      SizedBox(height: spacing),
      Text(
        'Các loại từ (Tùy chọn)',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          SizedBox(
            width: isMobile ? contentWidth : 230,
            child: TextField(
              controller: _nounController,
              enableSuggestions: false,
              autocorrect: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              decoration: fieldDecoration(label: 'Danh từ'),
            ),
          ),
          SizedBox(
            width: isMobile ? contentWidth : 230,
            child: TextField(
              controller: _verbController,
              enableSuggestions: false,
              autocorrect: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              decoration: fieldDecoration(label: 'Động từ'),
            ),
          ),
          SizedBox(
            width: isMobile ? contentWidth : 230,
            child: TextField(
              controller: _adjController,
              enableSuggestions: false,
              autocorrect: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              decoration: fieldDecoration(label: 'Tính từ'),
            ),
          ),
          SizedBox(
            width: isMobile ? contentWidth : 230,
            child: TextField(
              controller: _advController,
              enableSuggestions: false,
              autocorrect: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              decoration: fieldDecoration(label: 'Trạng từ'),
            ),
          ),
        ],
      ),
      SizedBox(height: spacing),
      Text(
        'Dạng của động từ (Tùy chọn)',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          SizedBox(
            width: isMobile ? contentWidth : 230,
            child: TextField(
              controller: _vEdController,
              enableSuggestions: false,
              autocorrect: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              decoration: fieldDecoration(label: 'V-ed'),
            ),
          ),
          SizedBox(
            width: isMobile ? contentWidth : 230,
            child: TextField(
              controller: _vIngController,
              enableSuggestions: false,
              autocorrect: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              decoration: fieldDecoration(label: 'V-ing'),
            ),
          ),
          SizedBox(
            width: isMobile ? contentWidth : 230,
            child: TextField(
              controller: _vSesController,
              enableSuggestions: false,
              autocorrect: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              decoration: fieldDecoration(label: 'V-s/es'),
            ),
          ),
        ],
      ),
      SizedBox(height: spacing),
      Text(
        'Nhóm từ (Tùy chọn)',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          SizedBox(
            width: isMobile ? contentWidth : 230,
            child: TextField(
              controller: _synonymController,
              enableSuggestions: false,
              autocorrect: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              decoration: fieldDecoration(
                label: isMobile ? 'Từ đồng nghĩa' : 'Synonym (Từ đồng nghĩa)',
                hint: isMobile ? '' : 'VD: mom, household...',
              ),
            ),
          ),
          SizedBox(
            width: isMobile ? contentWidth : 230,
            child: TextField(
              controller: _antonymController,
              enableSuggestions: false,
              autocorrect: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              decoration: fieldDecoration(
                label: isMobile ? 'Từ trái nghĩa' : 'Antonym (Từ trái nghĩa)',
                hint: isMobile ? '' : 'VD: father, children...',
              ),
            ),
          ),
        ],
      ),
    ]);
    return fields;
  }

  void _onSave() {
    final word = _wordController.text.trim();
    final meaning = _meaningController.text.trim();
    if (word.isEmpty) {
      // Chỉ bắt buộc nhập Word
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Word')));
      return;
    }
    Navigator.pop(
      context,
      widget.word.copyWith(
        word: word,
        meaning: meaning,
        wordForm: '',
        noun: _nounController.text.trim().isEmpty
            ? null
            : _nounController.text.trim(),
        verb: _verbController.text.trim().isEmpty
            ? null
            : _verbController.text.trim(),
        adjective: _adjController.text.trim().isEmpty
            ? null
            : _adjController.text.trim(),
        adverb: _advController.text.trim().isEmpty
            ? null
            : _advController.text.trim(),
        vEd: _vEdController.text.trim().isEmpty
            ? null
            : _vEdController.text.trim(),
        vIng: _vIngController.text.trim().isEmpty
            ? null
            : _vIngController.text.trim(),
        vSes: _vSesController.text.trim().isEmpty
            ? null
            : _vSesController.text.trim(),
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
