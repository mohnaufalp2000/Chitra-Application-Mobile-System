import 'color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Font Weigth

const FontWeight w300 = FontWeight.w300;
const FontWeight w400 = FontWeight.w400;
const FontWeight w500 = FontWeight.w500;
const FontWeight w600 = FontWeight.w600;
const FontWeight w700 = FontWeight.w700;
const FontWeight w800 = FontWeight.w800;

// Text Styles

TextStyle _getTextStyle(
  double fontSize,
  FontWeight fontWeight,
  Color color,
) {
  return GoogleFonts.urbanist(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

TextStyle getWhiteTextStyle(
    {double fontSize = 14, FontWeight fontWeight = w400}) {
  return _getTextStyle(fontSize, fontWeight, white);
}

TextStyle getBlackTextStyle(
    {double fontSize = 14, FontWeight fontWeight = w400}) {
  return _getTextStyle(fontSize, fontWeight, black);
}

TextStyle getGreyTextStyle(
  Color color, {
  double fontSize = 14,
  FontWeight fontWeight = w400,
}) {
  return _getTextStyle(fontSize, fontWeight, color);
}

TextStyle getRedTextStyle(
    {double fontSize = 14, FontWeight fontWeight = w400}) {
  return _getTextStyle(fontSize, fontWeight, Colors.red);
}

TextStyle getGreenTextStyle(
    {double fontSize = 14, FontWeight fontWeight = w400}) {
  return _getTextStyle(fontSize, fontWeight, green35C2C1);
}
