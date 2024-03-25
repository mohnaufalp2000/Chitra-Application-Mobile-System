import 'package:camos/core/styles/text_manager.dart';
import 'package:flutter/material.dart';

class CustomErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRefresh;

  CustomErrorWidget({required this.errorMessage, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Icon(
                Icons.error,
                color: Colors.red,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: getBlackTextStyle(),
              )
              // Text(
              //   'Please check your internet connection and press the \'Refresh\' button below to reload the page.',
              //   textAlign: TextAlign.center,
              //   style: getBlackTextStyle(),
              // )
            ],
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRefresh,
            child: Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
