using System;
using System.Collections.Generic;

namespace DriftLands.Core
{
    /// <summary>Equipment generation — C# port of the GDScript <c>LootTable</c>.</summary>
    public static class LootTable
    {
        public static readonly string[] Rarities = { "common", "uncommon", "rare", "epic", "legendary" };

        private static readonly Dictionary<string, float> RarityMult = new Dictionary<string, float>
        {
            { "common", 1.0f }, { "uncommon", 1.4f }, { "rare", 1.9f },
            { "epic", 2.6f }, { "legendary", 3.4f },
        };

        private static readonly Dictionary<Slot, string[]> NameBase = new Dictionary<Slot, string[]>
        {
            { Slot.Weapon, new[] { "Dirk", "Blade", "Cleaver" } },
            { Slot.Armor, new[] { "Jerkin", "Mail", "Hauberk" } },
            { Slot.Helm, new[] { "Coif", "Casque", "Greathelm" } },
            { Slot.Ring, new[] { "Band", "Loop", "Signet" } },
            { Slot.Boots, new[] { "Treads", "Greaves", "Sabatons" } },
        };

        private static readonly Dictionary<string, string> NamePrefix = new Dictionary<string, string>
        {
            { "common", "Worn" }, { "uncommon", "Sturdy" }, { "rare", "Runed" },
            { "epic", "Emberforged" }, { "legendary", "Ashen" },
        };

        public static string RollRarity(Random rng, int floor, float luck)
        {
            double t = rng.NextDouble() + luck * 0.015 + floor * 0.012;
            if (t > 0.985) return "legendary";
            if (t > 0.93) return "epic";
            if (t > 0.80) return "rare";
            if (t > 0.55) return "uncommon";
            return "common";
        }

        public static Item Roll(Random rng, int floor, float luck = 0f)
        {
            var item = new Item
            {
                Slot = (Slot)rng.Next(0, 5),
                FloorFound = floor,
            };
            item.Rarity = RollRarity(rng, floor, luck);
            float budget = (4f + floor * 1.6f) * RarityMult[item.Rarity];
            item.Mods = BudgetToMods(item.Slot, budget, rng);
            item.DisplayName = NamePrefix[item.Rarity] + " " + BaseName(item.Slot, rng);
            item.Id = item.Rarity + "_" + item.Slot + "_" + rng.Next(0, 100000);
            return item;
        }

        private static string BaseName(Slot slot, Random rng)
        {
            var options = NameBase[slot];
            return options[rng.Next(0, options.Length)];
        }

        private static Stats BudgetToMods(Slot slot, float budget, Random rng)
        {
            var s = new Stats();
            switch (slot)
            {
                case Slot.Weapon:
                    s.Attack += budget * 0.9f;
                    if (rng.NextDouble() < 0.5) s.CritChance += 0.03f + budget * 0.002f;
                    break;
                case Slot.Armor:
                    s.MaxHp += budget * 3.0f;
                    s.Defense += budget * 0.4f;
                    break;
                case Slot.Helm:
                    s.MaxHp += budget * 2.0f;
                    s.Defense += budget * 0.25f;
                    if (rng.NextDouble() < 0.4) s.Attack += budget * 0.2f;
                    break;
                case Slot.Ring:
                    switch (rng.Next(0, 3))
                    {
                        case 0: s.CritChance += 0.04f + budget * 0.003f; break;
                        case 1: s.AttackSpeed += 0.08f + budget * 0.01f; break;
                        default: s.Luck += 1f + budget * 0.05f; break;
                    }
                    break;
                case Slot.Boots:
                    s.MoveSpeed += budget * 1.6f;
                    s.PickupRange += budget * 0.8f;
                    break;
            }
            return s;
        }
    }
}
