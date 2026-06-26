using System.Collections.Generic;

namespace DriftLands.Core
{
    /// <summary>The five equip slots — C# port of the GDScript <c>Equipment</c>.</summary>
    public sealed class Equipment
    {
        private readonly Dictionary<Slot, Item> _slots = new Dictionary<Slot, Item>();

        /// <summary>Equips <paramref name="item"/>, returning the displaced item (or null).</summary>
        public Item Equip(Item item)
        {
            _slots.TryGetValue(item.Slot, out var prev);
            _slots[item.Slot] = item;
            return prev;
        }

        public Item Unequip(Slot slot)
        {
            _slots.TryGetValue(slot, out var prev);
            _slots.Remove(slot);
            return prev;
        }

        public Item Get(Slot slot)
        {
            _slots.TryGetValue(slot, out var item);
            return item;
        }

        public Stats TotalMods()
        {
            var s = new Stats();
            foreach (var item in _slots.Values)
                if (item?.Mods != null)
                    s = s.Add(item.Mods);
            return s;
        }
    }
}
