import 'dart:io';
import 'config_parser.dart';

/// A config file is just an AST of nodes to execute.
class Config {

    /// Symbol tables.
    //@@ENHANCEMENT: Stack of symbol tables for nested scopes.
    Map<String, String> localVars;
    Map<String, String> globalVars;
    Map<String, ConfigNode> funcs;

    Config() {

    }

    /// Execute statements in the top level.
    void run() {
        execute(funcs['@root']);
    }

    /// Execute a particular function as a task.
    void task(String task, List<String> args) {
        var node = new ConfigNode(ConfigNodeType.FunctionCall, []);
        
        var ident = new ConfigNode(ConfigNodeType.Ident, []);
        ident.data = task;
        node.children.add(ident);
        
        for (var arg in args) {
            var argNode = new ConfigNode(ConfigNodeType.String, []);
            argNode.data = arg;
            node.children.add(argNode);
        }
        
        execute(node);
    }

    /// Get a list of all the names of the tasks that aren't builtins
    List<String> getTaskNames() {
        List<String> names = [];
        funcs.forEach((name, value) {
            if (value.children.length > 0 && 
                value.children.last.type != ConfigNodeType.Builtin
            ) {
                names.add(name);
            }
        });
        return names;
    }

    /// Look up a global variable.
    String lookupGlobalVar(String name) {
        if (globalVars.containsKey(name)) {
            return globalVars[name];
        }
        return null;
    }

    // Look up a local variable.
    String lookupLocalVar(String name) {
        if (localVars.containsKey(name)) {
            return localVars[name];
        }
        return null;
    }

    /// Look up variable, either local or global.
    String lookupVar(String name) {
        String val = lookupGlobalVar(name);
        val ??= lookupLocalVar(name);
        return val;
    }

    /// Look up a function.
    ConfigNode lookupFunc(String name) {
        if (funcs.containsKey(name)) {
            return funcs[name];
        }
        return null;
    }    

    /// The main interpretation method.
    String execute(ConfigNode node) {
        switch (node.type) {
            case ConfigNodeType.Builtin:
                return builtin(node.data);

            case ConfigNodeType.Block:
                for (var child in node.children) {
                    execute(child);
                }
                break;

            case ConfigNodeType.Def:
                String name = node.children[0].data;
                if (lookupVar(name) == null && lookupFunc(name) == null) {
                    globalVars[name] = execute(node.children[1]);
                    return null;
                }
                throw 'Error: Variable ${name} has already been defined.';

            case ConfigNodeType.Assignment:
                String name = node.children[0].data;
                if (lookupGlobalVar(name) != null) {
                    globalVars[name] = execute(node.children[1]);
                    return null;
                }
                else if (lookupLocalVar(name) != null) {
                    localVars[name] = execute(node.children[1]);
                    return null;
                }
                throw 'Error: Variable ${name} is not defined.';

            case ConfigNodeType.Function:
                // Execute the block contained within the function:
                return execute(node.children.last);

            case ConfigNodeType.FunctionCall:
                String name = node.children[0].data;

                ConfigNode target = lookupFunc(name);
                if (target != null) {
                    
                    // Set up the arguments:
                    for (int i = 1; i < node.children.length; i++) {
                        String argName = target.children[i].data;
                        ConfigNode arg = node.children[i];

                        // If the arg is a variable, look up that variable 
                        if (arg.type == ConfigNodeType.Ident) {
                            localVars[argName] = lookupVar(arg.data);
                        } 
                        // Otherwise just use the result of the expression
                        else {
                            localVars[argName] = execute(arg);
                        }
                    }

                    // Execute the function
                    execute(target.children.last);

                    // Clear the function scope:
                    localVars = new Map<String, String>();

                    return null; 
                }
                throw 'Function ${name} is not defined.';

            case ConfigNodeType.Concat:
                String left = execute(node.children[0]);
                String right = execute(node.children[1]);
                if (node.children[0].type == ConfigNodeType.Ident) {
                    //@@CLEANUP
                    left = lookupVar(left);
                }
                if (node.children[1].type == ConfigNodeType.Ident) {
                    //@@CLEANUP
                    right = lookupVar(right);
                }
                return left + right;

            case ConfigNodeType.String:
                return node.data;

            case ConfigNodeType.Ident:
                if (lookupVar(node.data) != null || lookupFunc(node.data) != null) {
                    return node.data;
                }
                throw 'Error: Variable ${node.data} is not defined.';
        }
    }
    
    /// Execute a built-in function. Args are passed with names '@0', '@1' etc.,
    /// on the local variable scope
    String builtin(String name) {
        switch (name) {
            case 'print':
                print(lookupLocalVar('@0'));
                return null;
            case 'shell':
                shell(lookupLocalVar('@0'));
                return null;
            case 'copy':
                copy(lookupLocalVar('@0'), lookupLocalVar('@1'));
                return null;
            case 'delete':
                delete(lookupLocalVar('@0'));
                return null;
        }
        throw 'Error: Built-in function ${name} not found.';
    }

    void shell(String cmd) {

    }

    /// Copy a file or directory to another directory.
    void copy(String source, String dest) {
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
                String filename = element.path.split('/').last;
                String newPath = "${destDir.path}/${filename}";
                
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

            String filename = sourceFile.path.split('/').last;
            String newPath = "${destDir.path}/${filename}"; 

            sourceFile.copySync(newPath);           
        }
    }

    void delete(String path) {
        Directory obj = new Directory(path);
        if (obj.existsSync()) {
            obj.deleteSync(recursive: true);
        }
    }
}