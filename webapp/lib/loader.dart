/**
 * A snackbar UI widget for showing notifications or errors in Coda.
 */
import 'dart:html';

DivElement get loader => querySelector('#loader');

void showLoader(String message) {
  loader.attributes.remove('hidden');
  loader.querySelector('.contents').text = message;
}

void hideLoader() {
    loader.setAttribute('hidden', 'true');
    loader.querySelector('.contents').text = '';
  }
