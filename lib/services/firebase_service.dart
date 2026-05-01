import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/game.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authChanges => _auth.authStateChanges();

  // ── Auth ────────────────────────────────────────────────────────

  static Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Flutter Web: usa signInWithPopup direto no firebase_auth
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        final result = await _auth.signInWithPopup(provider);
        return result.user;
      } else {
        // Android / iOS: fluxo padrão via google_sign_in
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await _auth.signInWithCredential(credential);
        return result.user;
      }
    } catch (e) {
      // ignore: avoid_print
      print('[FirebaseService] signInWithGoogle error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Wishlist ────────────────────────────────────────────────────

  static CollectionReference? _wishlist() {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('wishlist');
  }

  static Future<void> addToWishlist(Game game) async {
    await _wishlist()?.doc('${game.id}').set({
      'id': game.id,
      'name': game.name,
      'backgroundImage': game.backgroundImage,
      'metacritic': game.metacritic,
      'genres': game.genres,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeFromWishlist(int gameId) async {
    await _wishlist()?.doc('$gameId').delete();
  }

  static Future<bool> isInWishlist(int gameId) async {
    final doc = await _wishlist()?.doc('$gameId').get();
    return doc?.exists ?? false;
  }

  static Stream<List<Map<String, dynamic>>> watchWishlist() {
    final col = _wishlist();
    if (col == null) return const Stream.empty();
    return col
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data() as Map<String, dynamic>).toList());
  }
}