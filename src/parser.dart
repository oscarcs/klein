import 'interpreter.dart';
import 'tokenizer.dart';
import 'symtab.dart';

enum NodeType {
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

/// Abstract syntax tree node for Klein code.
class Node {
    NodeType type;
    List<Node> children;
    String data = null;

    Node(NodeType type, List<Node> children) {
        this.type = type;
        this.children = children;
    }
}

/// Parses Klein code.
class Parser {
    
    /// The code to parse.
    String code = null;

    /// Tokens produced from the tokenization process.
    List<Token> tokens = null;
    int index = 0;
    Token get token {
        if (tokens != null && index < tokens.length && index >= 0) {
            return tokens[index];
        }
        throw 'Error: End of token stream exceeded.';
    }

    /// Symbol table
    SymTab symtab;

    Parser(String code) {
        this.code = code;

        // Set up the builtins:
        symtab = new SymTab();
        symtab
            ..registerBuiltinFunc('print', 1)
            ..registerBuiltinFunc('shell', 1)
            ..registerBuiltinFunc('copy', 2)
            ..registerBuiltinFunc('delete', 1)
            ..registerBuiltinFunc('preprocess', 2)
            ..registerBuiltinFunc('import', 1);
    }

    Node parse() {
        Tokenizer tokenizer = new Tokenizer(code);
        tokens = tokenizer.tokenize();
        
        // Parse the program!
        whitespace();
        Node root = program();

        return root;
    }

    void whitespace() {
        while (accept(TokenType.Newline)) { }
    }

    Node program() {
        List<Node> body = [];
        while (!accept(TokenType.End)) {
            var stmt = statement();
            if (stmt != null) {
                body.add(stmt);
            }
        }
        return new Node(NodeType.Block, body);
    }

    Node block() {
        List<Node> body = [];
        while (!accept(TokenType.RBrace)) {
            var stmt = statement();
            if (stmt != null) {
                body.add(stmt);
            }
        }
        return new Node(NodeType.Block, body);
    }

    Node statement() {
        Node node = null;

        var ident = token;
        Node lhs = new Node(NodeType.Ident, []);
        lhs.data = ident.reproduction;

        // Variable definition
        if (accept(TokenType.Def)) {
            // Change the identifier token
            ident = token;
            lhs.data = ident.reproduction;

            // Check that the identifier is not defined already:
            if (symtab.existsVar(lhs.data)) {
                throw 'The identifier ${ident.reproduction} has already been defined.';
            }

            // Add the identifier to the symbol table:
            symtab.globalVars[lhs.data] = null;

            expect(TokenType.Ident);
            expect(TokenType.Equals);

            Node rhs = expression();
            
            node = Node(NodeType.Def, [lhs, rhs]);
        }
        // Function definition
        else if (accept(TokenType.FunctionDef)) {
            // Change the identifier token
            ident = token;
            lhs.data = ident.reproduction;

            accept(TokenType.Ident);

            Node functionNode = functionDef();     
            functionNode.children.insert(0, lhs);
            symtab.funcs[lhs.data] = functionNode;
        }
        else if (accept(TokenType.Ident)) {
            // Assignment
            if (accept(TokenType.Equals)) {

                // Check that the identifier exists:
                if (!symtab.existsVar(ident.reproduction)) {
                    throw 'Can\'t assign to nonexistent variable ${ident.reproduction}.';
                }

                Node rhs = expression();
                node = Node(NodeType.Assignment, [lhs, rhs]);
            }
            // Function call
            else {
                node = functionCall();
                node.children.insert(0, lhs);
            }
        }
        else {
            node = expression();
        }
        
        expect(TokenType.Newline);
        return node;
    }

    Node functionDef() {
        expect(TokenType.LParen);

        List<Node> children = [];
        for (int i = 0; i < 10000; i++) {
            // Create the arg node:
            Node arg = new Node(NodeType.Ident, []);
            arg.data = token.reproduction;
            accept(TokenType.Ident);

            children.add(arg);

            // Add the argument name to the local scope:
            symtab.localVars[arg.data] = null;

            if (!accept(TokenType.Separator)) {
                break;
            }
        }

        expect(TokenType.RParen);
        expect(TokenType.LBrace);
        whitespace();

        // Parse the statements inside the function.
        Node body = block();
        children.add(body);
        
        // Pop the local scope:
        symtab.localVars = new Map<String, String>();

        // Create the function AST subtree:
        return new Node(NodeType.Function, children);
    }

    Node functionCall() {
        expect(TokenType.LParen);

        // Parse arguments
        List<Node> args = [];
        for (int i = 0; i < 10000; i++) {
            Node expr = expression();
            args.add(expr);

            if (!accept(TokenType.Separator)) {
                break;
            }
        }
        expect(TokenType.RParen);
        return new Node(NodeType.FunctionCall, args);
    }

    //@@ENHANCEMENT: use a better algorithm (something more generic?)
    /// Parse an expression
    Node expression() {
        Node root;
        NodeType type;

        for (int i = 0; i < 10000; i++) {
            Token value = token;
        
            if (accept(TokenType.Ident)) {
                type = NodeType.Ident;   
                
                // Check that the identifier is defined:
                if (!symtab.existsVar(value.reproduction)) {
                    throw 'Undefined identifier ${value.reproduction} in expression.';
                }        
            }
            else if (accept(TokenType.String)) {
                type = NodeType.String;                
            }
        
            Node leaf = new Node(type, []);
            leaf.data = value.reproduction;

            if (root == null) {
                root = leaf;
            } 
            else {
                root.children.add(leaf);
            }

            if (accept(TokenType.Concat)) {
                if (root == null) {
                    root = new Node(NodeType.Concat, [leaf]);
                }
                else {
                    root = new Node(NodeType.Concat, [root]);
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
