import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStatechanges => _auth.authStateChanges();

  Future<String?> signIn({
    required String email,
    required String password,
}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    }    on FirebaseAuthException catch(e) {
      return _handleAuthException(e);
    }
  }
}
  String _handleAuthException (FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong password':
        return 'wrong password provided';
      case 'email-already-in-use':
        return 'An Account already exists with this email';
      case 'Invalid-email':
        return 'The email address is invalid';
      case 'weeak-password':
        return 'The password is too weak';
      case 'Operation not allowed':
        return 'Operation not allowed. Please contact Chat-gpt';
      case 'user disabled':
        return 'This user account has been disable';
      default:
        return 'An error occured. Please Try Agian!';
    }
  }