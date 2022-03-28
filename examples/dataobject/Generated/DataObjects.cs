// <auto-generated>
// This file has been autogenerated by Kari.
// </auto-generated>

#pragma warning disable

namespace DataObjectExample
{
    public partial class Properties
    {
        public static bool operator==(Properties a, Properties b)
        {
            if (a is null && b is null)
                return true;
            if (a is null || b is null)
                return false;
            return a.Spacing == b.Spacing
                && a.Radius == b.Radius
                && a.NeckWidth == b.NeckWidth
                && a.Area == b.Area;
        }
        public static bool operator!=(Properties a, Properties b)
        {
            return !(a == b);
        }
        public void Sync(Properties other)
        {
            this.Spacing = other.Spacing;
            this.Radius = other.Radius;
            this.NeckWidth = other.NeckWidth;
            this.Area = other.Area;
        }
        public override int GetHashCode()
        {
            unchecked
            {
                int hash = 17;
                hash = hash * 23 + Spacing.GetHashCode();
                hash = hash * 23 + Radius.GetHashCode();
                hash = hash * 23 + NeckWidth.GetHashCode();
                hash = hash * 23 + Area.GetHashCode();
                return hash;
            }
        }
        public override bool Equals(object other)
        {
            return other is Properties a && this == a;
        }
        public Properties Copy => (Properties) this.MemberwiseClone();
    }
}

#pragma warning restore