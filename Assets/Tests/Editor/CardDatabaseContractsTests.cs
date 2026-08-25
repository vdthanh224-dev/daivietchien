using System.Linq;
using NUnit.Framework;

public sealed class CardDatabaseContractsTests
{
    [Test]
    public void StandardAndExpandedDecksHaveExpectedSizesAndUniqueIds()
    {
        var standard = CardDatabase.CreateDeck(52);
        var expanded = CardDatabase.CreateDeck(104);

        Assert.That(standard, Has.Count.EqualTo(52));
        Assert.That(expanded, Has.Count.EqualTo(104));
        Assert.That(standard.Select(card => card.id).Distinct().Count(), Is.EqualTo(standard.Count));
        Assert.That(expanded.Select(card => card.id).Distinct().Count(), Is.EqualTo(expanded.Count));
    }

    [Test]
    public void ExceptionsAndDelayedCardsKeepTheirRules()
    {
        var deck = CardDatabase.CreateDeck(104);

        var crossbow = deck.Single(card => card.cardName == "Nỏ Thần Kim Quy");
        Assert.That(crossbow.attackRange, Is.EqualTo(1));

        var lightning = deck.Single(card => card.subType == CardSubType.Lightning);
        Assert.That(lightning.suit, Is.EqualTo(CardSuit.Club));
        Assert.That(lightning.rank, Is.EqualTo(CardRank.Ace));

        var supplyShortages = deck.Where(card => card.subType == CardSubType.SupplyShortage).ToList();
        Assert.That(supplyShortages, Has.Count.EqualTo(2));
        Assert.That(supplyShortages.All(card => card.description.Contains("cự ly 1")), Is.True);
    }
}
