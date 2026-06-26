using System;

namespace DriftLands.Core
{
    public sealed class UpgradeDef
    {
        public string Id;
        public string Name;
        public string Desc;
        public int Max;
        public int BaseCost;
        public float Growth;
    }

    /// <summary>Souls-bought meta upgrades — C# port of the GDScript <c>Upgrades</c>.</summary>
    public static class Upgrades
    {
        public static readonly UpgradeDef[] Catalog =
        {
            new UpgradeDef { Id = "vigor", Name = "Vigor", Desc = "+15 Max HP", Max = 10, BaseCost = 40, Growth = 1.5f },
            new UpgradeDef { Id = "might", Name = "Might", Desc = "+2 Attack", Max = 10, BaseCost = 50, Growth = 1.5f },
            new UpgradeDef { Id = "guard", Name = "Guard", Desc = "+1 Defense", Max = 8, BaseCost = 45, Growth = 1.55f },
            new UpgradeDef { Id = "edge", Name = "Edge", Desc = "+2% Crit", Max = 8, BaseCost = 60, Growth = 1.6f },
            new UpgradeDef { Id = "swift", Name = "Swift", Desc = "+4 Move Speed", Max = 6, BaseCost = 55, Growth = 1.5f },
            new UpgradeDef { Id = "fortune", Name = "Fortune", Desc = "+1 Luck", Max = 6, BaseCost = 70, Growth = 1.7f },
        };

        public static UpgradeDef ById(string id)
        {
            foreach (var u in Catalog)
                if (u.Id == id)
                    return u;
            return null;
        }

        public static int Cost(string id, int level)
        {
            var u = ById(id);
            if (u == null || level >= u.Max)
                return -1;
            return (int)Math.Round(u.BaseCost * Math.Pow(u.Growth, level));
        }

        public static bool Purchase(MetaProgress meta, string id)
        {
            int level = meta.UpgradeLevel(id);
            int c = Cost(id, level);
            if (c < 0 || meta.Souls < c)
                return false;
            meta.Souls -= c;
            meta.SetUpgradeLevel(id, level + 1);
            return true;
        }

        public static Stats ApplyTo(Stats baseStats, MetaProgress meta)
        {
            var s = baseStats.Clone();
            s.MaxHp += 15f * meta.UpgradeLevel("vigor");
            s.Attack += 2f * meta.UpgradeLevel("might");
            s.Defense += 1f * meta.UpgradeLevel("guard");
            s.CritChance += 0.02f * meta.UpgradeLevel("edge");
            s.MoveSpeed += 4f * meta.UpgradeLevel("swift");
            s.Luck += 1f * meta.UpgradeLevel("fortune");
            return s;
        }
    }
}
