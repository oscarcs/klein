import 'parser.dart';
import 'builtin.dart';
import 'symtab.dart';

/// The Klein AST interpreter.
class Interpreter {

    String file;
    SymTab symtab;

    Interpreter(String file) {
        this.file = file;
    }

    //@@CLEANUP: split into two methods or something
    /// Execute statements in the top level.
    String interpret({String code}) {
        if (code != null) {
            Parser parser = new Parser(code);
            parser.symtab = symtab;
            Node root = parser.parse();
            return execute(root);
        }
        else {
            Parser parser = new Parser(file);
            Node root = parser.parse();
            symtab = parser.symtab;
            return execute(root);
        }
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
        symtab.funcs.forEach((name, value) {
            if (value.children.length > 0 && 
                value.children.last.type != NodeType.Builtin
            ) {
                names.add(name);
            }
        });
        return names;
    }

    /// The main interpretation method.
    String execute(Node node) {
        switch (node.type) {
            case NodeType.Builtin:
                return builtin(node.data);

            case NodeType.Block:
                String result;
                for (var child in node.children) {
                    result = execute(child);
                }
                return result;

            case NodeType.Def:
                String name = node.children[0].data;
                if (symtab.lookupVar(name) == null && symtab.lookupFunc(name) == null) {
                    symtab.globalVars[name] = execute(node.children[1]);
                    return null;
                }
                throw 'Error: Variable ${name} has already been defined.';

            case NodeType.Assignment:
                String name = node.children[0].data;
                if (symtab.lookupGlobalVar(name) != null) {
                    symtab.globalVars[name] = execute(node.children[1]);
                    return null;
                }
                else if (symtab.lookupLocalVar(name) != null) {
                    symtab.localVars[name] = execute(node.children[1]);
                    return null;
                }
                throw 'Error: Variable ${name} is not defined.';

            case NodeType.Function:
                // Execute the block contained within the function:
                return execute(node.children.last);

            case NodeType.FunctionCall:
                String name = node.children[0].data;

                Node target = symtab.lookupFunc(name);
                if (target != null) {
                    
                    // Set up the arguments:
                    for (int i = 1; i < node.children.length; i++) {
                        String argName = target.children[i].data;
                        Node arg = node.children[i];

                        // If the arg is a variable, look up that variable 
                        if (arg.type == NodeType.Ident) {
                            symtab.localVars[argName] = symtab.lookupVar(arg.data);
                        } 
                        // Otherwise just use the result of the expression
                        else {
                            symtab.localVars[argName] = execute(arg);
                        }
                    }

                    // Execute the function
                    String result = execute(target.children.last);

                    // Clear the function scope:
                    symtab.localVars = new Map<String, String>();

                    return result;
                }
                throw 'Function ${name} is not defined.';

            case NodeType.Concat:
                String left = execute(node.children[0]);
                String right = execute(node.children[1]);
                if (node.children[0].type == NodeType.Ident) {
                    //@@CLEANUP
                    left = symtab.lookupVar(left);
                }
                if (node.children[1].type == NodeType.Ident) {
                    //@@CLEANUP
                    right = symtab.lookupVar(right);
                }
                return left + right;

            case NodeType.String:
                return node.data;

            case NodeType.Ident:
                if (symtab.lookupVar(node.data) != null || symtab.lookupFunc(node.data) != null) {
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
                print(symtab.lookupLocalVar('@0'));
                return null;
            case 'shell':
                Builtin.shell(symtab.lookupLocalVar('@0'));
                return null;
            case 'copy':
                Builtin.copy(symtab.lookupLocalVar('@0'), symtab.lookupLocalVar('@1'));
                return null;
            case 'delete':
                Builtin.delete(symtab.lookupLocalVar('@0'));
                return null;
            case 'preprocess':
                Builtin.preprocess(symtab.lookupLocalVar('@0'), symtab.lookupLocalVar('@1'));
                return null;
            case 'import':
                return Builtin.import(symtab.lookupLocalVar('@0'));
        }
        throw 'Error: Built-in function ${name} not found.';
    }
}