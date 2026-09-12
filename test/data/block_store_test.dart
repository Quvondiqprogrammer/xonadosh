import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xonadosh/data/api/block_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('block is case-insensitive and can be undone', () async {
    final store = BlockStore();
    await store.block('Jasur_Dev');
    expect(await store.isBlocked('jasur_dev'), isTrue);
    expect(await store.load(), contains('jasur_dev'));

    await store.unblock('JASUR_DEV');
    expect(await store.isBlocked('jasur_dev'), isFalse);
  });

  test('empty username is ignored', () async {
    final store = BlockStore();
    await store.block('   ');
    expect(await store.load(), isEmpty);
  });
}
