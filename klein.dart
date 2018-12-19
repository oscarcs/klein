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
    }
    print(inputFileName);

    File inputFile = new File(inputFileName);
    inputFile
        .readAsString()
        .then((String f) {
            print(f);
        })
        .catchError((e) {
            print('Error: Could not find input file \'$inputFileName\'.');
        });
}
