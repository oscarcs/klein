import 'dart:io';
import 'src/config_parser.dart';

main(List<String> args) {
    String inputFileName;
    for (var arg in args) {
        if (inputFileName == null && !isOption(arg)) {
            inputFileName = arg;
        }
        else if (isOption(arg)) {
            if (arg.toLowerCase() == '-h' || arg.toLowerCase() == '--help') {
                printHelp();
            }
            return;
        }
    }
    if (inputFileName != null) {
        File inputFile = new File(inputFileName);
        inputFile
            .readAsString()
            .then((String f) {
                try {
                    var parser = new ConfigParser(f);
                    var config = parser.parse();
                }
                catch (e, s) {
                    print(e);
                    print(s);
                }
            })
            .catchError((e) {
                error('Could not read input file \'$inputFileName\'.');
            });
    }
    else {
        error('Please provide an input configuration file.');
    }
}

bool isOption(String arg) {
  return arg.startsWith('-');
}

void error(String msg) {
    print('Error: $msg');
}

void printHelp() {
    print('''
Klein: Web development the hard way.
v0001

Usage: klein <input_file | task> [options]

Options:
    -h, --help      Prints this help message.''');
}