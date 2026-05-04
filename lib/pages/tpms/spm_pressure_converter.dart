Map<String, String> spmConvertPressure(
    double rawPressure, String unitPressure) {
  double psi;
  String bar;

  if (unitPressure.toUpperCase() == 'BAR') {
    bar = rawPressure.toStringAsFixed(1);
    psi = (rawPressure * 14.5038).roundToDouble();
  } else {
    psi = rawPressure.roundToDouble();
    bar = (rawPressure / 14.5038).toStringAsFixed(1);
  }

  return {
    'psi': psi.toStringAsFixed(0),
    'bar': bar,
  };
}
