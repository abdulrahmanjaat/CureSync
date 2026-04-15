import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

/// Mocktail mock for [User] from firebase_auth.
/// Firebase's User is abstract — this lets us control [uid] in tests
/// without a real Firebase project or plugin channel.
class MockFirebaseUser extends Mock implements User {
  MockFirebaseUser(String uid) {
    when(() => this.uid).thenReturn(uid);
    // Stub commonly-accessed nullable fields so tests don't hit MissingStubError
    when(() => displayName).thenReturn(null);
    when(() => email).thenReturn(null);
    when(() => photoURL).thenReturn(null);
    when(() => isAnonymous).thenReturn(false);
    when(() => emailVerified).thenReturn(false);
  }
}
