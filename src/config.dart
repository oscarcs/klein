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

    /// Get a list of all the names of the tasks
    List<String> getTaskNames() {
        
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

    /// Execute statements in the top level.
    void run() {
        execute(funcs['@root']);
    }

    // Execute a particular function as a task.
    void task(String task) {
        
    }
    
    /// Execute a built-in function. Args are passed with names '@0', '@1' etc.
    /// on the local variable scope
    String builtin(String name) {
        switch (name) {
            case 'print':
                print(lookupLocalVar('@0'));
                return null;
            case 'shell':
                //@@TODO: implement
                print('executing: ${lookupLocalVar('@0')}');
                return null;
            case 'copy':
                //@@TODO: implement
                print('copying ${lookupLocalVar('@0')} to ${lookupLocalVar('@1')}');
                return null;
        }
        throw 'Error: Built-in function ${name} not found.';
    }
}