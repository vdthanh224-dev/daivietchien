using System;
using UnityEngine;

[Serializable]
public struct RankTierInfo
{
    public int tierIndex;
    public string name;
    public string badge;
    public string subtitle;
    public int minPoints;
    public int maxPoints;
    public Color color;
    public string description;

    public string ColorHex => "#" + ColorUtility.ToHtmlStringRGB(color);
}

/// <summary>
/// Hệ Thống 12 Bậc Quân Hàm / Quân Công Toàn Cục (Military Rank System)
/// Người chơi mới khởi điểm từ 0 điểm.
/// </summary>
public static class MilitaryRankSystem
{
    public static readonly RankTierInfo[] Tiers = new RankTierInfo[]
    {
        new RankTierInfo { tierIndex = 1,  name = "Tân Binh",        badge = "🔰", subtitle = "Bậc 1/12", minPoints = 0,    maxPoints = 99,   color = new Color(0.72f, 0.78f, 0.85f, 1f), description = "Chiến sĩ mới gia nhập hàng ngũ nghĩa quân Đại Việt." },
        new RankTierInfo { tierIndex = 2,  name = "Binh Nhì",        badge = "🗡️", subtitle = "Bậc 2/12", minPoints = 100,  maxPoints = 299,  color = new Color(0.80f, 0.88f, 0.95f, 1f), description = "Đã thuần thục kiếm pháp và thao lược trận mạc cơ bản." },
        new RankTierInfo { tierIndex = 3,  name = "Binh Nhất",       badge = "⚔️", subtitle = "Bậc 3/12", minPoints = 300,  maxPoints = 599,  color = new Color(0.55f, 0.82f, 1.00f, 1f), description = "Tay giáo thiện chiến nơi tiền tuyến, dũng cảm xung phong." },
        new RankTierInfo { tierIndex = 4,  name = "Thập Trưởng",     badge = "🛡️", subtitle = "Bậc 4/12", minPoints = 600,  maxPoints = 999,  color = new Color(0.40f, 0.92f, 0.70f, 1f), description = "Chỉ huy tiểu đội 10 binh sĩ, kiên cố phòng thủ biên cương." },
        new RankTierInfo { tierIndex = 5,  name = "Bách Trưởng",     badge = "🎖️", subtitle = "Bậc 5/12", minPoints = 1000, maxPoints = 1499, color = new Color(0.95f, 0.85f, 0.35f, 1f), description = "Thống lĩnh đại đội 100 quân sĩ, dạn dày khói lửa sa trường." },
        new RankTierInfo { tierIndex = 6,  name = "Thiên Trưởng",    badge = "🚩", subtitle = "Bậc 6/12", minPoints = 1500, maxPoints = 2199, color = new Color(1.00f, 0.72f, 0.20f, 1f), description = "Chỉ huy chiến đoàn ngàn binh mã, cờ phướn rợp trời." },
        new RankTierInfo { tierIndex = 7,  name = "Phó Tướng",       badge = "⚡", subtitle = "Bậc 7/12", minPoints = 2200, maxPoints = 2999, color = new Color(1.00f, 0.55f, 0.20f, 1f), description = "Cánh tay đắc lực của chủ tướng, điều binh khiển tướng như thần." },
        new RankTierInfo { tierIndex = 8,  name = "Chánh Tướng",     badge = "⭐", subtitle = "Bậc 8/12", minPoints = 3000, maxPoints = 3999, color = new Color(1.00f, 0.40f, 0.40f, 1f), description = "Thống lĩnh đại quân trấn giữ yếu đạo, uy danh vang dội." },
        new RankTierInfo { tierIndex = 9,  name = "Thiếu Tướng",     badge = "🌟", subtitle = "Bậc 9/12", minPoints = 4000, maxPoints = 5199, color = new Color(0.92f, 0.45f, 1.00f, 1f), description = "Tướng lĩnh cao cấp nắm giữ vận mệnh nhiều chiến dịch lớn." },
        new RankTierInfo { tierIndex = 10, name = "Trung Tướng",     badge = "👑", subtitle = "Bậc 10/12", minPoints = 5200, maxPoints = 6599, color = new Color(0.75f, 0.50f, 1.00f, 1f), description = "Trụ cột triều đình, mưu lược cái thế, địch nghe tên kinh hồn bạt vía." },
        new RankTierInfo { tierIndex = 11, name = "Đại Tướng Quân",  badge = "🦅", subtitle = "Bậc 11/12", minPoints = 6600, maxPoints = 8199, color = new Color(0.35f, 0.85f, 1.00f, 1f), description = "Tướng soái bách chiến bách thắng, uy danh chấn động bốn cõi non sông." },
        new RankTierInfo { tierIndex = 12, name = "Đại Nguyên Soái", badge = "🔥", subtitle = "Bậc 12/12", minPoints = 8200, maxPoints = 999999, color = new Color(1.00f, 0.84f, 0.00f, 1f), description = "Bậc Thống Soái tối cao, thống lĩnh toàn bộ quân lực bảo vệ xã tắc vĩnh cửu." }
    };

