import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

back(BuildContext _context) {
  Navigator.pop(_context);
}

exit() {
  SystemNavigator.pop();
}

push(BuildContext _context, String widget) {
  Navigator.pushNamed(_context, widget);
}

pushReplace(BuildContext _context, String widget) {
  Navigator.pushReplacementNamed(_context, widget);
}

pushRemoveUntil(BuildContext _context, String widget) {
  Navigator.pushNamedAndRemoveUntil(_context, widget, (route) => false);
}
