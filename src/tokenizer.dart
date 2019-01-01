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

class Tokenizer {

    String code = null;

    Tokenizer(String code) {
        this.code = code;
    }

    bool isIdentChar(String s) {
        RegExp exp = new RegExp("[A-Za-z]");
        return (exp.hasMatch(s));
    }

    List<Token> tokenize () { 
        List<Token> tokens = [];
        int pos = 0;
        while (pos < code.length) {
            // Skip whitespace:
            while (code[pos] == ' ' || code[pos] == '\t') {
                pos++;
            }

            if (code[pos] == '#') {
                // Ignore comments.
                while (code[pos] != '\n') {
                    pos++;
                }
                pos++;
            }
            else if (code[pos] == '\n' || code[pos] == '\r') {
                // Add a newline token into the stream:
                tokens.add(new Token(TokenType.Newline, "\n"));
                pos++;
                while (pos < code.length && (code[pos] == '\n' || code[pos] == '\r')) {
                    pos++;
                }
            }
            else if (code[pos] == '{') {
                tokens.add(new Token(TokenType.LBrace, '{'));
                pos++;
            }
            else if (code[pos] == '}') {
                tokens.add(new Token(TokenType.RBrace, '}'));
                pos++;
            }
            else if (code[pos] == '(') {
                tokens.add(new Token(TokenType.LParen, '('));
                pos++;
            }
            else if (code[pos] == ')') {
                tokens.add(new Token(TokenType.RParen, ')'));
                pos++;
            }
            else if (code[pos] == '=') {
                tokens.add(new Token(TokenType.Equals, '='));
                pos++;
            }
            else if (code[pos] == '+') {
                tokens.add(new Token(TokenType.Concat, '+'));
                pos++;
            }
            else if (code[pos] == ',') {
                tokens.add(new Token(TokenType.Separator, ','));
                pos++;
            }
            else if (isIdentChar(code[pos])) {
                int startPos = pos;
                pos++;
                while (pos < code.length && isIdentChar(code[pos])) {
                    pos++;
                }
                
                // Tokenize 
                String repr = code.substring(startPos, pos);
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
            else if (code[pos] == '\'') {
                int startPos = pos;
                pos++;
                while (pos < code.length && code[pos] != '\'') {
                    pos++;
                }
                pos++; // increment past the end of the string 
                // Exclude the quote marks from the tokenized data:
                String repr = code.substring(startPos + 1, pos - 1);
                tokens.add(new Token(TokenType.String, repr));
            }
            else {
                throw "Unexpected character: ${code[pos]}";
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