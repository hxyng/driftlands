using System;

namespace DriftLands.Core
{
    public enum Slot { Weapon, Armor, Helm, Ring, Boots }

    /// <summary>An equippable item — C# port of the GDScript <c>Item</c>.</summary>
    public sealed class Item
    {
        public string Id = "";
        public string DisplayName = "";
        public Slot Slot = Slot.Weapon;
        public string Rarity = "common";
        public int FloorFound = 1;
        public Stats Mods = new Stats();

        /// <summary>A scalar "how good is this item" for auto-equip comparisons.</summary>
        public float Power()
        {
            if (Mods == null)
                return 0f;
            return Math.Abs(Mods.MaxHp) + Math.Abs(Mods.Attack) * 5f + Math.Abs(Mods.Defense) * 4f
                + Math.Abs(Mods.CritChance) * 200f + Math.Abs(Mods.AttackSpeed) * 120f
                + Math.Abs(Mods.MoveSpeed) + Math.Abs(Mods.PickupRange) * 0.5f + Math.Abs(Mods.Luck) * 8f;
        }
    }
}