    public static RankTierInfo GetTier(int points)
    {
        points = Mathf.Max(0, points);
        for (int i = Tiers.Length - 1; i >= 0; i--)
        {
            if (points >= Tiers[i].minPoints) return Tiers[i];
        }
        return Tiers[0];
    }

    public static RankTierInfo GetNextTier(int points)
    {
        var current = GetTier(points);
        if (current.tierIndex >= 12) return current;
        return Tiers[current.tierIndex];
    }

    public static float GetProgress(int points)
    {
        var current = GetTier(points);
        if (current.tierIndex >= 12) return 1f;
        var next = GetNextTier(points);
        float range = next.minPoints - current.minPoints;
        if (range <= 0) return 1f;
        return Mathf.Clamp01((float)(points - current.minPoints) / range);
    }
}

/// <summary>
/// Hệ Thống 12 Bậc Xếp Hạng 2v2 Đồng Đội (2v2 Ranked Ladder System)
/// Tên gọi, biểu tượng và cấp bậc hoàn toàn độc lập, khác biệt với Quân Hàm.
/// </summary>
public static class Ranked2v2System
{
    public static readonly RankTierInfo[] Tiers = new RankTierInfo[]
    {
        new RankTierInfo { tierIndex = 1,  name = "Khởi Binh (Đồng Tâm I)",   badge = "🥉", subtitle = "Bậc 1/12", minPoints = 0,    maxPoints = 199,  color = new Color(0.75f, 0.60f, 0.45f, 1f), description = "Bước đầu kết đôi hiệp lực, tôi luyện sự ăn ý trong chiến thuật 2v2." },
        new RankTierInfo { tierIndex = 2,  name = "Tiên Phong (Đồng Tâm II)", badge = "🥉", subtitle = "Bậc 2/12", minPoints = 200,  maxPoints = 399,  color = new Color(0.85f, 0.68f, 0.50f, 1f), description = "Tiên phong mở đường trận địa, phối hợp linh hoạt cùng đồng đội." },
        new RankTierInfo { tierIndex = 3,  name = "Hợp Lực (Tương Trợ I)",    badge = "🥈", subtitle = "Bậc 3/12", minPoints = 400,  maxPoints = 699,  color = new Color(0.75f, 0.85f, 0.95f, 1f), description = "Bắt đầu biết chia sẻ tài nguyên bài và ứng cứu đồng đội khi nguy cấp." },
        new RankTierInfo { tierIndex = 4,  name = "Hiệp Binh (Tương Trợ II)", badge = "🥈", subtitle = "Bậc 4/12", minPoints = 700,  maxPoints = 999,  color = new Color(0.88f, 0.94f, 1.00f, 1f), description = "Cặp đôi tác chiến nhịp nhàng, công thủ song hành bất khả xâm phạm." },
        new RankTierInfo { tierIndex = 5,  name = "Bách Chiến (Kiên Cố)",     badge = "🥇", subtitle = "Bậc 5/12", minPoints = 1000, maxPoints = 1399, color = new Color(0.95f, 0.80f, 0.25f, 1f), description = "Cặp đôi kiên cường trải qua trăm trận thử lửa, phòng ngự vững như bàn thạch." },
        new RankTierInfo { tierIndex = 6,  name = "Song Toàn (Phá Trận)",     badge = "🥇", subtitle = "Bậc 6/12", minPoints = 1400, maxPoints = 1899, color = new Color(1.00f, 0.88f, 0.35f, 1f), description = "Kỹ năng phối hợp tuyệt hảo, dễ dàng phá vỡ thế trận của cặp đối phương." },
        new RankTierInfo { tierIndex = 7,  name = "Kỳ Binh (Hiệp Dũng)",      badge = "💎", subtitle = "Bậc 7/12", minPoints = 1900, maxPoints = 2499, color = new Color(0.30f, 0.85f, 0.95f, 1f), description = "Đột kích biến hóa khôn lường, tạo nên những màn lật kèo ngoạn mục." },
        new RankTierInfo { tierIndex = 8,  name = "Thiết Vệ (Kim Cương)",     badge = "💎", subtitle = "Bậc 8/12", minPoints = 2500, maxPoints = 3199, color = new Color(0.45f, 0.95f, 1.00f, 1f), description = "Lá chắn thép bảo vệ lẫn nhau, phản kích chí mạng trước mọi đòn hiểm." },
        new RankTierInfo { tierIndex = 9,  name = "Hùng Sư (Trấn Quốc)",      badge = "🏆", subtitle = "Bậc 9/12", minPoints = 3200, maxPoints = 3999, color = new Color(1.00f, 0.50f, 0.20f, 1f), description = "Cặp đôi dũng mãnh tựa song hổ, áp đảo mọi chiến trường đấu trường 2v2." },
        new RankTierInfo { tierIndex = 10, name = "Vương Giả (Chí Tôn)",      badge = "👑", subtitle = "Bậc 10/12", minPoints = 4000, maxPoints = 4999, color = new Color(0.90f, 0.35f, 1.00f, 1f), description = "Đạt tới cảnh giới vương quyền 2v2, danh tiếng lưu truyền khắp máy chủ." },
        new RankTierInfo { tierIndex = 11, name = "Vô Song Hào Kiệt",         badge = "⚡", subtitle = "Bậc 11/12", minPoints = 5000, maxPoints = 6199, color = new Color(1.00f, 0.30f, 0.60f, 1f), description = "Cặp đôi vô địch thiên hạ, thao lược và ăn ý đạt độ hoàn mỹ tột đỉnh." },
        new RankTierInfo { tierIndex = 12, name = "Thần Thoại Quân Vương",    badge = "🌌", subtitle = "Bậc 12/12", minPoints = 6200, maxPoints = 999999, color = new Color(1.00f, 0.85f, 0.20f, 1f), description = "Bậc Thầy 2v2 Tối Thượng, đứng trên đỉnh vinh quang bất diệt của Đại Việt Chiến." }
    };

    public static RankTierInfo GetTier(int points)
    {
        points = Mathf.Max(0, points);
        for (int i = Tiers.Length - 1; i >= 0; i--)
        {
            if (points >= Tiers[i].minPoints) return Tiers[i];
        }
        return Tiers[0];
    }

    public static RankTierInfo GetNextTier(int points)
    {
        var current = GetTier(points);
        if (current.tierIndex >= 12) return current;
        return Tiers[current.tierIndex];
    }

    public static float GetProgress(int points)
    {
        var current = GetTier(points);
        if (current.tierIndex >= 12) return 1f;
        var next = GetNextTier(points);
        float range = next.minPoints - current.minPoints;
        if (range <= 0) return 1f;
        return Mathf.Clamp01((float)(points - current.minPoints) / range);
    }
}
