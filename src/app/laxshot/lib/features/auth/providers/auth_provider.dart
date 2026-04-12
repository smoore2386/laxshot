import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

final authProvider = FutureProvider((ref) async {
  final auth = FirebaseAuth.instance;

  return auth.currentUser != null;
});

final userStateChanges = StreamProvider((ref) {
  return FirebaseAuth.instance.userChanges();
});

final userEmail = StreamProvider((ref) {
  return FirebaseAuth.instance.userChanges().map((user) => user?.email);
});

final userId = StreamProvider((ref) {
  return FirebaseAuth.instance.userChanges().map((user) => user?.uid);
});

final isLoggedIn = FutureProvider((ref) async {
  final auth = FirebaseAuth.instance;

  return auth.currentUser != null;
});
