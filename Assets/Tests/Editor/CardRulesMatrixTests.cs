using System.Linq;
using NUnit.Framework;

/// <summary>
/// Contract checks for the card matrix in Bài2.md.  These tests intentionally
/// assert gameplay-relevant metadata, not localized display wording.
/// </summary>
public sealed class CardRulesMatrixTests
{
    [Test]
    public void StandardDeckContainsTheExpectedCardGroups()
    {
        var deck = CardDatabase.CreateDeck(52);

        Assert.That(deck.Count(c => c.subType == CardSubType.AttackNormal), Is.EqualTo(3));
        Assert.That(deck.Count(c => c.subType == CardSubType.AttackFire), Is.EqualTo(2));
        Assert.That(deck.Count(c => c.subType == CardSubType.AttackThunder), Is.EqualTo(4));
        Assert.That(deck.Count(c => c.subType == CardSubType.Dodge), Is.EqualTo(8));
        Assert.That(deck.Count(c => c.subType == CardSubType.Peach), Is.EqualTo(5));
        Assert.That(deck.Count(c => c.subType == CardSubType.Wine), Is.EqualTo(3));
        Assert.That(deck.Count(c => c.subType == CardSubType.Weapon), Is.EqualTo(5));
        Assert.That(deck.Count(c => c.subType == CardSubType.Armor), Is.EqualTo(1));
        Assert.That(deck.Count(c => c.subType == CardSubType.OffensiveHorse || c.subType == CardSubType.DefensiveHorse), Is.EqualTo(2));
        // The detailed 52-card list contains three delayed cards (including
        // Thần Sấm); the summary table in Bài2.md lists 17/2, which is a
        // documented aggregate typo.
        Assert.That(deck.Count(c => c.category == CardCategory.InstantScroll), Is.EqualTo(15));
        Assert.That(deck.Count(c => c.category == CardCategory.DelayedScroll), Is.EqualTo(3));
    }

    [Test]
    public void ExpandedDeckContainsTheExpectedCardGroups()
    {
        var deck = CardDatabase.CreateDeck(104);

        Assert.That(deck.Count(c => c.subType == CardSubType.AttackNormal), Is.EqualTo(26));
        Assert.That(deck.Count(c => c.subType == CardSubType.AttackFire), Is.EqualTo(3));
        Assert.That(deck.Count(c => c.subType == CardSubType.AttackThunder), Is.EqualTo(4));
        Assert.That(deck.Count(c => c.subType == CardSubType.Dodge), Is.EqualTo(14));
        Assert.That(deck.Count(c => c.subType == CardSubType.Peach), Is.EqualTo(7));
        Assert.That(deck.Count(c => c.subType == CardSubType.Wine), Is.EqualTo(4));
        Assert.That(deck.Count(c => c.subType == CardSubType.Weapon), Is.EqualTo(9));
        Assert.That(deck.Count(c => c.subType == CardSubType.Armor), Is.EqualTo(3));
        Assert.That(deck.Count(c => c.subType == CardSubType.OffensiveHorse || c.subType == CardSubType.DefensiveHorse), Is.EqualTo(5));
        Assert.That(deck.Count(c => c.category == CardCategory.InstantScroll), Is.EqualTo(24));
        Assert.That(deck.Count(c => c.category == CardCategory.DelayedScroll), Is.EqualTo(5));
    }

    [Test]
    public void WeaponAndMountRangesMatchTheRules()
    {
        var deck = CardDatabase.CreateDeck(104);

        Assert.That(deck.Where(c => c.cardName == "Nỏ Thần Kim Quy").Select(c => c.attackRange), Is.All.EqualTo(1));
        Assert.That(deck.Where(c => c.cardName == "Kiếm Thuận Thiên").Select(c => c.attackRange), Is.All.EqualTo(2));
        Assert.That(deck.Where(c => c.cardName == "Song Cung Mường Nhạ").Select(c => c.attackRange), Is.All.EqualTo(2));
        Assert.That(deck.Where(c => c.cardName == "Trường Đao Nam Sơn").Select(c => c.attackRange), Is.All.EqualTo(3));
        Assert.That(deck.Where(c => c.cardName == "Thương Ngâu Lãng Bạc").Select(c => c.attackRange), Is.All.EqualTo(4));
        Assert.That(deck.Where(c => c.cardName == "Súng Thần Công Hồ Triều").Select(c => c.attackRange), Is.All.EqualTo(5));

        Assert.That(deck.Where(c => c.subType == CardSubType.OffensiveHorse).Select(c => c.distanceModifier), Is.All.EqualTo(-1));
        Assert.That(deck.Where(c => c.subType == CardSubType.DefensiveHorse).Select(c => c.distanceModifier), Is.All.EqualTo(1));
    }

    [Test]
    public void DelayedCardsKeepTheirJudgementRulesAndQuantities()
    {
        var deck = CardDatabase.CreateDeck(104);

        var lightning = deck.Single(c => c.subType == CardSubType.Lightning);
        Assert.That(lightning.id, Is.EqualTo("D1_C_A"));
        Assert.That(lightning.suit, Is.EqualTo(CardSuit.Club));
        Assert.That(lightning.rank, Is.EqualTo(CardRank.Ace));
        Assert.That(lightning.description, Does.Contain("Bích 2-9"));

        var supply = deck.Where(c => c.subType == CardSubType.SupplyShortage).ToList();
        Assert.That(supply, Has.Count.EqualTo(2));
        Assert.That(supply.Select(c => c.id), Is.EquivalentTo(new[] { "D1_D_J", "D2_H_Q" }));
        Assert.That(supply.All(c => c.description.Contains("cự ly 1")), Is.True);

        var acedia = deck.Where(c => c.subType == CardSubType.Acedia).ToList();
        Assert.That(acedia, Has.Count.EqualTo(2));
        Assert.That(acedia.Select(c => c.id), Is.EquivalentTo(new[] { "D1_S_6", "D2_H_K" }));
        Assert.That(acedia.All(c => c.description.Contains("KHÔNG PHẢI Cơ")), Is.True);
    }

    [Test]
    public void DismantleAndSnatchHaveTheAttackerChosenTargetContract()
    {
        var deck = CardDatabase.CreateDeck(104);
        var dismantle = deck.Where(c => c.subType == CardSubType.Dismantle).ToList();
        var snatch = deck.Where(c => c.subType == CardSubType.Snatch).ToList();

        Assert.That(dismantle, Has.Count.EqualTo(6));
        Assert.That(dismantle.All(c => c.description.Contains("Người tấn công chọn")), Is.True);
        Assert.That(snatch, Has.Count.EqualTo(5));
        Assert.That(snatch.All(c => c.description.Contains("vùng trì hoãn")), Is.True);
    }

    [Test]
    public void TienThoaiTransformationCanBeNormalizedBeforeReuse()
    {
        var card = new CardModel
        {
            cardName = "Đỡ",
            subType = CardSubType.Dodge,
            description = "temporary",
            iconPath = "temporary-icon",
            originalName = "Trảm Thường",
            originalSubType = CardSubType.AttackNormal,
            originalDescription = "printed",
            originalIconPath = "printed-icon"
        };

        card.ResetTransientTransformation();

        Assert.That(card.cardName, Is.EqualTo("Trảm Thường"));
        Assert.That(card.subType, Is.EqualTo(CardSubType.AttackNormal));
        Assert.That(card.description, Is.EqualTo("printed"));
        Assert.That(card.iconPath, Is.EqualTo("printed-icon"));
        Assert.That(card.originalSubType, Is.Null);
    }
}
