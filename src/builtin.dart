import 'dart:io';
import 'preprocessor.dart';

class Builtin {

    static void shell(String cmd) {
        Process.run(cmd, [], runInShell: true).then((result) {
            stdout.write(result.stdout);
            stderr.write(result.stderr);
        });
    }

    /// Copy a file or directory to another directory.
    static void copy(String source, String dest) {
        // If the destination directory doesn't exist, we need to create it.
        bool createdDir = false;
        Directory destDir = new Directory(dest);
        if (!destDir.existsSync()) {
            destDir.createSync(recursive: true);
            createdDir = true;
        }
        
        // If the source is a directory, then we must be copying a directory
        // into another directory:
        Directory sourceDir = new Directory(source);
        if (sourceDir.existsSync()) {
            
            // Recursively copy the contents of the source directory into the dest.
            sourceDir.listSync().forEach((element) {
                //@@TODO: Use some kind of platform-independent path abstraction.
                String filename = element.path.split(Platform.pathSeparator).last;
                String newPath = "${destDir.path}${Platform.pathSeparator}${filename}";
                
                if (element is File) {
                    element.copySync(newPath);
                } 
                else if (element is Directory) {
                    copy(element.path, newPath);
                }
            });
        }
        // Otherwise, the source is a file being copied into a directory.
        else {
            File sourceFile = new File(source);
            if (!sourceFile.existsSync()) {
                // The copy failed, so we should clean up after ourselves.
                if (createdDir) {
                    destDir.deleteSync(recursive: false);
                }
                throw 'The path ${source} does not exist.';
            }   

            //@@TODO: Use some kind of platform-independent path abstraction.
            String filename = sourceFile.path.split('/').last;
            String newPath = "${destDir.path}${Platform.pathSeparator}${filename}";

            sourceFile.copySync(newPath);           
        }
    }

    /// Delete a file or directory.
    static void delete(String path) {
        Directory obj = new Directory(path);
        if (obj.existsSync()) {
            obj.deleteSync(recursive: true);
        }
    }

    /// Run Klein on a file or set of files in a directory.
    static void preprocess(String source, String dest) {
        // If the destination directory doesn't exist, we need to create it.
        bool createdDir = false;
        Directory destDir = new Directory(dest);
        if (!destDir.existsSync()) {
            destDir.createSync(recursive: true);
            createdDir = true;
        }

        Directory dir = new Directory(source);
        if (dir.existsSync()) {
            dir.listSync().forEach((element) {
                preprocess(element.path, dest);
            });
        }
        else {
            File file = new File(source);
            if (file.existsSync()) {
                file.readAsString()
                .then((String f) {
                    Preprocessor p = new Preprocessor(f, source);
                    String output = p.preprocess();

                    String filename = file.path.split('/').last;
                    String newPath = "${destDir.path}${Platform.pathSeparator}${filename}";

                    new File(newPath).writeAsString(output)
                    .catchError((e) {
                        throw e;
                    });
                })
                .catchError((e) {
                    throw e;
                });
            }
            else {
                throw 'Cannot preprocess ${source} because it does not exist.';
            }
        }
    }

    /// Import a file
    static String import(String path) {
        String output;
        File file = new File(path);
        if (file.existsSync()) {
            output = file.readAsStringSync();
        }
        else {
            throw 'Cannot import ${path} because it does not exist.';
        }
        return output;
    }
}