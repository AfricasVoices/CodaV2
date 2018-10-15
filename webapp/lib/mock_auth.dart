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
    _logCall('currentUser', 'auth', _user.displayName);
    return _user;
  }

  Stream<firebase.User> _authState = new Stream.empty();

  @override
  Stream<firebase.User> get onAuthStateChanged {
    _logCall('onAuthStateChanged', 'auth', '');
    return _authState;
  }

  @override
  Future signOut() async {
    _logCall('signOut', 'auth', '');
    return true;
  }

  @override
  Future<firebase.UserCredential> signInWithPopup(firebase.AuthProvider<auth_interop.AuthProviderJsImpl> provider) async {
    _logCall('signInWithPopup', 'auth', provider.providerId);
    return null;
  }

  noSuchMethod(Invocation invocation) async {
    _logCall(invocation.memberName, 'auth', invocation.positionalArguments);
    return null;
  }
}

class MockUser implements firebase.User {

  @override
  String get displayName {
    String name = 'Sample User';
    _logCall('displayName', 'user', name);
    return name;
  }

  @override
  String get email {
    String email = 'info@example.com';
    _logCall('email', 'user', email);
    return email;
  }

  @override
  String get phoneNumber {
    String phone = '07123456789';
    _logCall('phoneNumber', 'user', phone);
    return phone;
  }

  @override
  String get photoURL {
    String photo = 'http://example.com/photoURL';
    _logCall('photoURL', 'user', photo);
    return photo;
  }

  @override
  String get uid {
    String uid = 'asdfghjkl';
    _logCall('uid', 'user', uid);
    return uid;
  }

  noSuchMethod(Invocation invocation) {
    firestoreCallLog.add({
      'callType': '${invocation.memberName}',
      'target': 'auth',
      'content': '${invocation.positionalArguments}'
    });
    return null;
  }
}

_logCall(var callType, var target, var content) {
  firestoreCallLog.add({
    'callType': callType,
    'target': target,
    'content': content
  });
}
