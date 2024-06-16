import 'package:firebase_auth/firebase_auth.dart';

Future linkAnonymousAccountToRegular(
    String emailAddress, String userPassword) async {
  // Obtener el usuario actual
  final currentUser = FirebaseAuth.instance.currentUser;

  // Crear credenciales de autenticación para la nueva cuenta
  final credential =
      EmailAuthProvider.credential(email: emailAddress, password: userPassword);

  try {
    // Vincular la cuenta anónima con las nuevas credenciales
    await currentUser?.linkWithCredential(credential);
    //print("currentUser: ${currentUser}");

    // Buscar el documento del usuario en Firestore y actualizar el email
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(currentUser?.uid);
    await userDoc.update({'email': emailAddress});
    //print("Email actualizado en Firestore");

    // Recargar la información del usuario para actualizar la sesión
    await currentUser?.reload();
    print("Cuentas vinculadas exitosamente");
    //print("Email: ${currentUser?.email}");
  } on FirebaseAuthException catch (e) {
    print("Error al vincular cuentas: $e");
    // Manejar errores aquí
  }
}