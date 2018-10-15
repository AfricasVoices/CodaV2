import "config.dart";

log(String s) => write(s);

verbose(String s) {
}

write(String s) => print ("${DateTime.now().toIso8601String()}: $s");