//lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registrar nuevo usuario
  Future<UserModel?> register({
    required String email,
    required String password,
    required String nombre,
    required String telefono,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear documento de usuario en Firestore
      final userModel = UserModel(
        id: userCredential.user!.uid,
        email: email,
        nombre: nombre,
        telefono: telefono,
        fechaRegistro: DateTime.now(),
        rol: 'cliente',
      );

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al registrar usuario: $e';
    }
  }

  // Iniciar sesión
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Obtener datos del usuario desde Firestore
      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw 'Usuario no encontrado en la base de datos';
      }

      return UserModel.fromMap(userDoc.data()!, userDoc.id);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al iniciar sesión: $e';
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error al cerrar sesión: $e';
    }
  }

  // Recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al enviar correo de recuperación: $e';
    }
  }

  // Obtener datos del usuario actual
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return null;

      return UserModel.fromMap(userDoc.data()!, userDoc.id);
    } catch (e) {
      throw 'Error al obtener datos del usuario: $e';
    }
  }

  // Actualizar datos del usuario
  Future<void> updateUserData({
    required String userId,
    required String nombre,
    required String telefono,
  }) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update({
        'nombre': nombre,
        'telefono': telefono,
      });
    } catch (e) {
      throw 'Error al actualizar datos del usuario: $e';
    }
  }

  // Cambiar contraseña
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw 'No hay usuario autenticado';

      // Re-autenticar al usuario
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Cambiar contraseña
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al cambiar contraseña: $e';
    }
  }

  // Manejar excepciones de Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'user-disabled':
        return 'Este usuario ha sido deshabilitado';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
