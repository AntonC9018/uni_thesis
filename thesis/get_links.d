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

auto findLinksThatBelongToRepo(Range)(Range links, string repo)
{
    static struct Thing
    {
        string path;
        int[2] range;
    }
    
    // return links
    //     .filter!((ref string a) => findSkip(a, repo)
    //         && findSkip(a, "blob/")
    //         && findSkip(a, "/"));
    return links
        .map!((a) => a.findSplit(repo)[2])
        .filter!(a => !a.empty)
        .map!((a) => a
            .findSplit("blob/")[2]
            // skips the hash
            .findSplit("/")[2])
        .map!((a)
        {
            int[2] range = -1;
            auto splitThing = a.findSplit("#");
            auto lineNumbersStart = splitThing[2];
            if (!lineNumbersStart.empty)
            {
                auto numbers = lineNumbersStart.splitter("-").map!(r => to!int(r.drop(1)));
                range[0] = numbers.front;
                numbers.popFront();
                if (!numbers.empty)
                    range[1] = numbers.front;
                else
                    range[1] = range[0];
            }
            return Thing(splitThing[0], range);
        });
}


string makeAppendixChapter(Range)(string targetRepo, string pathToRepoRoot, Range links)
{
    const appendixTemplate = "\\chapter{Codul sursă menționat al lui ``%s''}";
    auto paths = findLinksThatBelongToRepo(links, "AntonC9018/" ~ targetRepo);
    auto files = paths.save.map!(t => buildNormalizedPath(pathToRepoRoot, t.path)).uniq;
    
    auto app = appender!string;
    formattedWrite(app, appendixTemplate, targetRepo);
    app ~= "\n";

    foreach (f; files)
    {
        formattedWrite!`\lstinputlisting{%s}`(app, f);
        app ~= "\n";
    }

    return app[];
}


void main()
{
    auto f = std.file.readText("teza_processed.tex");

    auto links = f.splitter("\n").map!(s => s.strip).filter!(s => s.startsWith("http"));

    writeln(links.joiner("\n"));

    writeln(makeAppendixChapter("Kari", "../Kari", links));
    writeln(makeAppendixChapter("race", "../race", links));
    writeln(makeAppendixChapter("uni_thesis", "..", links));

    // auto r = regex("AntonC9018/([^/]+)/");
    // links.map!((a) => std.regex.matchFirst(a, r)).tee!writeln.array;
}