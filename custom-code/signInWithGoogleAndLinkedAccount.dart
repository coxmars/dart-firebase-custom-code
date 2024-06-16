import 'package:flutter/foundation.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Función para obtener la versión de la aplicación
Future<AppInfoStruct> appVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;

  // Crear una instancia del struct AppInfoStruct
  AppInfoStruct appInfo = AppInfoStruct(
    appVersion: version,
    bundleVersion: buildNumber,
  );

  return appInfo;
}

Future<bool> signInWithGoogleAndLinkedAccount() async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    print("currentUser.isAnonymous = ${currentUser?.isAnonymous}");

    final userCredential;

    if (kIsWeb) {
      print("Executing Web Sing in");

      userCredential =
          await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      print("userCredential = ${userCredential}");
    } else {
      print("Executing Monbile Sing in");

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        print("googleUser is null");
        return false;
      }

      final GoogleSignInAuthentication? googleAuth =
          await googleUser.authentication;
      userCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
    }

    if (currentUser != null && userCredential != null) {
      await currentUser.linkWithCredential(userCredential!);
      print("userCredential = ${userCredential}");
      // Crear user en coleccion Users con los datos de Google
      print("Current User: ${FirebaseAuth.instance.currentUser}");

      final setEmail =
          FirebaseAuth.instance.currentUser?.providerData.first.email;
      final setDisplayName =
          FirebaseAuth.instance.currentUser?.providerData.first.displayName;
      final setPhotoUrl =
          FirebaseAuth.instance.currentUser?.providerData.first.photoURL;

      // Obtener la información de la versión de la app
      final appInfo = await appVersion();

      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      await userDoc.update(
        {
          'email': setEmail,
          'display_name': setDisplayName,
          'photo_url': setPhotoUrl,
          'app_info': {
            'app_version': appInfo.appVersion,
            'bundle_version': appInfo.bundleVersion,
          }
        },
      );

      print("Cuentas sincronizadas.");
      return true;
    }
  } on Exception catch (e) {
    print('exception->$e');
  }

  return false;
}