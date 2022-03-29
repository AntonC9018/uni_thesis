import std.regex;
static import std.file; 
import std.stdio;

void main()
{
    string f = std.file.readText("teza.tex");
    
    {
        const r = regex("`([^`]+)`");
        f = replaceAll(f, r, "texttt{$1}");
    }
    {
        const r = regex(`"[^"]+"`);
        f = replaceAll(f, r, "``$1''");
    }
    {
        const r = regex(`\*[^\*]+\*`);
        f = replaceAll(f, r, "emph{$1}");
    }
    writeln(f);
}