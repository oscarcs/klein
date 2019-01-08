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
    int lineNumber;

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

class Tokenizer {

    String code = null;
    int pos = 0;
    int line = 1;
    List<Token> tokens = [];

    Tokenizer(String code) {
        this.code = code;
    }

    bool isIdentChar(String s) {
        RegExp exp = new RegExp('[A-Za-z]');
        return (exp.hasMatch(s));
    }

    String get char {
        if (pos < code.length) {
            return code[pos];
        }
    }

    String get next {
        if (pos + 1 < code.length) {
            return code[pos + 1];
        }
    }

    Token get lastToken {
        if (tokens.length > 0) {
            return tokens.last;
        }
        return new Token(TokenType.End, '');
    }

    void advance() {
        pos++;
    }

    void addToken(Token t) {
        t.lineNumber = line;
        tokens.add(t);
    }

    List<Token> tokenize () { 
        while (pos < code.length) {
            // Skip whitespace:
            while (char == ' ' || char == '\t') {
                advance();
            }

            if (char == '#') {
                // Ignore comments.
                while (char != '\n') {
                    advance();
                }
                advance();
            }
            // DOS / Windows line endings
            else if (char == '\r') {
                if (next == '\n') {
                    advance();
                }

                if (lastToken.type != TokenType.Newline) {
                    addToken(new Token(TokenType.Newline, '\n'));
                }
                line++;
                advance();
            }
            // UNIX line endings
            else if (char == '\n') {
                if (lastToken.type != TokenType.Newline) {
                    addToken(new Token(TokenType.Newline, char));
                }
                line++;
                advance();
            }
            else if (char == '{') {
                addToken(new Token(TokenType.LBrace, char));
                advance();
            }
            else if (char == '}') {
                addToken(new Token(TokenType.RBrace, char));
                advance();
            }
            else if (char == '(') {
                addToken(new Token(TokenType.LParen, char));
                advance();
            }
            else if (char == ')') {
                addToken(new Token(TokenType.RParen, char));
                advance();
            }
            else if (char == '=') {
                addToken(new Token(TokenType.Equals, char));
                advance();
            }
            else if (char == '+') {
                addToken(new Token(TokenType.Concat, char));
                advance();
            }
            else if (char == ',') {
                addToken(new Token(TokenType.Separator, char));
                advance();
            }
            else if (isIdentChar(char)) {
                int startPos = pos;
                advance();
                while (pos < code.length && isIdentChar(char)) {
                    advance();
                }
                
                // Tokenize 
                String repr = code.substring(startPos, pos);
                if (repr == 'let') {
                    addToken(new Token(TokenType.Def, repr));
                }
                else if (repr == 'fn') {
                    addToken(new Token(TokenType.FunctionDef, repr));
                }
                else {
                    addToken(new Token(TokenType.Ident, repr));
                }
            }
            else if (char == '\'') {
                int startPos = pos;
                advance();
                while (pos < code.length && char != '\'') {
                    advance();
                }
                advance(); // increment past the end of the string 
                // Exclude the quote marks from the tokenized data:
                String repr = code.substring(startPos + 1, pos - 1);
                addToken(new Token(TokenType.String, repr));
            }
            else {
                throw "Unexpected character: ${char}";
            }
        }

        //@@HACK: for statement parsing
        if (tokens.last.type != TokenType.Newline) {
            addToken(new Token(TokenType.Newline, ''));
        }

        addToken(new Token(TokenType.End, ''));
        tokens.forEach((t) => print('${t.type}: ${t.lineNumber}'));
        return tokens;
    }
}