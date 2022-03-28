using System.Diagnostics;
using Kari.Plugins.Flags;
using Root.Generated;

namespace FlagsExample;

[NiceFlags]
public enum Flags
{
    Shy = 1 << 0,
    Brave = 1 << 1,
    Strong = 1 << 2,
    Beautiful = 1 << 3,
}

public static class Program
{
    public static void Main(string[] args)
    {
        Flags flags = Flags.Shy | Flags.Brave;

        // Check if it has the Shy flag
        Debug.Assert(flags.Has(Flags.Shy));

        // Check if it has both the Shy and the Brave flags
        Debug.Assert(flags.Has(Flags.Shy | Flags.Brave));

        // Check it's neither Strong nor Beautiful
        Debug.Assert(flags.DoesNotHaveEither(Flags.Strong | Flags.Beautiful));

        // Clear the Shy flag
        flags.Unset(Flags.Shy);

        // Conditionally set/unset the Beautiful flag
        flags.Set(Flags.Beautiful, true);
    }
}