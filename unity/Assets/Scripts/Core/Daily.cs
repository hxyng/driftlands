using System;

namespace DriftLands.Core
{
    public struct DailyResult
    {
        public bool Claimed;
        public int Souls;
        public int Streak;
    }

    /// <summary>Daily-reward streak — C# port of the GDScript <c>Daily</c>. Dates
    /// are passed in ("yyyy-MM-dd") so the logic is testable without waiting.</summary>
    public static class Daily
    {
        public const int BaseReward = 25;
        public const int StreakBonus = 10;

        public static string Today() => DateTime.Now.ToString("yyyy-MM-dd");

        public static bool CanClaim(MetaProgress meta, string today) => meta.DailyLastClaim != today;

        public static DailyResult Claim(MetaProgress meta, string today)
        {
            if (meta.DailyLastClaim == today)
                return new DailyResult { Claimed = false, Souls = 0, Streak = meta.DailyStreak };

            if (meta.DailyLastClaim != "" && DaysBetween(meta.DailyLastClaim, today) == 1)
                meta.DailyStreak += 1;
            else
                meta.DailyStreak = 1;
            meta.DailyLastClaim = today;

            int souls = BaseReward + meta.DailyStreak * StreakBonus;
            meta.Souls += souls;
            return new DailyResult { Claimed = true, Souls = souls, Streak = meta.DailyStreak };
        }

        private static int DaysBetween(string a, string b)
        {
            var da = DateTime.Parse(a);
            var db = DateTime.Parse(b);
            return (int)Math.Round((db - da).TotalDays);
        }
    }
}
