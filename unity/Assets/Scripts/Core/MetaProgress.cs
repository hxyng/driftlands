using System;
using System.Collections.Generic;

namespace DriftLands.Core
{
    /// <summary>Persistent meta-progression — C# port of the GDScript <c>MetaProgress</c>.</summary>
    public sealed class MetaProgress
    {
        public int Souls;
        public int BestFloor;
        public int TotalRuns;
        public Dictionary<string, int> Upgrades = new Dictionary<string, int>();
        public string DailyLastClaim = "";
        public int DailyStreak;
        public List<string> Unlocked = new List<string>();

        public int UpgradeLevel(string id) => Upgrades.TryGetValue(id, out var v) ? v : 0;

        public void SetUpgradeLevel(string id, int level) => Upgrades[id] = Math.Max(level, 0);

        public bool IsUnlocked(string id) => Unlocked.Contains(id);

        public void Unlock(string id)
        {
            if (!Unlocked.Contains(id))
                Unlocked.Add(id);
        }
    }
}
