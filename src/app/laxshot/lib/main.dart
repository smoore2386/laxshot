import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/dev_config.dart';
import 'firebase_options.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Connect to Firebase Emulator Suite in dev mode
  if (DevConfig.useEmulator) {
    await FirebaseAuth.instance
        .useAuthEmulator(DevConfig.emulatorHost, 9099);
    FirebaseFirestore.instance
        .useFirestoreEmulator(DevConfig.emulatorHost, 8080);
    FirebaseFunctions.instance
        .useFunctionsEmulator(DevConfig.emulatorHost, 5001);
  }

  // Portrait only — better for camera recording UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: LaxShotApp(),
    ),
  );
}
