enum TokenType {
    Newline,
    Def,
    FunctionDef,
    Ident,
    Equals,
    String,
    Concat,
    LParen,
    RParen,
    Separator,
    LBrace,
    RBrace,
    End
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

class ConfigTokenizer {

    String file = null;

    ConfigTokenizer(String file) {
        this.file = file;
    }

    bool isIdentChar(String s) {
        RegExp exp = new RegExp("[A-Za-z]");
        return (exp.hasMatch(s));
    }

    List<Token> tokenize () { 
        List<Token> tokens = [];
        int pos = 0;
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
                int startPos = pos;
                pos++;
                while (pos < file.length && isIdentChar(file[pos])) {
                    pos++;
                }
                
                // Tokenize 
                String repr = file.substring(startPos, pos);
                if (repr == 'let') {
                    tokens.add(new Token(TokenType.Def, repr));
                }
                else if (repr == 'fn') {
                    tokens.add(new Token(TokenType.FunctionDef, repr));
                }
                else {
                    tokens.add(new Token(TokenType.Ident, repr));
                }
            }
            else if (file[pos] == '\'') {
                int startPos = pos;
                pos++;
                while (pos < file.length && file[pos] != '\'') {
                    pos++;
                }
                pos++; // increment past the end of the string 
                // Exclude the quote marks from the tokenized data:
                String repr = file.substring(startPos + 1, pos - 1);
                tokens.add(new Token(TokenType.String, repr));
            }
            else {
                throw "Unexpected character: ${file[pos]}";
            }
        }

        //@@HACK: for statement parsing
        if (tokens.last.type != TokenType.Newline) {
            tokens.add(new Token(TokenType.Newline, ''));
        }

        tokens.add(new Token(TokenType.End, ''));
        return tokens;
    }
}