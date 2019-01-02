import 'dart:io';
import 'src/interpreter.dart';

class Klein {
    static Interpreter interpreter;  
}

main(List<String> args) {
    String inputFileName;
    List<String> inputArgs = [];
    for (var arg in args) {
        if (inputFileName == null && !isOption(arg)) {
            inputFileName = arg;
        }
        else if (inputFileName != null && !isOption(arg)) {
            inputArgs.add(arg);
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
                    Klein.interpreter = new Interpreter(f);
                    Klein.interpreter.interpret();
                    
                    if (inputArgs.length > 0) {
                        if (inputArgs[0] == 'list') {
                            print('The available tasks are:');
                            Klein.interpreter.getTaskNames().forEach((name) => print('   $name'));
                        }
                        else {
                            Klein.interpreter.task(inputArgs[0], inputArgs.sublist(1));
                        }
                    }
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