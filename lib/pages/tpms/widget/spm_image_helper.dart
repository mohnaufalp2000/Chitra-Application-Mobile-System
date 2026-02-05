class SpmImageHelper {
  static const String _basePath = 'assets/images';

  static String getImageByModel(String? model) {
    if (model == null || model.trim().isEmpty) {
      return '$_basePath/oht.png'; // fallback
    }

    switch (model.toUpperCase()) {
      case 'LOADER':
        return '$_basePath/loader.png';

      case 'OHT':
        return '$_basePath/oht.png';

      case 'GRADER':
        return '$_basePath/grader.png';

      case 'TRUCK':
        return '$_basePath/truck.png';

      default:
        return '$_basePath/oht.png';
    }
  }
}
