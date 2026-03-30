import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        if (data != null) {
          for (final entry in data.entries) {
            // Screenshots saved by the integration_test framework
            print('Screenshot: ${entry.key}');
          }
        }
      },
    );
