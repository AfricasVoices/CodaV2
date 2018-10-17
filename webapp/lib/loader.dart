/**
 * A loader animation UI widget for showing dataset loading progress.
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
