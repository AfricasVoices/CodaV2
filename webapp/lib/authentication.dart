/// Library for handling authentication to Firebase following the example at
/// https://github.com/firebase/friendlychat-web/blob/master/web/scripts/main.js
library coda.auth;

import 'dart:html';

import 'package:firebase/firebase.dart' as firebase;

ButtonElement signInButton = querySelector('#sign-in');
ButtonElement signOutButton = querySelector('#sign-out');
DivElement userPicElement = querySelector('#user-pic');
DivElement userNameElement = querySelector('#user-name');

/// Signs the user in.
signIn() {
  var provider = new firebase.GoogleAuthProvider();
  firebase.auth().signInWithPopup(provider);
}

/// Signs the user out.
signOut() {
  firebase.auth().signOut();
}

/// Initialise firebase authentication.
initFirebaseAuth() {
  firebase.auth().onAuthStateChanged.listen(authStateObserver);

  signInButton.onClick.listen((_) => signIn());
  signOutButton.onClick.listen((_) => signOut());
}

/// Returns the signed-in user's profile Pic URL.
String getProfilePicUrl() {
  String photoURL = firebase.auth().currentUser.photoURL;
  if (photoURL == null) {
    photoURL =  '/assets/user_image_placeholder.png';
  }
  return photoURL;
}

/// Returns the signed-in user's display name.
String getUserName() {
  return firebase.auth().currentUser.displayName;
}

/// Returns the signed-in user's email address.
String getUserEmail() {
  return firebase.auth().currentUser.email;
}

/// Returns true if a user is signed-in.
bool isUserSignedIn() {
  return firebase.auth().currentUser != null;
}

/// Triggers when the authentication state changes (e.g. when the user signs-in or signs-out).
void authStateObserver(firebase.User user) {
  if (user == null) { // User not signed in
    // Hide user's profile pic, name and sign-out button.
    userNameElement.setAttribute('hidden', 'true');
    userPicElement.setAttribute('hidden', 'true');
    signOutButton.setAttribute('hidden', 'true');

    // Show sign-in button.
    signInButton.attributes.remove('hidden');
  } else { // User signed in
    // Set the user's profile pic and name
    userPicElement.style.backgroundImage = 'url(${getProfilePicUrl()})';
    userNameElement.text = getUserName();

    // Show user's profile pic, name and sign-out button.
    userNameElement.attributes.remove('hidden');
    userPicElement.attributes.remove('hidden');
    signOutButton.attributes.remove('hidden');

    // Hide sign-in button.
    signInButton.setAttribute('hidden', 'true');
  }
}
