import 'package:firebase_auth/firebase_auth.dart';

Future<bool> changePassword(String currentPassword, String newPassword) async {
  // Obtener el usuario actual
  final user = FirebaseAuth.instance.currentUser;

  if (user != null && user.email != null) {
    // Obtén el email del usuario autenticado
    String email = user.email!;

    // Credenciales del usuario para la re-autenticación
    AuthCredential credential =
        EmailAuthProvider.credential(email: email, password: currentPassword);

    try {
      // Re-autenticar al usuario
      await user.reauthenticateWithCredential(credential);

      // Cambiar la contraseña
      await user.updatePassword(newPassword);
      print("Password changed successfully");
      return true;
    } catch (error) {
      // Manejo de errores
      print("Error to change password: $error");
      return false;
    }
  } else {
    print("There is not an authenticated user");
    return false;
  }
}