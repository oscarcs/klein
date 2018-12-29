
enum ConfigNodeType {
    Program,        // Arbitrary list of nodes
    Def,            // Ident, rhs nodes
    Assignment,     // Ident, rhs nodes
    FunctionDef,    // Name, two arguments, list of statement nodes
    FunctionCall,   // Arbitrary argument nodes
    Concat,         // Two String/Ident nodes
    String,         // Leaf
    Ident,          // Leaf
    Builtin,        // Special node type for built-in functions
}

/// Abstract syntax tree node for the config file.
class ConfigNode {
    ConfigNodeType type;
    List<ConfigNode> children;
    String data = null;
    int args = 0;

    ConfigNode(ConfigNodeType type, List<ConfigNode> children) {
        this.type = type;
        this.children = children;
    }
}

/// A config file is just an AST of nodes to execute.
class Config {

    ConfigNode root;

    // Symbol tables.
    Map<String, String> vars;
    Map<String, List<ConfigNode>> funcs;
    //@@ENHANCEMENT: Stack of symbol tables for nested scopes.
    Map<String, String> localVars;

    Config(ConfigNode root) {
        this.root = root;

        // Set up the builtin vars:
        vars = {
            'version': ''
        };
        funcs = { };
        localVars = { };

        registerBuiltinFunc('print', 1);
        registerBuiltinFunc('copy', 2);
        registerBuiltinFunc('shell', 1);
    }

    /// Get a list of all the names of the tasks
    List<String> getTaskNames() {
        
    }

    /// Look up global variables
    String lookupVar(String name) {
        if (vars.containsKey(name)) {
            return vars[name];
        }
        return null;
    }

    // Look up local variables
    String lookupLocalVar(String name) {
        if (localVars.containsKey(name)) {
            return localVars[name];
        }
        return null;
    }

    //@@CLEANUP
    String lookupVarOrLocalVar(String name) {
        //@@OPTIMIZE
        return lookupVar(name) == null ? lookupLocalVar(name) : lookupVar(name);
    }

    /// Look up functions
    List<ConfigNode> lookupFunc(String name) {
        if (funcs.containsKey(name)) {
            return funcs[name];
        }
        return null;
    }    

    void registerBuiltinFunc(String name, int args) {
        ConfigNode execNode = new ConfigNode(ConfigNodeType.Builtin, []);
        execNode.data = name;
        funcs[name] = [];
        for (int i = 0; i < args; i++) {
            ConfigNode arg = new ConfigNode(ConfigNodeType.Ident, []);
            arg.data = '@' + i.toString();
            funcs[name].add(arg);
        }
        funcs[name].add(execNode);
    }

    /// The main interpretation method.
    String execute(ConfigNode node) {
        switch (node.type) {
            case ConfigNodeType.Builtin:
                builtin(node.data);
                return null;

            case ConfigNodeType.Program:
                for (var child in node.children) {
                    execute(child);
                }
                break;

            case ConfigNodeType.Def:
                String name = node.children[0].data;
                if (lookupVar(name) == null && lookupFunc(name) == null) {
                    vars[name] = execute(node.children[1]);
                    return null;
                }
                throw 'Error: Variable ${name} has already been defined.';

            case ConfigNodeType.Assignment:
                String name = node.children[0].data;
                if (lookupVar(name) != null) {
                    vars[name] = execute(node.children[1]);
                    return null;
                }
                else if (lookupLocalVar(name) != null) {
                    localVars[name] = execute(node.children[1]);
                    return null;
                }
                throw 'Error: Variable ${name} is not defined.';

            case ConfigNodeType.FunctionDef:
                String name = node.children[0].data;
                if (lookupFunc(name) == null) {
                    funcs[name] = node.children.sublist(1, node.children.length);
                    return null;
                }
                throw 'Error: Function ${name} is already defined.';

            case ConfigNodeType.FunctionCall:
                String name = node.children[0].data;
                List<ConfigNode> target = lookupFunc(name);
                
                if (target != null) {
                    
                    // Set up the arguments:
                    for (int i = 0; i < node.args; i++) {
                        String argName = target[i].data;
                        ConfigNode arg = node.children[i + 1];

                        // If the arg is a variable, look up that variable 
                        if (arg.type == ConfigNodeType.Ident) {
                            localVars[argName] = lookupVarOrLocalVar(arg.data);
                        } 
                        // Otherwise just use the result of the expression
                        else {
                            localVars[argName] = execute(arg);
                        }
                    }

                    //@@ENHANCEMENT: Change the function statements to a new 'Block' node type.
                    int numStatements = target.length - node.args;
                    for (int i = node.args; i < node.args + numStatements; i++) {
                        execute(target[i]);
                    }

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
                    left = lookupVarOrLocalVar(left);
                }
                if (node.children[1].type == ConfigNodeType.Ident) {
                    //@@CLEANUP
                    right = lookupVarOrLocalVar(right);
                }
                return left + right;

            case ConfigNodeType.String:
                return node.data;

            case ConfigNodeType.Ident:
                if (lookupLocalVar(node.data) != null ||
                    lookupVar(node.data) != null ||
                    lookupFunc(node.data) != null
                ) {
                    return node.data;
                }
                throw 'Error: Variable ${node.data} is not defined.';
        }
    }

    /// Execute statements in the top level.
    void run() {
        print('');
        
        execute(root);
    }

    // Execute a particular function as a task.
    void task(String task) {
        List<String> tasks = getTaskNames();
    }
    
    /// Execute a built-in function. Args are passed with names '0', '1' etc.
    /// on the local variable scope
    String builtin(String name) {
        switch (name) {
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