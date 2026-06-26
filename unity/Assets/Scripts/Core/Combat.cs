using System;

namespace DriftLands.Core
{
    public struct DamageResult
    {
        public int Damage;
        public bool Crit;
    }

    /// <summary>
    /// Stateless damage resolution — C# port of the GDScript <c>Combat</c>.
    /// Defense uses diminishing returns, crits multiply, and a variance roll
    /// keeps hits from feeling robotic.
    /// </summary>
    public static class Combat
    {
        public const float DefenseSoftcap = 20f;
        public const float Variance = 0.1f;

        public static DamageResult Resolve(Stats attacker, Stats defender, Random rng, bool canCrit = true)
        {
            float reduction = defender.Defense / (defender.Defense + DefenseSoftcap);
            float dmg = attacker.Attack * (1f - reduction);
            bool crit = canCrit && rng.NextDouble() < attacker.CritChance;
            if (crit)
                dmg *= Math.Max(attacker.CritMult, 1f);
            dmg *= (float)(1.0 - Variance + rng.NextDouble() * 2.0 * Variance);
            return new DamageResult
            {
                Damage = Math.Max(1, (int)Math.Round(dmg)),
                Crit = crit,
            };
        }

        public static float Expected(Stats attacker, Stats defender)
        {
            float reduction = defender.Defense / (defender.Defense + DefenseSoftcap);
            return Math.Max(1f, attacker.Attack * (1f - reduction));
        }
    }
}
