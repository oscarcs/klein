
enum ConfigNodeType {
    Program,        // Arbitrary list of nodes
    Def,            // Ident, rhs nodes
    Assignment,     // Ident, rhs nodes
    FunctionDef,    // Name, two arguments, list of statement nodes
    FunctionCall,   // Arbitrary argument nodes
    Concat,         // Two String/Ident nodes
    String,         // Leaf
    Ident,          // Leaf
}

/// Abstract syntax tree node for the config file.
class ConfigNode {
    ConfigNodeType type;
    List<ConfigNode> children;
    String data = "";

    ConfigNode(ConfigNodeType type, List<ConfigNode> children) {
        this.type = type;
        this.children = children;
    }
}

/// A config file is just an AST of nodes to execute.
class Config {

    ConfigNode root;

    Config(ConfigNode root) {
        this.root = root;
    }

    /// Get a list of all the names of the tasks
    List<String> getTaskNames() {
        // Walk the AST, gathering up all of the nodes that are 
        // function definitions.

    }

    void run(String task) {
        List<String> tasks = getTaskNames();
    }
}