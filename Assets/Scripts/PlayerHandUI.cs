using System;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Quản lý hiển thị và tương tác các lá bài trên tay của người chơi (Player Hand UI).
/// - Sắp xếp bài nằm ngang mượt mà ở cạnh dưới màn hình.
/// - Đồng bộ số lượng bài trên tay vào thẻ tướng GeneralCardUI.
/// - Chọn bài và đánh bài.
/// </summary>
public class PlayerHandUI : MonoBehaviour
{
    [Header("Configuration")]
    [SerializeField] private Vector2 cardSize = new Vector2(118, 162);
    [SerializeField] private float cardSpacing = 124f;
    [SerializeField] private GeneralCardUI boundHeroCard;

    private readonly List<CardUI> handCards = new List<CardUI>();
    private readonly List<CardUI> selectedCards = new List<CardUI>();
    private bool isMultiSelectMode = false;
    private int maxSelectableCards = 0;

    public int HandCount => handCards.Count;
    public IReadOnlyList<CardUI> Cards => handCards;
    public CardUI SelectedCard => selectedCards.Count > 0 ? selectedCards[0] : null;
    public IReadOnlyList<CardUI> SelectedCards => selectedCards;
    public int SelectedCount => selectedCards.Count;

    public int MaxSelectableCards
    {
        get => maxSelectableCards;
        set => maxSelectableCards = Mathf.Max(0, value);
    }

    public bool IsMultiSelectMode
    {
        get => isMultiSelectMode;
        set
        {
            isMultiSelectMode = value;
            if (!value)
            {
                maxSelectableCards = 0;
                if (selectedCards.Count > 1)
                {
                    var first = selectedCards[0];
                    ClearSelection();
                    SelectCard(first);
                }
            }
        }
    }

    public event Action<CardUI> OnCardSelected;
    public event Action<List<CardUI>> OnSelectionChanged;
    public event Action<CardUI> OnCardPlayed;

    public void BindHeroCard(GeneralCardUI hero)
    {
        boundHeroCard = hero;
        SyncHeroHandCount();
    }

    /// <summary>
    /// Thêm 1 lá bài mới vào tay.
    /// </summary>
    public CardUI AddCard(CardModel card)
    {
        if (card == null) return null;

        var cardUI = CardUI.Create(transform, card, cardSize);
        cardUI.OnCardClicked += HandleCardClicked;
        handCards.Add(cardUI);

        RearrangeHand();
        SyncHeroHandCount();
        return cardUI;
    }

    /// <summary>
    /// Thêm danh sách nhiều lá bài vào tay.
    /// </summary>
    public void AddCards(IEnumerable<CardModel> cards)
    {
        if (cards == null) return;
        foreach (var c in cards)
        {
            if (c != null)
            {
                var cardUI = CardUI.Create(transform, c, cardSize);
                cardUI.OnCardClicked += HandleCardClicked;
                handCards.Add(cardUI);
            }
        }
        RearrangeHand();
        SyncHeroHandCount();
    }

    /// <summary>
    /// Bỏ 1 lá bài ra khỏi tay (để đánh ra hoặc hủy).
    /// </summary>
    public bool RemoveCard(CardUI cardUI)
    {
        if (cardUI == null || !handCards.Contains(cardUI)) return false;

        selectedCards.Remove(cardUI);

        handCards.Remove(cardUI);
        cardUI.OnCardClicked -= HandleCardClicked;
        Destroy(cardUI.gameObject);

        RearrangeHand();
        SyncHeroHandCount();
        OnCardSelected?.Invoke(SelectedCard);
        OnSelectionChanged?.Invoke(new List<CardUI>(selectedCards));
        return true;
    }

    /// <summary>
    /// Bỏ nhiều lá bài cùng một lúc ra khỏi tay.
    /// </summary>
    public int RemoveCards(IEnumerable<CardUI> toRemove)
    {
        if (toRemove == null) return 0;
        int count = 0;
        var list = new List<CardUI>(toRemove);
        foreach (var cardUI in list)
        {
            if (cardUI != null && handCards.Contains(cardUI))
            {
                selectedCards.Remove(cardUI);
                handCards.Remove(cardUI);
                cardUI.OnCardClicked -= HandleCardClicked;
                Destroy(cardUI.gameObject);
                count++;
            }
        }

        RearrangeHand();
        SyncHeroHandCount();
        OnCardSelected?.Invoke(SelectedCard);
        OnSelectionChanged?.Invoke(new List<CardUI>(selectedCards));
        return count;
    }

