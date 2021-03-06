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
    auto lines = File("teza.tex").byLine.map!(a => a.stripRight.idup).array;

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
    
    bool hasAppendedSpacing = false;

    while (!links.empty)
    {
        auto link = links.front;
        links.popFront();

        const completedFilePath = pathsToStart[link.repo] ~ "/" ~ link.filePath;
        const filename = baseName(link.filePath);
        string newLineContent;
        enum maxLineCountInline = 30;

        void appendLabel(string label)
        {
            app.formattedWrite!`\label{%s}`(label);
        }

        string friendlyFileName()
        {
            return stripExtension(completedFilePath).replace("\\", "_").replace("/", "_").replace(".", "_");
        }

        static string getLanguageFromFileName(string filename)
        {
            string ext = extension(filename)[1 .. $];
            switch (ext)
            {
                // msbuild files
                case "props": return "xml";
                case "csproj": return "xml";

                // So that comments are allowed (jsonc is not supported)
                case "json": return "js";

                default: return ext;
            }
        }

        static string formatInputListing(string filePath, string fileName, int startLine, int endLine)
        {
            return format!`\inputminted[firstline=%d, lastline=%d]{%s}{%s}`(
                startLine, endLine, getLanguageFromFileName(fileName), filePath);
        }

        static string formatInputListing2(string filePath, string fileName)
        {
            return format!`\inputminted{%s}{%s}`(
                getLanguageFromFileName(fileName), filePath);
        }

        void doInlineFileRangeCase(int[2] range)
        {
            newLineContent = formatInputListing(completedFilePath, filename, range[0], range[1]);
        }

        string getRefLabel(string labelString)
        {
            return format!`A se vedea Anexa \ref{%s}.`(labelString);
        }

        void maybeAppendSpacing()
        {
            if (!hasAppendedSpacing)
            {
                hasAppendedSpacing = true;
                return;
            }
            app ~= "\n\n";
            app ~= `\clearpage`;
            // app ~= "\n\n";
        }

        // Entire file
        if (link.range[0] == -1)
        {
            const lineCountInThatFile = File(completedFilePath, "r").byLine.count;
            if (lineCountInThatFile <= maxLineCountInline)
            {
                newLineContent = formatInputListing2(completedFilePath, filename);
            }
            else
            {
                maybeAppendSpacing();

                formattedWrite!`\section{%s}`(app, filename);
                const labelString = format!`appendix:%s_%s`(link.repo, friendlyFileName);
                newLineContent = getRefLabel(labelString);
                
                appendLabel(labelString);
                app ~= "\n";
                app ~= formatInputListing2(completedFilePath, filename);
            }
        }

        // A single line
        else if (link.range[1] == -1)
        {
            doInlineFileRangeCase([link.range[0], link.range[0]]);
        }

        // Multiple lines
        else
        {
            const range = link.range;
            const rangeLength = range[1] - range[0] + 1;
            if (rangeLength <= maxLineCountInline)
            {
                doInlineFileRangeCase(range);
            }
            else
            {
                maybeAppendSpacing();

                formattedWrite!`\section{%s, rândurile %d--%d}`(app, filename, range[0], range[1]);
                const labelString = format!`appendix:%s_%s_%d_%d`(link.repo, friendlyFileName, range[0], range[1]);
                newLineContent = getRefLabel(labelString);
                
                appendLabel(labelString);
                app ~= "\n";
                app ~= formatInputListing(completedFilePath, filename, range[0], range[1]);
            }
        }
        
        lines[link.lineIndex] = newLineContent;
    }
    
    lines[lines.countUntil("% insert appendices here")] = app[];

    copy(lines.joiner("\n"), File("teza_processed.tex", "w").lockingTextWriter);
}