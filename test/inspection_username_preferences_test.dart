import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('nama inspector disimpan terpisah untuk setiap akun', () async {
    await saveInspectionUsername(
      accountId: 'account-a',
      username: 'Inspector A',
    );
    await saveInspectionUsername(
      accountId: 'account-b',
      username: 'Inspector B',
    );

    expect(
      await getInspectionUsername(accountId: 'account-a'),
      'Inspector A',
    );
    expect(
      await getInspectionUsername(accountId: 'account-b'),
      'Inspector B',
    );
  });

  test('nilai kosong menghapus nama inspector pilihan', () async {
    await saveInspectionUsername(
      accountId: 'account-a',
      username: '  Inspector A  ',
    );
    expect(
      await getInspectionUsername(accountId: 'account-a'),
      'Inspector A',
    );

    await saveInspectionUsername(
      accountId: 'account-a',
      username: '   ',
    );

    expect(await getInspectionUsername(accountId: 'account-a'), isEmpty);
  });
}