    /// <summary>
    /// Xóa toàn bộ bài trên tay.
    /// </summary>
    public void ClearHand()
    {
        selectedCards.Clear();
        foreach (var c in handCards)
        {
            if (c != null) Destroy(c.gameObject);
        }
        handCards.Clear();
        SyncHeroHandCount();
        OnCardSelected?.Invoke(null);
        OnSelectionChanged?.Invoke(new List<CardUI>(selectedCards));
    }

    public void HighlightOnlyMatching(Predicate<CardModel> predicate)
    {
        foreach (var cardUI in handCards)
        {
            if (cardUI == null) continue;
            bool match = predicate != null && predicate(cardUI.Data);
            cardUI.SetDimmed(!match);
            cardUI.SetTutorialHighlight(match);
        }
    }

    public void ClearHighlights()
    {
        ResetAllCardsVisuals();
    }

    public void ResetAllCardsVisuals()
    {
        foreach (var cardUI in handCards)
        {
            if (cardUI == null) continue;
            cardUI.SetTutorialHighlight(false);
            cardUI.SetDimmed(false);
            cardUI.SetGlow(cardUI.IsSelected);
        }
    }

    public void SelectCard(CardUI cardUI)
    {
        if (cardUI == null)
        {
            ClearSelection();
            return;
        }

        if (isMultiSelectMode)
        {
            if (!selectedCards.Contains(cardUI))
            {
                if (maxSelectableCards > 0 && selectedCards.Count >= maxSelectableCards)
                {
                    return;
                }
                cardUI.SetSelected(true);
                selectedCards.Add(cardUI);
                AudioManager.Instance.PlayCardSelect();
            }
        }
        else
        {
            foreach (var c in selectedCards)
            {
                if (c != null && c != cardUI) c.SetSelected(false);
            }
            selectedCards.Clear();
            cardUI.SetSelected(true);
            selectedCards.Add(cardUI);
            AudioManager.Instance.PlayCardSelect();
        }

        OnCardSelected?.Invoke(SelectedCard);
        OnSelectionChanged?.Invoke(new List<CardUI>(selectedCards));
    }

    public void DeselectCard(CardUI cardUI)
    {
        if (cardUI == null) return;
        if (selectedCards.Contains(cardUI))
        {
            cardUI.SetSelected(false);
            selectedCards.Remove(cardUI);
            OnCardSelected?.Invoke(SelectedCard);
            OnSelectionChanged?.Invoke(new List<CardUI>(selectedCards));
        }
    }

    public void ClearSelection()
    {
        foreach (var c in selectedCards)
        {
            if (c != null) c.SetSelected(false);
        }
        selectedCards.Clear();
        OnCardSelected?.Invoke(null);
        OnSelectionChanged?.Invoke(new List<CardUI>(selectedCards));
    }

    /// <summary>
    /// Kỹ năng Tiến Thoái: Hoán chuyển toàn bộ Trảm <-> Đỡ trên tay.
    /// Giữ nguyên thuộc tính gốc (Trảm Lôi, Trảm Hỏa...) để khi chuyển ngược lại không bị mất.
    /// </summary>
    public int TransformSlashAndDodge()
    {
        return TransformSlashAndDodge(out _);
    }

