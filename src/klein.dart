import 'dart:io';

const MIN_ARGS = 1;
const MAX_ARGS = 1;

main(List<String> args) {
    if (args.length < MIN_ARGS || args.length > MAX_ARGS) {
        print('Wrong number of arguments.');
        return;
    }

    String inputFileName;
    for (int i = 0; i < args.length; i++) {
        if (inputFileName == null && !args[i].startsWith('-')) {
            inputFileName = args[i];
        }
        else if (args[i].startsWith('-')) {
            if (args[i].toLowerCase() == '-h' || args[i].toLowerCase() == '--help') {
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
                print(f);
            })
            .catchError((e) {
                error('Could not read input file \'$inputFileName\'.');
            });
    }
    else {
        error('Please provide an input configuration file.');
    }
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