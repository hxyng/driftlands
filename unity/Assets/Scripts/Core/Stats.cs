namespace DriftLands.Core
{
    /// <summary>
    /// The full stat block shared by every combatant — the C# port of the
    /// GDScript <c>Stats</c>. Final stats are assembled additively
    /// (base + meta upgrades + equipment + boons), so one flat, addable struct
    /// keeps composition trivial across both engines.
    /// </summary>
    public sealed class Stats
    {
        public float MaxHp;
        public float Attack;
        public float Defense;
        public float CritChance;   // 0..1
        public float CritMult;
        public float MoveSpeed;
        public float AttackSpeed;
        public float PickupRange;
        public float Luck;

        public static Stats Make(float hp, float atk, float def, float cc, float cm,
            float ms, float aspd, float pr, float lk)
        {
            return new Stats
            {
                MaxHp = hp, Attack = atk, Defense = def, CritChance = cc, CritMult = cm,
                MoveSpeed = ms, AttackSpeed = aspd, PickupRange = pr, Luck = lk,
            };
        }

        public static Stats PlayerBase()
        {
            return Make(100f, 12f, 2f, 0.08f, 1.6f, 80f, 1f, 30f, 0f);
        }

        public Stats Clone()
        {
            return Make(MaxHp, Attack, Defense, CritChance, CritMult,
                MoveSpeed, AttackSpeed, PickupRange, Luck);
        }

        /// <summary>Field-wise sum of this and <paramref name="o"/> (non-mutating).</summary>
        public Stats Add(Stats o)
        {
            var s = Clone();
            s.MaxHp += o.MaxHp;
            s.Attack += o.Attack;
            s.Defense += o.Defense;
            s.CritChance += o.CritChance;
            s.CritMult += o.CritMult;
            s.MoveSpeed += o.MoveSpeed;
            s.AttackSpeed += o.AttackSpeed;
            s.PickupRange += o.PickupRange;
            s.Luck += o.Luck;
            return s;
        }
    }
}
