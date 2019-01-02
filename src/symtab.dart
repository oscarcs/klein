import 'parser.dart';

/// Class to represent a symbol table.
class SymTab {
    //@@ENHANCEMENT: Stack of symbol tables for nested scopes.
    Map<String, String> localVars;
    Map<String, String> globalVars;
    Map<String, Node> funcs;
    Node root;

    SymTab() {
        globalVars = {
            'version': ''
        };
        funcs = { };
        localVars = { };
    }

    @override
    SymTab operator +(SymTab other) {
        localVars.addAll(other.localVars);
        globalVars.addAll(other.globalVars);
        funcs.addAll(other.funcs);
        return this;
    }

    /// Create a built-in function with a given name and number of arguments.
    void registerBuiltinFunc(String name, int args) {
        if (!existsFunc(name)) {  
            List<Node> children = [];  
            
            Node identNode = new Node(NodeType.Ident, []);
            identNode.data = name;
            children.add(identNode);

            for (int i = 0; i < args; i++) {
                Node arg = new Node(NodeType.Ident, []);
                arg.data = '@' + i.toString();
                children.add(arg);
            }

            Node execNode = new Node(NodeType.Builtin, []);
            execNode.data = name;
            children.add(execNode);

            funcs[name] = new Node(NodeType.Function, children);
            return;
        }
        throw 'A function with the name ${name} is already registered!';
    }

    /// Check a global variable exists.
    bool existsGlobalVar(String name) {
        return globalVars.containsKey(name);
    }

    // Check a local variable exists.
    bool existsLocalVar(String name) {
        return localVars.containsKey(name);
    }

    /// Check a local or global variable exists.
    bool existsVar(String name) {
        return existsGlobalVar(name) || existsLocalVar(name);
    }

    /// Check that a certain function exists.
    bool existsFunc(String name) {
        return funcs.containsKey(name);
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
}