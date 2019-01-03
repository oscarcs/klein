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
        
        Match match = firstMatchOrNull('@@', output);
        while (match != null) {
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

            // Recalculate the next match
            match = firstMatchOrNull('@@', output);
        }
        return output;
    }

    /// Get the next match; otherwise return null.
    Match firstMatchOrNull(String pattern, String content) {
        Iterable<Match> matches = pattern.allMatches(content);
        if (matches.length > 0) {
            return matches.first;
        }
        return null;
    }
}