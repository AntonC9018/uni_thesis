module thesis.get_links;

import std.stdio;
static import std.file;
import std.string;
import std.algorithm;
import std.array;
import std.range;
import std.conv;
import std.regex;
import std.path;
import std.format;
import std.typecons;


string makeAppendixChapter(Range)(string targetRepo, string pathToRepoRoot, Range links)
{
    static struct Result
    {
        string chapterContent;
        string[] paths;
        string[] labels;
    }

    const appendixTemplate = "\\chapter{Codul sursă menționat al lui ``%s''}";
    auto paths = findLinksThatBelongToRepo(links, "AntonC9018/" ~ targetRepo);
    // auto files = paths.save.map!(t => buildNormalizedPath(pathToRepoRoot, t.path)).uniq;
    
    auto app = appender!string;
    formattedWrite(app, appendixTemplate, targetRepo);
    app ~= "\n";

    auto labels = appender!(string[]);

    foreach (p; paths)
    {
        const filename = baseName(p.path);
        string label;
        if (p.range[0] == -1)
        {
            formattedWrite!`\section{%s}`(app, filename);
            label = format!`\label{%s_%s}`(targetRepo, stripExtension(filename));
            
        }
        else
        {
            formattedWrite!`\section{%s, rândurile %d-%d}`(app, filename, p.range[0], p.range[1]);
            label = format!`\label{%s_%s_%d_%d}`(targetRepo, stripExtension(filename), p.range[0], p.range[1]);
        }
        
        app ~= "\n";
        app ~= label;
        labels ~= label;

        formattedWrite!`\lstinputlisting{%s}`(app, f);
        app ~= "\n";
    }

    return app[];
}

static struct Link
{
    int lineIndex;
    string repo;
    string path;
    int[2] range;
}

void main()
{
    auto f = std.file.readText("teza.tex");
    auto lines = f.split("\n");

    // http...AntonC9018/RepoName/blob/hashstring/file/path.ext[#lineFrom-lineTo]
    auto linkRegex = regex(`https://github.com/[^/]+/([^/]+)/blob/[^/]+/([^\#^\}]+)(\#[^\}]+)?`);
    auto links = lines
        .map!(s => s.strip)
        .enumerate
        
        // index, string -> index, match
        .map!(t => tuple(t[0], matchFirst(t[1], linkRegex)))

        // take those that matched
        .filter!(m => !m[1].empty)
        
        .map!((t)
        {
            auto match = t[1];
            string repoName = match[1];
            string filePath = match[2];

            int[2] range = -1;
            // The line numbers 

            if (match[3])
            (){
                // #(things)
                auto linesString = match[3][1..$];
                auto lines = linesString.splitter("-");
                if (lines.empty)
                    return;

                // L123
                range[0] = lines.front[1..$].to!int;
                lines.popFront();
                
                if (lines.empty)
                    return;

                range[1] = lines.front[1..$].to!int;
            }();

            int index = cast(int) t[0];

            return Link(index, repoName, filePath, range);
        });
    

    writeln(links.map!(a => a.to!string).joiner("\n"));

    // writeln(makeAppendixChapter("Kari", "../Kari", links));
    // writeln(makeAppendixChapter("race", "../race", links));
    // writeln(makeAppendixChapter("uni_thesis", "..", links));

    // auto r = regex("AntonC9018/([^/]+)/");
    // links.map!((a) => std.regex.matchFirst(a, r)).tee!writeln.array;
}