import 'dart:async';

import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/src/interop/auth_interop.dart' as auth_interop;

import 'config.dart';

MockAuth _testAuth = new MockAuth();

firebase.Auth auth() => _testAuth;

class MockAuth implements firebase.Auth {

  @override
  firebase.App get app => null;

  MockUser _user = new MockUser();

  @override
  firebase.User get currentUser {
    logFirestoreCall('currentUser', 'auth', _user.displayName);
    return _user;
  }

  Stream<firebase.User> _authState = new Stream.empty();

  @override
  Stream<firebase.User> get onAuthStateChanged {
    logFirestoreCall('onAuthStateChanged', 'auth', '');
    return _authState;
  }

  @override
  Future signOut() async {
    logFirestoreCall('signOut', 'auth', '');
    return true;
  }

  @override
  Future<firebase.UserCredential> signInWithPopup(firebase.AuthProvider<auth_interop.AuthProviderJsImpl> provider) async {
    logFirestoreCall('signInWithPopup', 'auth', provider.providerId);
    return null;
  }

  noSuchMethod(Invocation invocation) async {
    logFirestoreCall(invocation.memberName, 'auth', invocation.positionalArguments);
    return null;
  }
}

class MockUser implements firebase.User {

  @override
  String get displayName {
    String name = 'Sample User';
    logFirestoreCall('displayName', 'user', name);
    return name;
  }

  @override
  String get email {
    String email = 'info@example.com';
    logFirestoreCall('email', 'user', email);
    return email;
  }

  @override
  String get phoneNumber {
    String phone = '07123456789';
    logFirestoreCall('phoneNumber', 'user', phone);
    return phone;
  }

  @override
  String get photoURL {
    String photo = 'http://example.com/photoURL';
    logFirestoreCall('photoURL', 'user', photo);
    return photo;
  }

  @override
  String get uid {
    String uid = 'asdfghjkl';
    logFirestoreCall('uid', 'user', uid);
    return uid;
  }

  noSuchMethod(Invocation invocation) {
    logFirestoreCall(invocation.memberName, 'auth', invocation.positionalArguments);
    return null;
  }
}
