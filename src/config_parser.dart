import 'config.dart';

enum TokenType {
    Newline,
    Def,
    Ident,
    Equals,
    String,
    Concat,
    LParen,
    RParen,
    Separator,
    LBrace,
    RBrace
}

class Token {
    TokenType type;
    String reproduction;

    Token(TokenType type, String reproduction) {
        this.type = type;
        this.reproduction = reproduction;
    }

    @override
    bool operator ==(dynamic other) {
        if (other is! Token) return false;
        Token t = other;
        return (t.type == type && t.reproduction == reproduction);
    }
}

/// Parses a config file.
class ConfigParser {
    
    String file = null;

    List<Token> tokens = null;
    num index = 0;
    Token get token {
        if (tokens != null && index < tokens.length) {
            return tokens[index];
        }
        return null;
    }

    ConfigParser(String file) {
        this.file = file;
    }

    bool isIdentChar(String s) {
        RegExp exp = new RegExp("[A-Za-z]");
        return (exp.hasMatch(s));
    }

    void tokenize() {
        List<Token> tokens = [];
        num pos = 0;
        while (pos < file.length) {
            // Skip whitespace:
            while (file[pos] == ' ' || file[pos] == '\t') {
                pos++;
            }

            if (file[pos] == '#') {
                // Ignore comments.
                while (file[pos] != '\n') {
                    pos++;
                }
                pos++;
            }
            else if (file[pos] == '\n' || file[pos] == '\r') {
                // Add a newline token into the stream:
                tokens.add(new Token(TokenType.Newline, "\n"));
                pos++;
                while (pos < file.length && (file[pos] == '\n' || file[pos] == '\r')) {
                    pos++;
                }
            }
            else if (file[pos] == '{') {
                tokens.add(new Token(TokenType.LBrace, '{'));
                pos++;
            }
            else if (file[pos] == '}') {
                tokens.add(new Token(TokenType.RBrace, '}'));
                pos++;
            }
            else if (file[pos] == '(') {
                tokens.add(new Token(TokenType.LParen, '('));
                pos++;
            }
            else if (file[pos] == ')') {
                tokens.add(new Token(TokenType.RParen, ')'));
                pos++;
            }
            else if (file[pos] == '=') {
                tokens.add(new Token(TokenType.Equals, '='));
                pos++;
            }
            else if (file[pos] == '+') {
                tokens.add(new Token(TokenType.Concat, '+'));
                pos++;
            }
            else if (file[pos] == ',') {
                tokens.add(new Token(TokenType.Separator, ','));
                pos++;
            }
            else if (isIdentChar(file[pos])) {
                num startPos = pos;
                pos++;
                while (pos < file.length && isIdentChar(file[pos])) {
                    pos++;
                }
                String repr = file.substring(startPos, pos);
                if (repr == 'def') {
                    tokens.add(new Token(TokenType.Def, repr));
                }
                else {
                    tokens.add(new Token(TokenType.Ident, repr));
                }
            }
            else if (file[pos] == '\'') {
                num startPos = pos;
                pos++;
                while (pos < file.length && file[pos] != '\'') {
                    pos++;
                }
                pos++; // increment past the end of the string 
                String repr = file.substring(startPos, pos);
                tokens.add(new Token(TokenType.String, repr));
            }
            else {
                print("Unexpected character: ${file[pos]}");
                break;
            }
        }

        // @@HACK: add an extra terminating newline.
        tokens.add(new Token(TokenType.Newline, '\n'));
        this.tokens = tokens;
    }

    void advance() {
        index++;
    }

    Config parse() {
        tokenize();
        var root = new ConfigNode(ConfigNodeType.Program, []);
        var config = new Config(root);
        
        List<ConfigNode> statements = [];
       
        whitespace();
        while (token != null) {
            statements.add(statement());
        }
        whitespace();
        
        root.children.addAll(statements);
        return config;
    }

    void whitespace() {
        while (accept(TokenType.Newline)) { }
    }

    ConfigNode statement() {
        var ident = token;
        ConfigNode node = null;

        // Local variable
        if (accept(TokenType.Def)) {
            ident = token;
            ConfigNode lhs = new ConfigNode(ConfigNodeType.Ident, []);
            lhs.data = ident.reproduction;

            expect(TokenType.Ident);
            expect(TokenType.Equals);
            ConfigNode rhs = expression();
            node = ConfigNode(ConfigNodeType.Def, [lhs, rhs]);
        }
        // Builtin, redefinition, or function
        else if (accept(TokenType.Ident)) {
            if (accept(TokenType.Equals)) {
                ConfigNode lhs = new ConfigNode(ConfigNodeType.Ident, []);
                lhs.data = ident.reproduction;

                ConfigNode rhs = expression();
                node = ConfigNode(ConfigNodeType.Assignment, [lhs, rhs]);
            }
            else {
                ConfigNode lhs = new ConfigNode(ConfigNodeType.Ident, []);
                lhs.data = ident.reproduction;
                node = func();
                node.children.insert(0, lhs);
            }
        }
        else {
            throw "Error: Expected a statement, got ${token.type} instead.";
        }
        expect(TokenType.Newline);
        return node;
    }

    ConfigNode expression() {
        ConfigNode root;
        ConfigNodeType type;

        for (int i = 0; i < 10000; i++) {
            Token value = token;
        
            if (accept(TokenType.Ident)) {
                type = ConfigNodeType.Ident;                
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

    ConfigNode func() {
        expect(TokenType.LParen);
        bool isCall = false;

        // Parse arguments
        List<ConfigNode> args = [];
        for (int i = 0; i < 10000; i++) {
            ConfigNode expr = expression();
            args.add(expr);
            
            // Allow syntax checking for function definitions by checking if
            // any of the arguments are expressions
            if (expr.type != ConfigNodeType.Ident) {
                isCall = true;
            }

            if (!accept(TokenType.Separator)) {
                break;
            }
        }
        accept(TokenType.RParen);
        
        // Function definition
        if (accept(TokenType.LBrace)) {
            whitespace();

            if (isCall) {
                throw "Arguments in function definitions must not be expressions.";
            }

            List<ConfigNode> statements = [];
            while (!accept(TokenType.RBrace)) {
                statements.add(statement());
            }
            args.addAll(statements);
            return new ConfigNode(ConfigNodeType.FunctionDef, args);
        }
        // Function call
        else {
            return new ConfigNode(ConfigNodeType.FunctionCall, args);
        }
    }

    bool accept(TokenType type) {
        if (token != null && token.type == type) {
            advance();
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
