// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';

appBarWidget(String name, BuildContext context, {bool isBehind = false}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    title: Padding(
      padding: const EdgeInsets.only(top: 18.0),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: (isBehind)
            ? getWhiteTextStyle(fontSize: 20, fontWeight: w700)
            : getBlackTextStyle(fontSize: 20, fontWeight: w700),
      ),
    ),
    centerTitle: true,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: (isBehind) ? white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: black),
        ),
        child: IconButton(
            onPressed: () {
              back(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: black,
              size: 24,
            )),
      ),
    ),
  );
}
