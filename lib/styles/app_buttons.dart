import 'package:flutter/material.dart';

/// Centralized button styles to reuse across dialogs.
///
/// - cancle: outline button style for cancel actions
/// - standas: primary filled button style for main actions
class AppButtons {
  const AppButtons._();

  /// Outline cancel button (cancle) — subtle but clear.
  static ButtonStyle cancle(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      side: BorderSide(
        color: theme.colorScheme.primary.withValues(alpha: 0.6),
        width: 1.4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Solid primary button (standas) — main action.
  static ButtonStyle standas(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      elevation: 0,
    );
  }
}