    public int TransformSlashAndDodge(out string resultingName)
    {
        int count = 0;
        resultingName = "";
        foreach (var cardUI in handCards)
        {
            if (cardUI == null || cardUI.Data == null) continue;
            var d = cardUI.Data;
            if (d.category == CardCategory.Basic)
            {
                if (d.subType == CardSubType.AttackNormal || d.subType == CardSubType.AttackFire || d.subType == CardSubType.AttackThunder)
                {
                    // Nếu chưa có sao lưu gốc thì ghi nhớ thuộc tính gốc
                    if (d.originalSubType == null)
                    {
                        d.originalName = d.cardName;
                        d.originalSubType = d.subType;
                        d.originalDescription = d.description;
                        d.originalIconPath = d.iconPath;
                    }

                    if (d.originalSubType == CardSubType.Dodge)
                    {
                        // Khôi phục về lá Đỡ nguyên bản
                        d.cardName = d.originalName ?? "Đỡ";
                        d.subType = CardSubType.Dodge;
                        d.description = d.originalDescription ?? "Hóa giải hoàn toàn 1 đòn Trảm.";
                        d.iconPath = d.originalIconPath ?? "UI/icon_dodge";
                    }
                    else
                    {
                        // Biến Trảm thành Đỡ
                        d.cardName = "Đỡ";
                        d.subType = CardSubType.Dodge;
                        d.description = "Hóa giải hoàn toàn 1 đòn Trảm.";
                        d.iconPath = "UI/icon_dodge";
                    }

                    resultingName = d.cardName;
                    cardUI.RefreshVisuals();
                    StartCoroutine(AnimateCardTransform(cardUI.transform));
                    count++;
                }
                else if (d.subType == CardSubType.Dodge)
                {
                    if (d.originalSubType.HasValue && d.originalSubType.Value != CardSubType.Dodge)
                    {
                        // Khôi phục chính xác thuộc tính Trảm nguyên bản (Trảm Lôi, Trảm Hỏa, Trảm Thường...)
                        d.cardName = d.originalName ?? "Trảm Thường";
                        d.subType = d.originalSubType.Value;
                        d.description = d.originalDescription;
                        d.iconPath = d.originalIconPath ?? (d.subType == CardSubType.AttackThunder ? "UI/icon_slash_thunder" : d.subType == CardSubType.AttackFire ? "UI/icon_slash_fire" : "UI/icon_slash");
                    }
                    else
                    {
                        // Là lá Đỡ gốc -> ghi nhớ và chuyển sang Trảm Thường
                        if (d.originalSubType == null)
                        {
                            d.originalName = d.cardName;
                            d.originalSubType = d.subType;
                            d.originalDescription = d.description;
                            d.originalIconPath = d.iconPath;
                        }

                        d.cardName = "Trảm Thường";
                        d.subType = CardSubType.AttackNormal;
                        d.description = "Gây 1 sát thương cho mục tiêu trong tầm đánh.";
                        d.iconPath = "UI/icon_slash";
                    }

                    resultingName = d.cardName;
                    cardUI.RefreshVisuals();
                    StartCoroutine(AnimateCardTransform(cardUI.transform));
                    count++;
                }
            }
        }

        if (SelectedCard != null)
        {
            OnCardSelected?.Invoke(SelectedCard);
            OnSelectionChanged?.Invoke(new List<CardUI>(selectedCards));
        }

        // Đọc tên lá bài vừa chuyển hóa thành
        if (!string.IsNullOrEmpty(resultingName))
        {
            AudioManager.Instance.PlayCardVoice(resultingName);
        }

        return count;
    }

