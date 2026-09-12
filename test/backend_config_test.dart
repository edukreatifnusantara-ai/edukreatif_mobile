import 'package:flutter_test/flutter_test.dart';
import 'package:edukreatif_mobile/config/backend_config.dart';

void main() {
  test('backend remains safely offline without deployment credentials', () {
    expect(BackendConfig.isConfigured, isFalse);
  });
}
