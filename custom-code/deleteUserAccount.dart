import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// Re-autenticar con Email y Contraseña
Future<bool> reauthenticateWithEmail(
    String email, String currentPassword) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    AuthCredential credential =
        EmailAuthProvider.credential(email: email, password: currentPassword);
    try {
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print("Error in email/password reauthentication: $e");
      return false;
    }
  }
  return false;
}

// Re-autenticar con Google
Future<bool> reauthenticateWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      return false;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.currentUser
        ?.reauthenticateWithCredential(credential);
    return true;
  } catch (e) {
    print("Error in Google reauthentication: $e");
    return false;
  }
}

// Re-autenticar con Apple
Future<bool> reauthenticateWithApple() async {
  try {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    await FirebaseAuth.instance.currentUser
        ?.reauthenticateWithCredential(oauthCredential);
    return true;
  } catch (e) {
    print("Error in Apple reauthentication: $e");
    return false;
  }
}

// Función para Re-autenticar según el Proveedor
Future<bool> reauthenticate(User user, String? currentPassword) async {
  if (user.providerData.any((userInfo) => userInfo.providerId == 'password')) {
    if (currentPassword != null && user.email != null) {
      return await reauthenticateWithEmail(user.email!, currentPassword);
    } else {
      print("Password is required for email/password reauthentication");
      return false;
    }
  } else if (user.providerData
      .any((userInfo) => userInfo.providerId == 'google.com')) {
    return await reauthenticateWithGoogle();
  } else if (user.providerData
      .any((userInfo) => userInfo.providerId == 'apple.com')) {
    return await reauthenticateWithApple();
  } else {
    print("No supported reauthentication method available");
    return false;
  }
}

// Función para Eliminar la Cuenta
Future<bool> deleteUserAccount(String? currentPassword) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    bool reauthenticated = await reauthenticate(user, currentPassword);
    if (reauthenticated) {
      try {
        await user.delete();
        print("Account deleted successfully");
        return true;
      } catch (error) {
        print("Error to delete account: $error");
        return false;
      }
    } else {
      print("Re-authentication failed");
      return false;
    }
  } else {
    print("There is not an authenticated user");
    return false;
  }
}