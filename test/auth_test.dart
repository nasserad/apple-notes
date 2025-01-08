import 'package:apple_notes/services/auth/auth_exceptions.dart';
import 'package:apple_notes/services/auth/auth_provider.dart';
import 'package:apple_notes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvider();
    test('Should not be initialized from the get-go', () {
      expect(provider._isInitialized, false);
    });

    test('Cannot log out if not initialized', () {
      expect(
          provider.signOut(),
          throwsA(
            const TypeMatcher<NotInitializedException>(),
          ));
    });

    test('Should be able to be initialized', () async {
      await provider.initialize();
      expect(provider._isInitialized, true);
    });

    test('User should be null after initialization', () {
      expect(provider.currentUser, null);
    });

    test(
      'Should be able to initialize in less than 3 seconds',
      () async {
        //Testing async stuff (thru timingout)
        await provider.initialize();
        expect(provider._isInitialized, true);
      },
      timeout: const Timeout(
          Duration(seconds: 3)), // This will terminate the call after 3 secs.
    );

    test('createUser() should delegate to logIn()', () async {
      // Scenario A: User Not Found
      final badEmailUser = provider.createUser(
        email: 'bla@bla.com',
        password: 'anyPasswordLiterally',
      );
      expect(
        badEmailUser,
        throwsA(const TypeMatcher<UserNotFoundAuthException>()),
      );

      // Scenario B: Wrong Password
      final badPasswordUser = provider.createUser(
        email: 'anyEmail@bla.com',
        password: '123',
      );
      expect(
        badPasswordUser,
        throwsA(const TypeMatcher<WrongPasswordAuthException>()),
      );

      // Scenario C (Positive Scenario): User Created Successfully
      final goodNewUser = await provider.createUser(
        email: 'fr334e',
        password: 'pales1tine',
      );
      expect(
        provider.currentUser,
        goodNewUser,
      );
      expect(goodNewUser.isEmailVerified, false);
    });

    test('Logged in user should be able to get verified', () async {
      await provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified,
          true); // We used force (its okay because we replaced/protected-ourselves-against the null runtime error w/ the above null expectation).
    });

    test('Should be able to logout and login again', () async {
      await provider.signOut();
      await provider.logIn(
        email: 'email',
        password: 'password',
      );
      final user = provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;
  AuthUser? _user;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 1));
    return logIn(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) {
    if (!_isInitialized) throw NotInitializedException();
    if (email == 'bla@bla.com') throw UserNotFoundAuthException();
    if (password == '123') throw WrongPasswordAuthException();
    const user = AuthUser(isEmailVerified: false);
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    const newUser = AuthUser(isEmailVerified: true);
    _user = newUser;
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> signOut() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotLoggedInAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }
}
