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
    num pos = -1;
    String get token {
        
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

        tokens.forEach((t) => print(t.type));
        this.tokens = tokens;
    }

    Config parse() {
        tokenize();
        var config = new Config();
        return config;
    }

    bool accept(TokenType type) {
        
    }

    bool expect(TokenType token) {

    }
}
