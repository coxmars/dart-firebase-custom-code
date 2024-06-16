import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

Future<String> createUser(
  String email,
  String password,
  String randomDocGen,
) async {
  String message = "User created";
  DateTime created_time = DateTime.now();

  FirebaseApp app = await Firebase.initializeApp(
      name: randomDocGen, options: Firebase.app().options);

  try {
    UserCredential userCredential = await FirebaseAuth.instanceFor(app: app)
        .createUserWithEmailAndPassword(email: email, password: password);
    String? uid = userCredential.user?.uid;

    if (uid != null) {
      final CollectionReference<Map<String, dynamic>> user =
          FirebaseFirestore.instance.collection('users');
      user.doc(uid).set({
        'uid': uid,
        'email': email,
        'created_time': created_time,
      });
    } else {
      return 'Error';
    }

    return message;
  } on FirebaseAuthException catch (e) {
    return e.code;
  }
}