class Preprocessor {
    String fileContents;
    String path;

    Preprocessor(String fileContents, String path) {
        this.fileContents = fileContents;
        this.path = path;
    }

    String preprocess() {
        print(fileContents);
        return fileContents;
    }
}