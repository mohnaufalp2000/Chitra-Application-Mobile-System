import 'package:camos/core/styles/text_manager.dart';
import 'package:flutter/material.dart';

class NotUpdateWarningWidget extends StatelessWidget {
  final int totalActual;

  const NotUpdateWarningWidget({super.key, required this.totalActual});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.shade300,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data unit belum sinkron dengan server.',
                style: getBlackTextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Total unit aktual: ',
                      style: getBlackTextStyle(fontSize: 13),
                    ),
                    TextSpan(
                      text: '$totalActual',
                      style: getBlackTextStyle(fontSize: 13).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    TextSpan(
                      text: '. Silakan tekan ',
                      style: getBlackTextStyle(fontSize: 13),
                    ),
                    TextSpan(
                      text: '"Update Unit"',
                      style: getBlackTextStyle(fontSize: 13).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
