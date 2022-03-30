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
    string filePath;
    int[2] range;
}

void main()
{
    auto f = std.file.readText("teza.tex");
    auto lines = f.splitter("\r\n").array;

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
    
    
    auto app = appender!string;

    const pathsToStart = [
        "Kari": "../Kari",
        "race": "../race",
        "uni_thesis": ".."   
    ];

    foreach (link; links)
    {
        const completedFilePath = pathsToStart[link.repo] ~ "/" ~ link.filePath;
        const filename = baseName(link.filePath);
        string labelString;
        string newLineContent;
        enum maxLineCountInline = 30;

        void appendLabel(string label)
        {
            app.formattedWrite!`\label{%s}`(label);
            app ~= "\n";
        }

        string friendlyFileName()
        {
            return stripExtension(completedFilePath).replace("\\", "_").replace("/", "_").replace(".", "_");
        }

        static string formatInputListing(string filePath, int startLine, int endLine)
        {
            return format!`\lstinputlisting[firstline=%d, lastline=%d]{%s}`(startLine, endLine, filePath);
        }

        // Entire file
        if (link.range[0] == -1)
        {
            formattedWrite!`\chapter{%s}`(app, filename);
            labelString = format!`appendix:%s_%s`(link.repo, friendlyFileName);
            newLineContent = format!`\ref{%s}`(labelString);
            
            appendLabel(labelString);

            formattedWrite!`\lstinputlisting{%s}`(app, completedFilePath);
            app ~= "\n";
            app ~= "\n";
        }
        // A single line
        else if (link.range[1] == -1)
        {
            newLineContent = formatInputListing(completedFilePath, link.range[0], link.range[0]);
            labelString = "";
        }
        // Multiple lines
        else
        {
            const rangeLength = link.range[1] - link.range[0] + 1;
            if (rangeLength > maxLineCountInline)
            {
                formattedWrite!`\chapter{%s, rândurile %d--%d}`(app, filename, link.range[0], link.range[1]);
                labelString = format!`appendix:%s_%s_%d_%d`(link.repo, friendlyFileName, link.range[0], link.range[1]);
                newLineContent = format!`\ref{%s}`(labelString);

                appendLabel(labelString);
                app ~= formatInputListing(completedFilePath, link.range[0], link.range[1]);
                app ~= "\n";
                app ~= "\n";
            }
            else
            {
                labelString = "";
                newLineContent = formatInputListing(completedFilePath, link.range[0], link.range[1]);
            }
        }
        
        lines[link.lineIndex] = newLineContent;
    }

    auto lastLine = lines[$ - 1];
    const prevLength = lines.length;
    auto toAdd = [
        `\appendix`,
        // `\begin{appendices}`,
        // `\chapter{Codul sursă menționat}`,
        app[],
        // `\end{appendices}`,
    ];
    lines.length += toAdd.length;
    lines[prevLength - 1 .. $ - 1] = toAdd[];
    lines[$ - 1] = lastLine;

    copy(lines.joiner("\n"), File("teza_processed.tex", "w").lockingTextWriter);
}