import 'package:flutter/foundation.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

Future<bool> signInWithAppleAndLinkedAccount() async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    print("currentUser.isAnonymous = ${currentUser?.isAnonymous}");

    final userCredential;

    if (kIsWeb) {
      // Autenticación en la web
      print("Executing Web Sign In");
      userCredential =
          await FirebaseAuth.instance.signInWithPopup(AppleAuthProvider());
      print("userCredential = ${userCredential}");
    } else {
      // Autenticación en dispositivos móviles
      print("Executing Mobile Sign In");
      final AuthorizationCredentialAppleID? appleUser =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (appleUser == null) {
        print("appleUser is null");
        return false;
      }

      userCredential = OAuthProvider("apple.com").credential(
        idToken: appleUser.identityToken,
        accessToken: appleUser.authorizationCode,
      );
    }

    if (currentUser != null && userCredential != null) {
      // Vinculación de la cuenta anónima con la cuenta de Apple
      await currentUser.linkWithCredential(userCredential);
      print("Cuentas sincronizadas.");

      // Opcional: Crear o actualizar usuario en la colección 'Users'
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

      return true;
    }
  } on FirebaseAuthException catch (e) {
    print('FirebaseAuthException->$e');
  } catch (e) {
    print('Exception->$e');
  }

  return false;
}