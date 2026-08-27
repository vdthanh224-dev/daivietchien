using System;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Quản lý Kho Bài Đại Việt Chiến (Draw Pile & Discard Pile)
/// Quy tắc:
/// 1. Bắt đầu xáo bộ bài 1 lần.
/// 2. Chia 4 lá bài cho mỗi người chơi khi vào trận.
/// 3. Rút bài đến khi xấp bài rút cạn (0 lá), tự động gom các lá đã dùng (Discard Pile) đem xáo lại thành xấp rút mới.
/// 4. Các lá bài trên tay và lá bài trang bị đang đeo không bị xáo.
/// </summary>
public class CardDeckManager : MonoBehaviour
{
    private static CardDeckManager instance;
    public static CardDeckManager Instance => instance;

    [Header("Deck Settings")]
    [SerializeField] private int deckMode = 52; // 52 hoặc 104 lá

    private readonly List<CardModel> drawPile = new List<CardModel>();
    private readonly List<CardModel> discardPile = new List<CardModel>();

    public int DrawPileCount => drawPile.Count;
    public int DiscardPileCount => discardPile.Count;
    public int DeckMode => deckMode;

    public event Action<int, int> OnDeckCountsChanged; // (drawCount, discardCount)
    public event Action OnDeckReshuffled;
    public event Action<CardModel> OnCardDiscarded;

    private void Awake()
    {
        instance = this;
    }

    /// <summary>
    /// Khởi tạo kho bài: Nạp danh sách bài và xáo bài lần đầu tiên.
    /// </summary>
    private int currentDeckSeed = 0;

    public void InitializeDeck(int mode = 52, int seed = 0)
    {
        deckMode = mode;
        currentDeckSeed = seed;
        drawPile.Clear();
        discardPile.Clear();

        var masterDeck = CardDatabase.CreateDeck(deckMode);
        drawPile.AddRange(masterDeck);

        // Xáo bộ bài 1 lần lúc bắt đầu với seed đồng bộ
        ShuffleList(drawPile, currentDeckSeed);
        Debug.Log($"[CardDeckManager] Đã khởi tạo kho bài {deckMode} lá và xáo bài lần đầu (Seed: {currentDeckSeed}).");

        NotifyCounts();
    }

    /// <summary>
    /// Đảm bảo lá bài tại vị trí index thỏa điều kiện predicate (dùng cho ván tân thủ để đảm bảo bài thực tế rút ra có Trảm/Đỡ).
    /// Hoán đổi với lá bài hợp lệ đầu tiên trong xấp rút, bảo toàn toàn bộ danh sách bài.
    /// </summary>
    public void SwapCardToPosition(int targetIndex, Predicate<CardModel> predicate)
    {
        if (predicate == null || targetIndex < 0 || targetIndex >= drawPile.Count) return;
        if (predicate(drawPile[targetIndex])) return;

        int foundIdx = drawPile.FindIndex(predicate);
        if (foundIdx >= 0)
        {
            var tmp = drawPile[targetIndex];
            drawPile[targetIndex] = drawPile[foundIdx];
            drawPile[foundIdx] = tmp;
        }
    }

    /// <summary>
    /// Rút 1 lá bài từ xấp bài rút.
    /// Nếu xấp bài rút hết (0 lá), tự động gom xấp bài đã dùng (Discard Pile) xáo lại.
    /// </summary>
    public CardModel DrawCard()
    {
        if (drawPile.Count == 0)
        {
            ReshuffleDiscardIntoDraw();
        }

        if (drawPile.Count == 0)
        {
            Debug.LogWarning("[CardDeckManager] Toàn bộ bài trong kho và xấp xả đã cạn kiệt!");
            return null;
        }

        var card = drawPile[0];
        drawPile.RemoveAt(0);
        card?.ResetTransientTransformation();
        NotifyCounts();
        return card;
    }

    /// <summary>
    /// Rút trực tiếp lá đầu tiên thỏa điều kiện mà không làm mất các lá đứng trước nó.
    /// </summary>
    public CardModel DrawMatching(Predicate<CardModel> predicate)
    {
        if (predicate == null) return DrawCard();

        // A matching card may be in the discard pile after the draw pile has
        // been exhausted (or after the current draw segment contains no
        // match). Reshuffle before falling back to a synthetic tutorial card.
        if (drawPile.Count == 0)
            ReshuffleDiscardIntoDraw();

        int index = drawPile.FindIndex(predicate);
        if (index < 0 && discardPile.Count > 0)
        {
            ReshuffleDiscardIntoDraw();
            index = drawPile.FindIndex(predicate);
        }
        if (index < 0) return null;
        var card = drawPile[index];
        drawPile.RemoveAt(index);
        card?.ResetTransientTransformation();
        NotifyCounts();
        return card;
    }

    /// <summary>
    /// Rút nhiều lá bài cùng lúc.
    /// </summary>
    public List<CardModel> DrawCards(int count)
    {
        var drawn = new List<CardModel>();
        for (int i = 0; i < count; i++)
        {
            var card = DrawCard();
            if (card != null) drawn.Add(card);
            else break;
        }
        return drawn;
    }

    /// <summary>
    /// Đưa 1 lá bài đã sử dụng vào Xấp Bài Đã Dùng (Mộ Bài / Discard Pile).
    /// </summary>
    public void DiscardCard(CardModel card)
    {
        if (card == null) return;
        card.ResetTransientTransformation();
        discardPile.Add(card);
        OnCardDiscarded?.Invoke(card);
        NotifyCounts();
    }

    /// <summary>
    /// Đưa danh sách bài đã sử dụng vào Xấp Bài Đã Dùng.
    /// </summary>
    public void DiscardCards(IEnumerable<CardModel> cards)
    {
        if (cards == null) return;
        foreach (var c in cards)
        {
            if (c != null)
            {
                c.ResetTransientTransformation();
                discardPile.Add(c);
                OnCardDiscarded?.Invoke(c);
            }
        }
        NotifyCounts();
    }

    /// <summary>
    /// Gom toàn bộ các lá bài đã dùng (Discard Pile) đem xáo lại thành xấp rút mới.
    /// (Lá trên tay và lá trang bị đang đeo không nằm trong Discard Pile nên không bị xáo).
    /// </summary>
    public void ReshuffleDiscardIntoDraw()
    {
        if (discardPile.Count == 0)
        {
            Debug.Log("[CardDeckManager] Không có lá bài nào trong xấp đã dùng để xáo lại.");
            return;
        }

        Debug.Log($"[CardDeckManager] Xấp rút đã hết! Đang gom {discardPile.Count} lá bài đã dùng để xáo lại thành xấp rút mới...");
        foreach (var card in discardPile)
            card?.ResetTransientTransformation();
        drawPile.AddRange(discardPile);
        discardPile.Clear();

        currentDeckSeed = (currentDeckSeed != 0) ? currentDeckSeed + 1337 : 0;
        ShuffleList(drawPile, currentDeckSeed);
        OnDeckReshuffled?.Invoke();
        NotifyCounts();
    }

    /// <summary>
    /// Thuật toán xáo bài ngẫu nhiên Fisher-Yates.
    /// </summary>
    public static void ShuffleList<T>(List<T> list, int seed = 0)
    {
        var rng = (seed != 0) ? new System.Random(seed) : new System.Random();
        int n = list.Count;
        while (n > 1)
        {
            n--;
            int k = rng.Next(n + 1);
            T value = list[k];
            list[k] = list[n];
            list[n] = value;
        }
    }

    private void NotifyCounts()
    {
        OnDeckCountsChanged?.Invoke(drawPile.Count, discardPile.Count);
    }
}
