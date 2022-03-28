using System.Diagnostics;
using Kari.Plugins.DataObject;

namespace DataObjectExample;

[DataObject]
public partial class Properties
{
    public float Spacing = 0.05f;
    public ushort Radius = 3;
    public ushort NeckWidth = 1;
    public double Area = 100.0;
}

public static class Program
{
    public static void Main(string[] args)
    {
        var a = new Properties();
        var b = new Properties();

        Debug.Assert(a == b);

        a.NeckWidth += 5;
        Debug.Assert(a != b);

        a.Sync(b);
        Debug.Assert(a == b);

        var c = b.Copy;
        Debug.Assert(c == b);

        b.Area -= 10;
        Debug.Assert(c != b);

        Console.WriteLine(a.GetHashCode());
    }
}