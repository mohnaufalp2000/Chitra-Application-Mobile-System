/// Hanya salin metadata foto untuk satu dokumen, tanpa membaca byte gambar.
List<Map<String, dynamic>> pendingInspectionPhotosForDocument(
  List<Map<String, dynamic>> pending,
  String documentId,
) {
  return pending
      .where((item) => item['docId'] == documentId)
      .toList(growable: false);
}

String? pendingInspectionPhotoPath(
  List<Map<String, dynamic>> photos, {
  required int storedIndex,
  required String tirePosition,
}) {
  // Utamakan nomor posisi ban agar tidak tergantung urutan array terbaru.
  for (final item in photos.reversed) {
    if (tirePosition.isNotEmpty && item['tirePosition'] == tirePosition) {
      return item['filePath'] as String?;
    }
  }
  // Kompatibilitas antrean lama yang hanya memiliki index array dokumen.
  for (final item in photos.reversed) {
    if ((item['tirePosition']?.toString() ?? '').isEmpty &&
        item['posisiIndex'] == storedIndex) {
      return item['filePath'] as String?;
    }
  }
  return null;
}

/// Lengkapi metadata antrean lama tanpa menambah entry atau membaca file.
bool bindPendingInspectionPhotoPositions(
  List<Map<String, dynamic>> pending,
  String documentId,
  List<dynamic> storedPositions,
) {
  var changed = false;
  for (final item in pending) {
    if (item['docId'] != documentId ||
        (item['tirePosition']?.toString() ?? '').isNotEmpty) continue;
    final index = item['posisiIndex'];
    if (index is! int || index < 0 || index >= storedPositions.length) continue;
    final position = storedPositions[index];
    if (position is! Map) continue;
    final key = (position['position'] ?? position['pos'])?.toString() ?? '';
    if (key.isEmpty) continue;
    item['tirePosition'] = key;
    changed = true;
  }
  return changed;
}

bool upsertPendingInspectionPhoto(
  List<Map<String, dynamic>> pending, {
  required String docId,
  required String filePath,
  required int posisiIndex,
  String tirePosition = '',
}) {
  bool matches(Map<String, dynamic> item) {
    if (item['docId'] != docId) return false;
    final storedPosition = item['tirePosition']?.toString() ?? '';
    if (tirePosition.isNotEmpty && storedPosition.isNotEmpty) {
      return storedPosition == tirePosition;
    }
    return item['posisiIndex'] == posisiIndex;
  }

  final existing = pending.where(matches).toList();
  if (existing.length == 1 &&
      existing.single['filePath'] == filePath &&
      existing.single['posisiIndex'] == posisiIndex &&
      (existing.single['tirePosition']?.toString() ?? '') == tirePosition) {
    return false;
  }
  pending.removeWhere(matches);
  pending.add({
    'docId': docId,
    'filePath': filePath,
    'posisiIndex': posisiIndex,
    if (tirePosition.isNotEmpty) 'tirePosition': tirePosition,
  });
  return true;
}

int inspectionPhotoPositionIndex(
  List<dynamic> positions, {
  required int fallbackIndex,
  String tirePosition = '',
}) {
  if (tirePosition.isNotEmpty) {
    return positions.indexWhere((item) =>
        item is Map &&
        (item['position'] ?? item['pos'])?.toString() == tirePosition);
  }
  return fallbackIndex >= 0 && fallbackIndex < positions.length
      ? fallbackIndex
      : -1;
}

Map<String, dynamic> inspectionPhotoFields({
  required List<dynamic> existingImages,
  required bool existingPending,
  required String? newLocalImagePath,
}) {
  final hasNewImage = newLocalImagePath?.trim().isNotEmpty == true;
  return {
    'images': hasNewImage ? <dynamic>[] : List<dynamic>.from(existingImages),
    'imagePending': hasNewImage || existingPending,
  };
}
