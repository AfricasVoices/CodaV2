/**
 * A snackbar UI widget for showing notifications or errors in Coda.
 */
import 'dart:async';
import 'dart:html';

enum NotificatonType {
  notification,
  warning,
  error
}

DivElement get snackbar => querySelector('#snackbar');

init() {
  snackbar.querySelector('.close').onClick.listen((click) {
    hideSnackbar();
  });
}

showSnackbar(String message, NotificatonType type) {
  snackbar.querySelector('.contents').text = message;
  snackbar.attributes.remove('hidden');
  snackbar.setAttribute('type', type.toString().replaceAll('NotificatonType.', ''));
  new Timer(new Duration(seconds: 3), () => hideSnackbar());
}

hideSnackbar() {
  snackbar.querySelector('.contents').text = '';
  snackbar.setAttribute('hidden', 'true');
  snackbar.attributes.remove('type');
}
