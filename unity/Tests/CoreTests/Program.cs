using System;
using DriftLands.Core;

namespace DriftLands.CoreTests
{
    /// <summary>
    /// Console parity harness for DriftLands.Core. The deterministic results
    /// (xp curve, defense softcap, upgrade costs, daily streak, equipment sums)
    /// must equal the Godot/GDScript values exactly — proving the two engines
    /// share one design. Exit code gates CI.
    /// </summary>
    internal static class Program
    {
        private static int _passed;
        private static int _failed;

        private static int Main()
        {
            Console.WriteLine("DriftLands.Core parity tests...");
            TestStats();
            TestCombat();
            TestProgression();
            TestEquipment();
            TestLoot();
            TestDaily();
            TestUpgrades();
            Console.WriteLine($"=== {_passed} passed, {_failed} failed ===");
            return _failed > 0 ? 1 : 0;
        }

        private static void Check(bool cond, string label)
        {
            if (cond) _passed++;
            else { _failed++; Console.Error.WriteLine("  FAIL  " + label); }
        }

        private static float ModTotal(Stats s)
        {
            return Math.Abs(s.MaxHp) + Math.Abs(s.Attack) + Math.Abs(s.Defense)
                + Math.Abs(s.CritChance) * 100f + Math.Abs(s.AttackSpeed) * 50f
                + Math.Abs(s.MoveSpeed) + Math.Abs(s.PickupRange) + Math.Abs(s.Luck) * 5f;
        }

        private static void TestStats()
        {
            var a = Stats.Make(100, 10, 2, 0.1f, 1.5f, 80, 1, 30, 0);
            var b = Stats.Make(20, 5, 1, 0.05f, 0, 0, 0.1f, 0, 1);
            var c = a.Add(b);
            Check(c.MaxHp == 120 && c.Attack == 15 && c.Defense == 3, "stats add field-wise");
            Check(a.MaxHp == 100 && a.Attack == 10, "add does not mutate operands");
            var d = a.Clone();
            d.Attack = 99;
            Check(a.Attack == 10, "clone is independent");
        }

        private static void TestCombat()
        {
            var atk = Stats.Make(0, 50, 0, 0, 1.5f, 0, 0, 0, 0);
            var def = Stats.Make(0, 0, 20, 0, 0, 0, 0, 0, 0);
            Check(Math.Abs(Combat.Expected(atk, def) - 25.0) < 0.001, "defense softcap halves dmg at def=20");
            var r = Combat.Resolve(atk, def, new Random(1), false);
            Check(r.Damage >= 1, "damage at least 1");
            Check(!r.Crit, "no crit at 0% chance");
        }

        private static void TestProgression()
        {
            Check(Progression.XpForNext(1) == 20, "first level needs 20 xp");
            var p = new Progression();
            int gained = p.AddXp(20);
            Check(gained == 1 && p.Level == 2 && p.SkillPoints == 1, "level up grants a skill point");
            var p2 = new Progression();
            int g = p2.AddXp(10000);
            Check(p2.Level > 5 && g == p2.Level - 1, "big xp grants multiple levels");
            Check(p2.Xp < Progression.XpForNext(p2.Level), "leftover xp below threshold");
        }

        private static void TestEquipment()
        {
            var eq = new Equipment();
            var w = new Item { Slot = Slot.Weapon, Mods = Stats.Make(0, 10, 0, 0, 0, 0, 0, 0, 0) };
            var armor = new Item { Slot = Slot.Armor, Mods = Stats.Make(50, 0, 5, 0, 0, 0, 0, 0, 0) };
            eq.Equip(w);
            eq.Equip(armor);
            var tm = eq.TotalMods();
            Check(tm.Attack == 10 && tm.MaxHp == 50 && tm.Defense == 5, "equipment sums modifiers");
            var w2 = new Item { Slot = Slot.Weapon, Mods = Stats.Make(0, 20, 0, 0, 0, 0, 0, 0, 0) };
            var prev = eq.Equip(w2);
            Check(prev == w, "equipping a slot returns the replaced item");
            Check(eq.TotalMods().Attack == 20, "replacement updates the total");
        }

        private static void TestLoot()
        {
            var rng = new Random(42);
            var low = LootTable.Roll(rng, 1, 0);
            Check(low.Mods != null, "rolled item has modifiers");
            Check(Array.IndexOf(LootTable.Rarities, low.Rarity) >= 0, "rarity is valid");
            double sumLow = 0, sumHigh = 0;
            for (int i = 0; i < 200; i++)
            {
                sumLow += ModTotal(LootTable.Roll(rng, 1, 0).Mods);
                sumHigh += ModTotal(LootTable.Roll(rng, 20, 3).Mods);
            }
            Check(sumHigh > sumLow * 1.5, "deeper floors + luck yield stronger loot");
        }

        private static void TestDaily()
        {
            var m = new MetaProgress();
            var r1 = Daily.Claim(m, "2026-06-25");
            Check(r1.Claimed && m.DailyStreak == 1 && m.Souls == 35, "first claim pays base + streak");
            Check(!Daily.Claim(m, "2026-06-25").Claimed, "cannot claim twice in one day");
            var r2 = Daily.Claim(m, "2026-06-26");
            Check(r2.Claimed && m.DailyStreak == 2, "consecutive day grows streak");
            var r3 = Daily.Claim(m, "2026-06-29");
            Check(r3.Claimed && m.DailyStreak == 1, "missed day resets streak");
        }

        private static void TestUpgrades()
        {
            Check(Upgrades.Cost("might", 0) == 50, "first Might level costs 50");
            Check(Upgrades.Cost("might", 1) == 75, "second Might level costs 75");
            var m = new MetaProgress { Souls = 1000 };
            bool ok = Upgrades.Purchase(m, "might");
            Check(ok && m.UpgradeLevel("might") == 1 && m.Souls == 950, "purchase deducts souls");
            m.SetUpgradeLevel("might", 3);
            var applied = Upgrades.ApplyTo(Stats.PlayerBase(), m);
            Check(applied.Attack == Stats.PlayerBase().Attack + 6f, "Might applies +2 attack per level");
            var poor = new MetaProgress { Souls = 10 };
            Check(!Upgrades.Purchase(poor, "might"), "cannot purchase without souls");
        }
    }
}
