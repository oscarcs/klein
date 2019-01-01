import 'parser.dart';
import 'builtin.dart';

/// The Klein AST interpreter.
class Interpreter {

    String code;

    /// Symbol tables.
    //@@ENHANCEMENT: Stack of symbol tables for nested scopes with separate types.
    Map<String, String> localVars;
    Map<String, String> globalVars;
    Map<String, Node> funcs;

    Interpreter(String code) {
        this.code = code;
    }

    /// Execute statements in the top level.
    void interpret() {
        Parser parser = new Parser(code);
        parser.parse();

        //@@TODO: change this to be something cleaner.
        localVars = parser.localVars;
        globalVars = parser.globalVars;
        funcs = parser.funcs;

        execute(funcs['@root']);
    }

    /// Execute a particular function as a task.
    void task(String task, List<String> args) {
        var node = new Node(NodeType.FunctionCall, []);
        
        var ident = new Node(NodeType.Ident, []);
        ident.data = task;
        node.children.add(ident);
        
        for (var arg in args) {
            var argNode = new Node(NodeType.String, []);
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
                value.children.last.type != NodeType.Builtin
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
    Node lookupFunc(String name) {
        if (funcs.containsKey(name)) {
            return funcs[name];
        }
        return null;
    }    

    /// The main interpretation method.
    String execute(Node node) {
        switch (node.type) {
            case NodeType.Builtin:
                return builtin(node.data);

            case NodeType.Block:
                for (var child in node.children) {
                    execute(child);
                }
                break;

            case NodeType.Def:
                String name = node.children[0].data;
                if (lookupVar(name) == null && lookupFunc(name) == null) {
                    globalVars[name] = execute(node.children[1]);
                    return null;
                }
                throw 'Error: Variable ${name} has already been defined.';

            case NodeType.Assignment:
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

            case NodeType.Function:
                // Execute the block contained within the function:
                return execute(node.children.last);

            case NodeType.FunctionCall:
                String name = node.children[0].data;

                Node target = lookupFunc(name);
                if (target != null) {
                    
                    // Set up the arguments:
                    for (int i = 1; i < node.children.length; i++) {
                        String argName = target.children[i].data;
                        Node arg = node.children[i];

                        // If the arg is a variable, look up that variable 
                        if (arg.type == NodeType.Ident) {
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

            case NodeType.Concat:
                String left = execute(node.children[0]);
                String right = execute(node.children[1]);
                if (node.children[0].type == NodeType.Ident) {
                    //@@CLEANUP
                    left = lookupVar(left);
                }
                if (node.children[1].type == NodeType.Ident) {
                    //@@CLEANUP
                    right = lookupVar(right);
                }
                return left + right;

            case NodeType.String:
                return node.data;

            case NodeType.Ident:
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
                Builtin.shell(lookupLocalVar('@0'));
                return null;
            case 'copy':
                Builtin.copy(lookupLocalVar('@0'), lookupLocalVar('@1'));
                return null;
            case 'delete':
                Builtin.delete(lookupLocalVar('@0'));
                return null;
            case 'preprocess':
                Builtin.preprocess(lookupLocalVar('@0'), lookupLocalVar('@1'));
                return null;
        }
        throw 'Error: Built-in function ${name} not found.';
    }
}