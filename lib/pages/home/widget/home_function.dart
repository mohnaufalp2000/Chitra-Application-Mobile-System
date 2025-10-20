import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/styles/asset_path.dart';
import '../../../core/styles/text_manager.dart';
import '../../../core/utils/data/menu.dart';

class HomeFunction {
  static List<Color> getGradientColors(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return [const Color(0xFF03C078), const Color(0xFF6EE7B7)];
      case 'repair':
        return [const Color(0xFF4ADE80), const Color(0xFF22C55E)];
      case 'spare':
        return [const Color(0xFF38BDF8), const Color(0xFF3B82F6)];
      case 'scrap':
        return [const Color(0xFFFBBF24), const Color(0xFFF59E0B)];
      default:
        return [const Color(0xFFCBD5E1), const Color(0xFFE2E8F0)];
    }
  }

  static IconData getIconByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return LucideIcons.circle; // lingkaran baru
      case 'repair':
        return LucideIcons.wrench; // alat perbaikan
      case 'spare':
        return LucideIcons.repeat; // rotasi / cadangan
      case 'scrap':
        return LucideIcons.trash2; // buangan
      default:
        return LucideIcons.helpCircle; // default icon
    }
  }

  static Widget buildMenuItem(Menu item) {
    return Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        color: Colors.transparent,
        child: InkWell(
          splashColor: item.color.withOpacity(0.4),
          highlightColor: item.color.withOpacity(0.2),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Image.asset(
                          '${iconPath}/${item.image}',
                          height: 50,
                          width: 50,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.name,
                  style: getBlackTextStyle(fontWeight: w500, fontSize: 12),
                )
              ],
            ),
          ),
        ));
  }

  static Widget buildInlineError({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔴 Ikon Error
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.error_outline, color: Colors.red, size: 32),
            ),
            const SizedBox(height: 12),

            // 📝 Pesan Error
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // 🔁 Tombol Retry
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  'Try Again',
                  style: getWhiteTextStyle(fontWeight: w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
