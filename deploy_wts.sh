set -e

rm -rf public
rm -rf public_prod
rm -rf public_wts

# # Move the dev constants
mv webapp/lib/firebase_constants.dart webapp/lib/firebase_constants_dev.dart 
mv webapp/lib/firebase_constants_wts.dart webapp/lib/firebase_constants.dart 

# # build
cd webapp
webdev build
mv build ../public_wts
cd ..

# Predeploy verify that the wts strings are present
if ! grep "https://wts-experiments.firebaseio.com" public_wts/main.dart.js; then echo "prod config not found"; exit 1; fi
if ! grep "AIzaSyAKxMisrwwy4bWTXuHPBV-CInpn9bjXYFY" public_wts/main.dart.js; then echo "prod config not found"; exit 1; fi
if ! grep "wts-experiments" public_wts/main.dart.js; then echo "prod config not found"; exit 1; fi

# Predeploy verify that the dev strings are not present
if grep "https://fir-test-b0eb7.firebaseio.com" public_wts/main.dart.js; then echo "dev config found"; exit 1; fi
if grep "AIzaSyAVM9wsuKG0ANdKnkJjNN6lTmmH0fD_v68" public_wts/main.dart.js; then echo "dev config found"; exit 1; fi
if grep "fir-test-b0eb7" public_wts/main.dart.js; then echo "dev config found"; exit 1; fi

# Predeploy verify that the prod strings are not present
if ! grep "https://web-coda.firebaseio.com" public_wts/main.dart.js; then echo "prod config not found"; exit 1; fi
if ! grep "AIzaSyAdwgBTgdD2oNYP9VwyS9fQd6sf5roqLuA" public_wts/main.dart.js; then echo "prod config not found"; exit 1; fi
if ! grep "web-coda" public_wts/main.dart.js; then echo "prod config not found"; exit 1; fi

# # deploy
firebase deploy --project wts-experiments --public public_wts

# # Revert to dev constants
mv webapp/lib/firebase_constants.dart webapp/lib/firebase_constants_wts.dart 
mv webapp/lib/firebase_constants_dev.dart webapp/lib/firebase_constants.dart 
