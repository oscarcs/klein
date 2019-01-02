import '../klein.dart';

class Preprocessor {
    String fileContents;
    String path;

    Preprocessor(String fileContents, String path) {
        this.fileContents = fileContents;
        this.path = path;
    }

    String preprocess() {
        String output = fileContents;
        for (Match match in '@@'.allMatches(output)) {
            int loc = match.start;
            while (output[loc] != '\n' && output[loc] != '\r') {
                loc++;
            }

            String line = output.substring(match.start + 2, loc);

            // Execute the line
            String result = Klein.interpreter.interpret(code: line);
            if (result == null) {
                result = '';
            }
            output = output.replaceRange(match.start, loc, result);
        }
        return output;
    }
}