    /// <summary>
    /// Kỹ năng Chế Nỏ (Cao Lỗ): Chuyển hóa lá bài chất Bích (♠) trên tay thành [Nỏ Thần Kim Quy] (hoặc khôi phục về gốc).
    /// </summary>
    /// <param name="transformedIntoNoThan">true nếu vừa chuyển hóa thành Nỏ Thần, false nếu vừa khôi phục về lá gốc</param>
    /// <returns>Tên lá bài bị tác động hoặc null nếu không có lá chất Bích</returns>
    public string ToggleSpadeToNoThan(out bool transformedIntoNoThan)
    {
        transformedIntoNoThan = false;

        // 1. Ưu tiên lá bài đang được chọn nếu là chất Bích (hoặc là lá đã chuyển hóa)
        CardUI targetCardUI = null;
        if (SelectedCard != null && SelectedCard.Data != null)
        {
            var d = SelectedCard.Data;
            if (d.suit == CardSuit.Spade || d.originalSubType.HasValue || d.originalCategory.HasValue)
            {
                targetCardUI = SelectedCard;
            }
        }

        // 2. Nếu chưa chọn lá nào hợp lệ, tìm lá chất Bích đầu tiên (ưu tiên lá đã chuyển hóa để toggle ngược lại, hoặc lá chưa chuyển hóa)
        if (targetCardUI == null)
        {
            targetCardUI = handCards.Find(c => c != null && c.Data != null && (c.Data.originalSubType.HasValue || c.Data.originalCategory.HasValue));
            if (targetCardUI == null)
            {
                targetCardUI = handCards.Find(c => c != null && c.Data != null && c.Data.suit == CardSuit.Spade);
            }
        }

        if (targetCardUI == null || targetCardUI.Data == null) return null;

        var card = targetCardUI.Data;
        string resultName;

        // Nếu lá này đang ở trạng thái chuyển hóa Nỏ Thần -> Khôi phục về lá gốc
        if (card.originalCategory.HasValue || card.originalSubType.HasValue)
        {
            card.ResetTransientTransformation();
            transformedIntoNoThan = false;
            resultName = card.cardName;
        }
        else
        {
            // Chuyển hóa sang Nỏ Thần Kim Quy
            card.originalName = card.cardName;
            card.originalCategory = card.category;
            card.originalSubType = card.subType;
            card.originalAttackRange = card.attackRange;
            card.originalDescription = card.description;
            card.originalIconPath = card.iconPath;

            card.cardName = "Nỏ Thần Kim Quy";
            card.category = CardCategory.Equipment;
            card.subType = CardSubType.Weapon;
            card.attackRange = 1;
            card.description = "Tầm 1. Giúp người chơi bỏ giới hạn lượt: Có thể ra không giới hạn số lá Trảm trong cùng một Giai đoạn Ra bài.";
            card.iconPath = "UI/icon_weapon";

            transformedIntoNoThan = true;
            resultName = card.cardName;
        }

        targetCardUI.RefreshVisuals();
        StartCoroutine(AnimateCardTransform(targetCardUI.transform));

        if (SelectedCard != null)
        {
            OnCardSelected?.Invoke(SelectedCard);
            OnSelectionChanged?.Invoke(new List<CardUI>(selectedCards));
        }

        // Đọc tên lá bài vừa chuyển hóa thành
        if (!string.IsNullOrEmpty(resultName))
        {
            AudioManager.Instance.PlayCardVoice(resultName);
        }

        return resultName;
    }

    private System.Collections.IEnumerator AnimateCardTransform(Transform target)
    {
        if (target == null) yield break;
        Vector3 orig = target.localScale;
        float elapsed = 0f;
        while (elapsed < 0.15f)
        {
            elapsed += Time.deltaTime;
            float s = Mathf.Sin((elapsed / 0.15f) * Mathf.PI);
            target.localScale = orig * (1f + s * 0.25f);
            yield return null;
        }
        if (target != null) target.localScale = orig;
    }

    private void HandleCardClicked(CardUI cardUI)
    {
        if (cardUI == null) return;

        if (isMultiSelectMode)
        {
            if (selectedCards.Contains(cardUI))
            {
                DeselectCard(cardUI);
            }
            else
            {
                SelectCard(cardUI);
            }
        }
        else
        {
            if (selectedCards.Contains(cardUI))
            {
                ClearSelection();
            }
            else
            {
                SelectCard(cardUI);
            }
        }
    }

    /// <summary>
    /// Sắp xếp lại vị trí các lá bài trên tay theo hàng ngang cân đối.
    /// </summary>
    public void RearrangeHand()
    {
        int count = handCards.Count;
        if (count == 0) return;

        // Tự động thu nhỏ khoảng cách nếu có quá nhiều bài trên tay
        float effectiveSpacing = cardSpacing;
        float maxAvailableWidth = 720f;
        if ((count - 1) * effectiveSpacing > maxAvailableWidth)
        {
            effectiveSpacing = maxAvailableWidth / Mathf.Max(1, count - 1);
        }

        float totalWidth = (count - 1) * effectiveSpacing;
        float startX = -totalWidth / 2f;

        for (int i = 0; i < count; i++)
        {
            float posX = startX + i * effectiveSpacing;
            handCards[i].SetBasePosition(new Vector2(posX, 0));
        }
    }

    private void SyncHeroHandCount()
    {
        if (boundHeroCard != null)
        {
            boundHeroCard.SetHandCardCount(handCards.Count);
        }
    }
}
