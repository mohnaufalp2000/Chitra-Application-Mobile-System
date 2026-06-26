import 'package:camos/core/styles/text_manager.dart';
import 'package:flutter/material.dart';

class AdjustmentDetailPopupWidget extends StatelessWidget {
  final String unit;
  final int position;
  final int beforePsi;
  final double beforeBar;
  final int afterPsi;
  final double afterBar;
  final int changePsi;
  final String startTime; // e.g. "18 Jun 2026, 03:25:41"
  final String endTime; // e.g. "18 Jun 2026, 04:42:14"
  final int durationMinute;

  const AdjustmentDetailPopupWidget({
    super.key,
    required this.unit,
    required this.position,
    required this.beforePsi,
    required this.beforeBar,
    required this.afterPsi,
    required this.afterBar,
    required this.changePsi,
    required this.startTime,
    required this.endTime,
    required this.durationMinute,
  });

  static const Color _teal = Color(0xFF2A9D8F);
  static const Color _red = Color(0xFFE63946);
  static const Color _green = Color(0xFF2A9D5C);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────
            _buildHeader(context),

            // ── Body ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  _buildTimelineRow(
                    iconColor: _red,
                    iconData: Icons.arrow_downward_rounded,
                    label: "BEFORE",
                    labelColor: _red,
                    subtitle: startTime,
                    psi: "$beforePsi PSI",
                    psiColor: _red,
                    bar: "(${beforeBar.toStringAsFixed(1)} BAR)",
                  ),
                  _buildDivider(),
                  _buildTimelineRow(
                    iconColor: _teal,
                    iconData: Icons.arrow_upward_rounded,
                    label: "AFTER",
                    labelColor: _teal,
                    subtitle: endTime,
                    psi: "$afterPsi PSI",
                    psiColor: _teal,
                    bar: "(${afterBar.toStringAsFixed(1)} BAR)",
                  ),
                  _buildDivider(),
                  _buildChangeRow(),
                  _buildDivider(),
                  _buildTimeRow(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── Last Adjusted Footer ─────────────────────────────────
            _buildLastAdjustedFooter(),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo/icon circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child:
                    const Icon(Icons.settings, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Adjustment Detail",
                  style: getWhiteTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Last Adjusted subtitle pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fire_truck, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  "$unit - Pos $position",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TIMELINE ROW (Before / After) ───────────────────────────────────
  Widget _buildTimelineRow({
    required Color iconColor,
    required IconData iconData,
    required String label,
    required Color labelColor,
    required String subtitle,
    required String psi,
    required Color psiColor,
    required String bar,
  }) {
    // Parse string ke DateTime lalu format ulang
    // Asumsi format input: "2025-06-18 03:25:41" atau sesuaikan parsenya
    String dateLine = '';
    String timeLine = '';

    try {
      final dt = DateTime.parse(subtitle); // e.g. "2025-06-18 03:25:41"
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

      dateLine =
          "${dayNames[dt.weekday - 1]}, ${dt.day} ${monthNames[dt.month - 1]} ${dt.year},";
      timeLine =
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      // Fallback jika parse gagal, tampilkan string asli
      dateLine = subtitle;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: iconColor, width: 2),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLine,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (timeLine.isNotEmpty)
                  Text(
                    timeLine,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: psi,
                  style: TextStyle(
                    color: psiColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: "  $bar",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CHANGE ROW ──────────────────────────────────────────────────────
  Widget _buildChangeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _green, width: 2),
            ),
            child: const Icon(Icons.trending_up, color: _green, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              "CHANGE",
              style: TextStyle(
                color: _green,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Text(
            "+$changePsi PSI",
            style: const TextStyle(
              color: _green,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_upward, color: _green, size: 22),
        ],
      ),
    );
  }

  // ── TIME ROW ────────────────────────────────────────────────────────
  Widget _buildTimeRow() {
    String _formatDate(String raw) {
      try {
        final dt = DateTime.parse(raw);
        final dayNames = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        final monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        return "${dayNames[dt.weekday - 1]}, ${dt.day} ${monthNames[dt.month - 1]} ${dt.year},";
      } catch (_) {
        return raw;
      }
    }

    String _formatTime(String raw) {
      try {
        final dt = DateTime.parse(raw);
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (_) {
        return '';
      }
    }

    final startDateLine = _formatDate(startTime);
    final startTimeLine = _formatTime(startTime);
    final endDateLine = _formatDate(endTime);
    final endTimeLine = _formatTime(endTime);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black54, width: 2),
            ),
            child:
                const Icon(Icons.access_time, color: Colors.black54, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TIME",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                // Start time
                Text(startDateLine,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(startTimeLine,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Icon(Icons.arrow_downward,
                      size: 14, color: Colors.black45),
                ),
                // End time
                Text(endDateLine,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(endTimeLine,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ],
            ),
          ),
          // Duration
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.timer_outlined, color: _teal, size: 22),
                const SizedBox(height: 4),
                const Text(
                  "Duration Low Pressure",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  "$durationMinute minutes",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── LAST ADJUSTED FOOTER ────────────────────────────────────────────
  Widget _buildLastAdjustedFooter() {
    String lastAdjusted = '';
    String lastAdjustedAgo = '';

    try {
      final dt = DateTime.parse(endTime);
      final monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

      lastAdjusted = "${dt.day} ${monthNames[dt.month - 1]} ${dt.year}, "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        lastAdjustedAgo = "${diff.inMinutes} minutes ago";
      } else if (diff.inHours < 24) {
        lastAdjustedAgo = "${diff.inHours} hours ago";
      } else {
        lastAdjustedAgo = "${diff.inDays} days ago";
      }
    } catch (_) {
      lastAdjusted = endTime;
      lastAdjustedAgo = '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF0FAF8),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_outlined,
                color: _teal, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "LAST ADJUSTED",
                  style: TextStyle(
                    fontSize: 11,
                    color: _teal,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastAdjusted,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // "X minutes ago" chip
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.black26),
          //     borderRadius: BorderRadius.circular(20),
          //   ),
          //   child: Text(
          //     lastAdjustedAgo,
          //     style: const TextStyle(
          //       fontSize: 13,
          //       color: Colors.black87,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFEEEEEE));
  }
}
