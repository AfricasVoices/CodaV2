# Changes needed for adding a new deployment target

This file details what needs to be added and modified to add a new deployment. For the rest of the file, words in brackets (e.g. <NAME>) should be replaced with the corresponding values for the new deployment.


## Firebase constants file

Create a new Dart file `webapp/lib/firebase_constants_<NAME>.dart` containing the constants you get from the Firebase console of the new project, under the Add app button.

An example file can be found at https://github.com/AfricasVoices/CodaV2/blob/master/webapp/lib/firebase_constants_wts.dart


## New deploy script

Create a new script `deploy_<NAME>.sh` in the root of the repo which builds the web app, checks that it references the correct Firebase constants and deploys it.

An example file can be found at https://github.com/AfricasVoices/CodaV2/blob/master/deploy_wts.sh


## Update existing deploy scripts and .gitignore

Add the corresponding predeployment verification for the other existing deployment scripts.

If building the web app to a new folder, this new folder should also be added to the `.gitignore` file.


## PR Example

[PR #164](https://github.com/AfricasVoices/CodaV2/pull/164/files) followed by [PR #165](https://github.com/AfricasVoices/CodaV2/pull/165/files) are an example of adding a new deployment target.
