/// Library for handling authentication to Firebase following the example at
/// https://github.com/firebase/friendlychat-web/blob/master/web/scripts/main.js
library coda.auth;

import 'dart:html';

import 'package:firebase/firebase.dart' as firebase;

import 'config.dart';
import 'firebase_tools.dart' as fbt;
import 'main_ui.dart' as ui;
import 'mock_auth.dart' as mock;

ButtonElement signOutButton = querySelector('#sign-out');
ButtonElement signInButtonNav = querySelector('#sign-in-nav');
ButtonElement signInButtonMain = querySelector('#sign-in-main');
DivElement signInPanel = querySelector('#sign-in-panel');
DivElement userPicElement = querySelector('#user-pic');
DivElement userNameElement = querySelector('#user-name');


firebase.Auth get firebaseAuth {
  if (TEST_MODE) {
    return mock.auth();
  } else {
    return firebase.auth();
  }
}

/// Signs the user in.
signIn() {
  var provider = new firebase.GoogleAuthProvider();
  firebaseAuth.signInWithPopup(provider);
}

/// Signs the user out.
signOut() {
  firebaseAuth.signOut();
}

/// Initialise firebase authentication.
init() {
  firebaseAuth.onAuthStateChanged.listen(authStateObserver);

  signInButtonNav.onClick.listen((_) => signIn());
  signInButtonMain.onClick.listen((_) => signIn());
  signOutButton.onClick.listen((_) => signOut());
}

/// Returns the signed-in user's profile Pic URL.
String getProfilePicUrl() {
  String photoURL = firebaseAuth.currentUser.photoURL;
  if (photoURL == null) {
    photoURL =  '/assets/user_image_placeholder.png';
  }
  return photoURL;
}

/// Returns the signed-in user's display name.
String getUserName() {
  return firebaseAuth.currentUser.displayName;
}

/// Returns the signed-in user's email address.
String getUserEmail() {
  return firebaseAuth.currentUser.email;
}

/// Returns true if a user is signed-in.
bool isUserSignedIn() {
  return firebaseAuth.currentUser != null;
}

/// Triggers when the authentication state changes (e.g. when the user signs-in or signs-out).
void authStateObserver(firebase.User user) {
  if (user == null) { // User not signed in
    // Hide user's profile pic, name and sign-out button.
    userNameElement.setAttribute('hidden', 'true');
    userPicElement.setAttribute('hidden', 'true');
    signOutButton.setAttribute('hidden', 'true');

    // Show sign-in button.
    signInButtonNav.attributes.remove('hidden');
    signInPanel.attributes.remove('hidden');

    // Display signed out view.
    ui.codaUI.displaySignedOutView();
  } else { // User signed in
    // Set the user's profile pic and name
    userPicElement.style.backgroundImage = 'url(${getProfilePicUrl()})';
    userNameElement.text = getUserName();

    // Show user's profile pic, name and sign-out button.
    userNameElement.attributes.remove('hidden');
    userPicElement.attributes.remove('hidden');
    signOutButton.attributes.remove('hidden');

    // Hide sign-in button.
    signInButtonNav.setAttribute('hidden', 'true');
    signInPanel.setAttribute('hidden', 'true');

    // Load the data for this user
    String datasetName = Uri.base.queryParameters["dataset"];
    var dataset;
    try {
      dataset = fbt.loadDataset(datasetName);
    } catch (e) {
      ui.codaUI.displayUrlErrorView(e.toString());
      return;
    }
    ui.codaUI.displayDatasetView(dataset);
  }
}
