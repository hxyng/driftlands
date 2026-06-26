using System;

namespace DriftLands.Core
{
    /// <summary>XP and leveling — C# port of the GDScript <c>Progression</c>.</summary>
    public sealed class Progression
    {
        public int Level = 1;
        public int Xp;
        public int SkillPoints;

        /// <summary>XP required to advance FROM <paramref name="lvl"/> to lvl + 1.</summary>
        public static int XpForNext(int lvl)
        {
            int n = Math.Max(lvl - 1, 0);
            return 20 + (lvl - 1) * 18 + (int)Math.Pow(n, 2) * 4;
        }

        public int AddXp(int amount)
        {
            Xp += Math.Max(amount, 0);
            int gained = 0;
            while (Xp >= XpForNext(Level))
            {
                Xp -= XpForNext(Level);
                Level++;
                SkillPoints++;
                gained++;
            }
            return gained;
        }
    }
}
