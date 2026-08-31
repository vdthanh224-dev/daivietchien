using System;
using UnityEngine;

public enum CardSuit
{
    Spade,    // Bích ♠ (Đen)
    Club,     // Chuồn / Tép ♣ (Đen)
    Heart,    // Cơ ♥ (Đỏ)
    Diamond   // Rô ♦ (Đỏ)
}

public enum CardRank
{
    Ace = 1,
    Two = 2,
    Three = 3,
    Four = 4,
    Five = 5,
    Six = 6,
    Seven = 7,
    Eight = 8,
    Nine = 9,
    Ten = 10,
    Jack = 11,
    Queen = 12,
    King = 13
}

public enum CardCategory
{
    Basic,          // Bài Cơ Bản (Trảm, Đỡ, Bánh Chưng, Hủ Rượu)
    Equipment,      // Bài Trang Bị (Vũ khí, Giáp, Chiến mã)
    InstantScroll,  // Cẩm Nang Tức Thời (Dụng Binh, Diệu Kế, Vườn Không...)
    DelayedScroll   // Cẩm Nang Trì Hoãn (Thần Sấm, Cắt Đường Lương, Trầm Ảo...)
}

public enum CardSubType
{
    // Cơ bản
    AttackNormal,    // Trảm Thường (Đen / Đỏ)
    AttackFire,      // Trảm - Hỏa
    AttackThunder,   // Trảm - Lôi
    Dodge,           // Đỡ
    Peach,           // Bánh Chưng (Hồi máu / Cứu nạn)
    Wine,            // Hủ Rượu (+1 Sát thương Trảm / Tự cứu)

    // Trang bị
    Weapon,          // Vũ khí (Kiếm Thuận Thiên, Song Cung, Nỏ Thần, Trường Đao, Thương Ngâu, Súng Thần Công)
    Armor,           // Giáp (Giáp Đồng Sơn Vi, Khiên Mây Bện, Áo Bào Hoàng Tộc)
    OffensiveHorse,  // Ngựa công / Ngựa Trắng Thuần Nông (-1 Khoảng cách)
    DefensiveHorse,  // Ngựa thủ / Voi Chiến Đại Việt (+1 Khoảng cách)

    // Cẩm nang tức thời
    FlawlessDefense, // Diệu Kế Phá Mưu
    Dismantle,       // Vườn Không Nhà Trống
    Snatch,          // Đột Kích Trộm Lương
    ExNihilo,        // Dụng Binh Như Thần
    Duel,            // Thách Đấu
    Harvest,         // Mở Kho Cứu Tế
    BarbarianInvasion,// Bãi Cọc Ngầm
    ArrowRain,       // Mưa Tên Liên Châu

    // Cẩm nang trì hoãn
    Lightning,       // Thần Sấm Báo Ứng (A♣)
    SupplyShortage,  // Cắt Đường Lương (J♦, Q♥)
    Acedia           // Trầm Ảo Sa Bẫy (6♠, K♥)
}

[Serializable]
public class CardModel
{
    public string id;
    public string cardName;
    public CardSuit suit;
    public CardRank rank;
    public int deckNumber; // 1 hoặc 2
    public CardCategory category;
    public CardSubType subType;
    public int attackRange; // Tầm đánh đối với vũ khí (2, 3, 4, 5)
    public int distanceModifier; // -1 hoặc +1 đối với chiến mã
    public string description;
    public string iconPath;

    [Header("Skill Backup Attributes (Tiến Thoái / Chế Nỏ...)")]
    public string originalName;
    public CardCategory? originalCategory;
    public CardSubType? originalSubType;
    public int? originalAttackRange;
    public string originalDescription;
    public string originalIconPath;

