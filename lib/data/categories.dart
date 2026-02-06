import 'package:flutter/material.dart';

/// ID của các nhóm topic — dùng cho Topic.categoryId và route.
class CategoryIds {
  static const String topic = 'cat_topic';
  static const String grade = 'cat_grade';
  static const String grammar = 'cat_grammar';
  static const String idiom = 'cat_idiom';
  static const String ipa = 'cat_ipa';
}

/// Một nhóm topic (Từ vựng theo chủ đề, theo lớp, Ngữ pháp, ...).
class AppCategory {
  final String id;
  final String name;
  final IconData icon;

  const AppCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

/// Danh sách 5 nhóm ban đầu — web và mobile dùng chung.
const List<AppCategory> kCategories = [
  AppCategory(
    id: CategoryIds.topic,
    name: 'Từ vựng theo chủ đề',
    icon: Icons.menu_book,
  ),
  AppCategory(
    id: CategoryIds.grade,
    name: 'Từ vựng theo lớp',
    icon: Icons.school,
  ),
  AppCategory(
    id: CategoryIds.grammar,
    name: 'Ngữ pháp',
    icon: Icons.article,
  ),
  AppCategory(
    id: CategoryIds.idiom,
    name: 'Idiom & Collocations',
    icon: Icons.lightbulb_outline,
  ),
  AppCategory(
    id: CategoryIds.ipa,
    name: 'Phát âm IPA',
    icon: Icons.record_voice_over,
  ),
];
