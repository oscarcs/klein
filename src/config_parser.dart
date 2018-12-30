import 'config.dart';
import 'config_tokenizer.dart';

enum ConfigNodeType {
    Block,          // Arbitrary list of nodes
    Def,            // Ident, rhs nodes
    Assignment,     // Ident, rhs nodes
    Function,       // Ident, args, block
    FunctionCall,   // Ident, args
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

    ConfigNode(ConfigNodeType type, List<ConfigNode> children) {
        this.type = type;
        this.children = children;
    }
}

/// Parses a config file.
class ConfigParser {
    
    /// The file to parse.
    String file = null;

    /// Tokens produced from the tokenization process.
    List<Token> tokens = null;
    int index = 0;
    Token get token {
        if (tokens != null && index < tokens.length && index >= 0) {
            return tokens[index];
        }
        throw 'Error: End of token stream exceeded.';
    }

    /// Symbol tables.
    //@@ENHANCEMENT: Stack of symbol tables for nested scopes.
    Map<String, String> localVars;
    Map<String, String> globalVars;
    Map<String, ConfigNode> funcs;

    ConfigParser(String file) {
        this.file = file;

        // Set up the builtins:
        globalVars = {
            'version': ''
        };
        funcs = { };
        localVars = { };
        registerBuiltinFunc('print', 1);
        registerBuiltinFunc('shell', 1);
        registerBuiltinFunc('copy', 2);
        registerBuiltinFunc('delete', 1);
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

    /// Create a built-in function with a given name and number of arguments.
    void registerBuiltinFunc(String name, int args) {
        if (!existsFunc(name)) {  
            List<ConfigNode> children = [];  
            
            ConfigNode identNode = new ConfigNode(ConfigNodeType.Ident, []);
            identNode.data = name;
            children.add(identNode);

            for (int i = 0; i < args; i++) {
                ConfigNode arg = new ConfigNode(ConfigNodeType.Ident, []);
                arg.data = '@' + i.toString();
                children.add(arg);
            }

            ConfigNode execNode = new ConfigNode(ConfigNodeType.Builtin, []);
            execNode.data = name;
            children.add(execNode);

            funcs[name] = new ConfigNode(ConfigNodeType.Function, children);
            return;
        }
        throw 'A function with the name ${name} is already registered!';
    }

    Config parse() {
        ConfigTokenizer tokenizer = new ConfigTokenizer(file);
        tokens = tokenizer.tokenize();
        
        // Parse the program!
        whitespace();
        funcs['@root'] = program();

        var config = new Config();
        config.localVars = localVars;
        config.globalVars = globalVars;
        config.funcs = funcs;
        return config;
    }

    void whitespace() {
        while (accept(TokenType.Newline)) { }
    }

    ConfigNode program() {
        List<ConfigNode> body = [];
        while (!accept(TokenType.End)) {
            var stmt = statement();
            if (stmt != null) {
                body.add(stmt);
            }
        }
        return new ConfigNode(ConfigNodeType.Block, body);
    }

    ConfigNode block() {
        List<ConfigNode> body = [];
        while (!accept(TokenType.RBrace)) {
            var stmt = statement();
            if (stmt != null) {
                body.add(stmt);
            }
        }
        return new ConfigNode(ConfigNodeType.Block, body);
    }

    ConfigNode statement() {
        ConfigNode node = null;

        var ident = token;
        ConfigNode lhs = new ConfigNode(ConfigNodeType.Ident, []);
        lhs.data = ident.reproduction;

        // Variable definition
        if (accept(TokenType.Def)) {
            // Change the identifier token
            ident = token;
            lhs.data = ident.reproduction;

            // Check that the identifier is not defined already:
            if (existsVar(lhs.data)) {
                throw 'The identifier ${ident.reproduction} has already been defined.';
            }

            // Add the identifier to the symbol table:
            globalVars[lhs.data] = null;

            expect(TokenType.Ident);
            expect(TokenType.Equals);

            ConfigNode rhs = expression();
            
            node = ConfigNode(ConfigNodeType.Def, [lhs, rhs]);
        }
        // Function definition
        else if (accept(TokenType.FunctionDef)) {
            // Change the identifier token
            ident = token;
            lhs.data = ident.reproduction;

            accept(TokenType.Ident);

            ConfigNode functionNode = functionDef();     
            functionNode.children.insert(0, lhs);
            funcs[lhs.data] = functionNode;
        }
        else if (accept(TokenType.Ident)) {
            // Assignment
            if (accept(TokenType.Equals)) {

                // Check that the identifier exists:
                if (!existsVar(ident.reproduction)) {
                    throw 'Can\'t assign to nonexistent variable ${ident.reproduction}.';
                }

                ConfigNode rhs = expression();
                node = ConfigNode(ConfigNodeType.Assignment, [lhs, rhs]);
            }
            // Function call
            else {
                node = functionCall();
                node.children.insert(0, lhs);
            }
        }
        else {
            throw "Error: Expected a statement, got ${token.type} instead.";
        }
        expect(TokenType.Newline);
        return node;
    }

    ConfigNode functionDef() {
        expect(TokenType.LParen);

        List<ConfigNode> children = [];
        for (int i = 0; i < 10000; i++) {
            // Create the arg node:
            ConfigNode arg = new ConfigNode(ConfigNodeType.Ident, []);
            arg.data = token.reproduction;
            accept(TokenType.Ident);

            children.add(arg);

            // Add the argument name to the local scope:
            localVars[arg.data] = null;

            if (!accept(TokenType.Separator)) {
                break;
            }
        }

        expect(TokenType.RParen);
        expect(TokenType.LBrace);
        whitespace();

        // Parse the statements inside the function.
        ConfigNode body = block();
        children.add(body);
        
        // Pop the local scope:
        localVars = new Map<String, String>();

        // Create the function AST subtree:
        return new ConfigNode(ConfigNodeType.Function, children);
    }

    ConfigNode functionCall() {
        expect(TokenType.LParen);

        // Parse arguments
        List<ConfigNode> args = [];
        for (int i = 0; i < 10000; i++) {
            ConfigNode expr = expression();
            args.add(expr);

            if (!accept(TokenType.Separator)) {
                break;
            }
        }
        expect(TokenType.RParen);
        return new ConfigNode(ConfigNodeType.FunctionCall, args);
    }

    //@@ENHANCEMENT: use a better algorithm (something more generic?)
    /// Parse an expression
    ConfigNode expression() {
        ConfigNode root;
        ConfigNodeType type;

        for (int i = 0; i < 10000; i++) {
            Token value = token;
        
            if (accept(TokenType.Ident)) {
                type = ConfigNodeType.Ident;   
                
                // Check that the identifier is defined:
                if (!existsVar(value.reproduction)) {
                    throw 'Undefined identifier ${value.reproduction} in expression.';
                }        
            }
            else if (accept(TokenType.String)) {
                type = ConfigNodeType.String;                
            }
        
            ConfigNode leaf = new ConfigNode(type, []);
            leaf.data = value.reproduction;

            if (root == null) {
                root = leaf;
            } 
            else {
                root.children.add(leaf);
            }

            if (accept(TokenType.Concat)) {
                if (root == null) {
                    root = new ConfigNode(ConfigNodeType.Concat, [leaf]);
                }
                else {
                    root = new ConfigNode(ConfigNodeType.Concat, [root]);
                }
            }
            else {
                break;
            }
        }
        return root;
    }

    bool accept(TokenType type) {
        if (token != null && token.type == type) {
            index++;
            return true;
        }
        return false;
    }

    bool expect(TokenType type) {
        if (accept(type)) {
            return true;
        }
        if (token == null) {
            throw "Error: Token is null.";
        }
        throw "Error: expected token $type but got ${token.type}";
    }
}