    /// <summary>
    /// Clears the temporary Tiến Thoái / Chế Nỏ conversion before a card is reused.
    /// The skill changes only the card while it remains in the current hand;
    /// a card drawn back from the discard pile must recover its printed face.
    /// </summary>
    public void ResetTransientTransformation()
    {
        if (!originalSubType.HasValue && !originalCategory.HasValue)
            return;

        cardName = originalName ?? cardName;
        if (originalCategory.HasValue) category = originalCategory.Value;
        if (originalSubType.HasValue) subType = originalSubType.Value;
        if (originalAttackRange.HasValue) attackRange = originalAttackRange.Value;
        description = originalDescription ?? description;
        iconPath = originalIconPath ?? iconPath;

        originalName = null;
        originalCategory = null;
        originalSubType = null;
        originalAttackRange = null;
        originalDescription = null;
        originalIconPath = null;
    }

    public bool IsRed => suit == CardSuit.Heart || suit == CardSuit.Diamond;
    public bool IsBlack => suit == CardSuit.Spade || suit == CardSuit.Club;

    public string SuitString
    {
        get
        {
            return suit switch
            {
                CardSuit.Spade => "♠",
                CardSuit.Heart => "♥",
                CardSuit.Club => "♣",
                CardSuit.Diamond => "♦",
                _ => "?"
            };
        }
    }

        public string GetFormattedName()
    {
        if ((int)suit == 0 && (int)rank == 0) return $"[{cardName}]";
        string colorTag = IsRed ? "<color=#FF5555>" : "<color=#BBBBBB>";
        return $"[{cardName} ({colorTag}{SuitString}</color> {RankString})]";
    }

public string GetSuitSymbol()
    {
        return SuitString;
    }

    public string GetSuitShortName()
    {
        return suit switch
        {
            CardSuit.Spade => "Bích",
            CardSuit.Club => "Chuồn",
            CardSuit.Heart => "Cơ",
            CardSuit.Diamond => "Rô",
            _ => "?"
        };
    }

    public string GetSuitFullName()
    {
        return suit switch
        {
            CardSuit.Spade => "Bích ♠",
            CardSuit.Club => "Chuồn ♣",
            CardSuit.Heart => "Cơ ♥",
            CardSuit.Diamond => "Rô ♦",
            _ => "?"
        };
    }

    public string GetSuitIconPath()
    {
        return suit switch
        {
            CardSuit.Spade => "UI/suit_spade",
            CardSuit.Club => "UI/suit_club",
            CardSuit.Heart => "UI/suit_heart",
            CardSuit.Diamond => "UI/suit_diamond",
            _ => "UI/suit_spade"
        };
    }

    public Color GetSuitColor()
    {
        return IsRed ? new Color(0.85f, 0.15f, 0.15f, 1f) : new Color(0.12f, 0.14f, 0.18f, 1f);
    }

    public string RankString
    {
        get
        {
            return rank switch
            {
                CardRank.Ace => "A",
                CardRank.Jack => "J",
                CardRank.Queen => "Q",
                CardRank.King => "K",
                _ => ((int)rank).ToString()
            };
        }
    }

    public string GetRankString()
    {
        return RankString;
    }

    public string GetCategoryName()
    {
        return category switch
        {
            CardCategory.Basic => "CƠ BẢN",
            CardCategory.Equipment => subType switch
            {
                CardSubType.Weapon => $"VŨ KHÍ (TẦM {attackRange})",
                CardSubType.Armor => "ÁO GIÁP",
                CardSubType.OffensiveHorse => "NGỰA CÔNG (-1)",
                CardSubType.DefensiveHorse => "NGỰA THỦ (+1)",
                _ => "TRANG BỊ"
            },
            CardCategory.InstantScroll => "CẨM NANG",
            CardCategory.DelayedScroll => "CẨM NANG TRÌ HOÃN",
            _ => "CHIẾN BÀI"
        };
    }

    /// <summary>
    /// Compatibility alias for callers that describe the operation as a
    /// restore rather than a transient transformation reset.
    /// </summary>
    public void RestoreOriginalState()
    {
        ResetTransientTransformation();
    }
}
