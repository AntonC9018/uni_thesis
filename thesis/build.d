module thesis.build;

static import std.file; 

import std.process;
import std.stdio;

auto spawnProcess2(const(char[])[] args)
{
    writeln(escapeShellCommand(args));
    return std.process.spawnProcess(args);
}

int main()
{
    import std.process;
    if (spawnProcess2(["dmd", "-run", "get_links.d"]).wait != 0)
        return 1;
    
    return spawnProcess2(["latexmk", "--shell-escape", "-xelatex", "teza_processed.tex"]).wait;
}