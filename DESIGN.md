# Design Document

*Web development, the 'hard way'.*

Today, many websites are written as single-page applications, which use client-side Javascript to control the display of the page. This means that a single HTML 'document' is loaded, containing the required HTML components for the application. Frequently, the Javascript required by the application is also bundled together. 

To facilitate this pattern, a number of tools have arisen that the developer of a single page application can use during development.

- Package managers, such as NPM.
- 'Module bundlers', programs that take modules of code with dependencies and create static assets for the web containing the right assets, such as Webpack.
- Transpilers to convert 'modern' Javascript code to code that browsers can actually understand, such as Babel.
- Virtual machines, to run the above tools (which are invariably written in Javascript), such as Node.js.
- Various libraries to run 'tasks', including Grunt, Gulp, Bower, NPM,  

As you might expect, there's been a bit of a pushback against the sheer quantity of tooling involved in building simple web pages. **Web tooling today mostly doesn't provide a good experience.** It's too complex to keep a model of what's happening in your head, which means when things go wrong you have no simple way to fix it.

By making a few simplifying assumptions, we can obviate the need for most of these tools.

- **No package management.** There are lots of good reasons for not using package management, including security, dependency hell, and build reproducibility. If you work for a bank, do you really want your users to be running all sorts of untrusted, unaudited JS modules on their systems every time they go to check their balance?

- **No Node.js.** Who would write a [compiler in Javascript](https://github.com/oscarcs/bplus) anyway? 

- **Specific needs.** Web developers have different needs for their projects. Mostly, those needs are actually pretty minimal, because **the hard part of web development is capturing and fulfilling specific business and usability requirements** (i.e. engineering).

## Why does this tool exist?

- There are a number of good existing standalone tools that provide 95% of the functionality needed to build modern single 
- These tools are not linked together and easy to use.
- We want to solve these web development problems, in roughly this order: HTML compilation / templating / preprocessing; CSS preprocessing; 

## What does the tool do?

- Ties together code to perform the functions listed above in a transparent, flexible, and *minimal* way.
- Agnostic single page app framework integration. However, Vue will be the primary target because it can be integrated most easily without build tools.
- Some kind of HTML preprocessing, so that the user can develop their modules in separate files and then they can be cleanly bundled into a file for deployment.
- Integration with a Javascript optimization tool. The Google Closure Compiler is a strong candidate. The software should be able to retrieve the Closure Compiler from the internet and set it up.
- Integration with a CSS preprocessor. Plain CSS is bad for anything except the smallest projects. Sass runs on Dart -- a good option to reduce the number of dependencies this software has.
- An easy way to define an interface to the backend. This will probably involve some sort of templating for REST endpoints.

Stretch goals:

- 'Watch' behaviour (so the software can just run continuously). 

### Initialization

```
klein init vue
```
Creates a default set of HTML, CSS, JS, and config files.

### HTML Templating

```html
<html>
    <body>
        @@import(components + '/button-template')
    </body>
</html>
```
```html
<html>
    <body>
        @@import-all(components)
    </body>
</html>
```

### Build language
```
# This is a comment.

# This is a local variable.
def src = '.'
def dest = src + '/build'

# This is a builtin.
version = '0.0.1'

# This is a (builtin) method call.
copy(src, dest)
shell('ls ' + src)

# This is a custom method. 
# This can be called as a task from the command line.
doWork(x, y) {
    copy(x + '/src', y)
}
```

## What does the name mean?

It's German for 'small'.