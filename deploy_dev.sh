set -e

rm -rf public
rm -rf public_prod
rm -rf public_wts

# # # build
cd webapp
webdev build
mv build ../public
cd ..

# Predeploy verify that the dev strings are present
if ! grep "https://fir-test-b0eb7.firebaseio.com" public/main.dart.js; then echo "dev config not found"; exit 1; fi
if ! grep "AIzaSyAVM9wsuKG0ANdKnkJjNN6lTmmH0fD_v68" public/main.dart.js; then echo "dev config not found"; exit 1; fi
if ! grep "fir-test-b0eb7" public/main.dart.js; then echo "dev config not found"; exit 1; fi

# Predeploy verify that the prod strings are not present
if grep "https://web-coda.firebaseio.com" public/main.dart.js; then echo "prod config found"; exit 1; fi
if grep "AIzaSyAdwgBTgdD2oNYP9VwyS9fQd6sf5roqLuA" public/main.dart.js; then echo "prod config found"; exit 1; fi
if grep "web-coda" public/main.dart.js; then echo "prod config found"; exit 1; fi

# Predeploy verify that the wts strings are not present
if grep "https://XXXXXXXXX.firebaseio.com" public_wts/main.dart.js; then echo "prod config not found"; exit 1; fi
if grep "XXXXXXXXX" public_wts/main.dart.js; then echo "prod config not found"; exit 1; fi
if grep "XXXXXXXXX" public_wts/main.dart.js; then echo "prod config not found"; exit 1; fi

# # deploy
firebase deploy --project fir-test-b0eb7 --public public
