using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Quản lý hiển thị máu theo từng cục hoa sen (Lotus Health Units).
/// Khi còn máu: hoa sen sáng màu (lotus_full).
/// Khi mất máu: hoa sen tối màu (lotus_empty).
/// </summary>
[RequireComponent(typeof(RectTransform))]
public class LotusHealthUI : MonoBehaviour
{
    [Header("Settings")]
    [SerializeField] private int maxHp = 4;
    [SerializeField] private int currentHp = 4;
    [SerializeField] private Vector2 lotusSize = new Vector2(28, 28);
    [SerializeField] private float spacing = 4f;
    [SerializeField] private bool vertical = true;

    [Header("Lotus Sprites")]
    [SerializeField] private Sprite lotusFullSprite;
    [SerializeField] private Sprite lotusEmptySprite;

    private readonly List<Image> lotusNodes = new List<Image>();
    private RectTransform rectTransform;

    public int MaxHp => maxHp;
    public int CurrentHp => currentHp;

    private void Awake()
    {
        rectTransform = GetComponent<RectTransform>();
        LoadSpritesIfNull();
    }

    private void LoadSpritesIfNull()
    {
        if (lotusFullSprite == null)
            lotusFullSprite = LoadSpriteFromResources("UI/lotus_full");

        if (lotusEmptySprite == null)
            lotusEmptySprite = LoadSpriteFromResources("UI/lotus_empty");
    }

    public static Sprite LoadSpriteFromResources(string path)
    {
        if (string.IsNullOrEmpty(path)) return null;

        var sprite = Resources.Load<Sprite>(path);
        if (sprite != null) return sprite;

        var tex = Resources.Load<Texture2D>(path);
        if (tex != null)
        {
            return Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), new Vector2(0.5f, 0.5f), 100f);
        }

        return null;
    }

    public void Setup(int current, int max)
    {
        maxHp = Mathf.Max(1, max);
        currentHp = Mathf.Clamp(current, 0, maxHp);
        RefreshLayout();
    }

    public void SetCurrentHp(int current)
    {
        currentHp = Mathf.Clamp(current, 0, maxHp);
        UpdateLotusVisuals();
    }

    public void SetMaxHp(int max)
    {
        maxHp = Mathf.Max(1, max);
        currentHp = Mathf.Clamp(currentHp, 0, maxHp);
        RefreshLayout();
    }

    public void TakeDamage(int amount = 1)
    {
        SetCurrentHp(currentHp - amount);
    }

    public void Heal(int amount = 1)
    {
        SetCurrentHp(currentHp + amount);
    }

    public void RefreshLayout()
    {
        LoadSpritesIfNull();

        // Xóa các node cũ nếu thừa
        while (lotusNodes.Count > maxHp)
        {
            var last = lotusNodes[lotusNodes.Count - 1];
            lotusNodes.RemoveAt(lotusNodes.Count - 1);
            if (last != null) Destroy(last.gameObject);
        }

        // Tạo thêm node nếu thiếu
        while (lotusNodes.Count < maxHp)
        {
            var nodeGo = new GameObject("Lotus_" + lotusNodes.Count, typeof(RectTransform), typeof(Image));
            nodeGo.transform.SetParent(transform, false);
            var img = nodeGo.GetComponent<Image>();
            img.raycastTarget = false;
            img.preserveAspect = true;
            lotusNodes.Add(img);
        }

        // Cập nhật vị trí từng node
        for (int i = 0; i < maxHp; i++)
        {
            var rt = lotusNodes[i].rectTransform;
            rt.sizeDelta = lotusSize;

            if (vertical)
            {
                // Xếp từ trên xuống dưới
                rt.anchorMin = new Vector2(0.5f, 1f);
                rt.anchorMax = new Vector2(0.5f, 1f);
                rt.pivot = new Vector2(0.5f, 1f);
                float yOffset = -i * (lotusSize.y + spacing);
                rt.anchoredPosition = new Vector2(0, yOffset);
            }
            else
            {
                // Xếp từ trái qua phải
                rt.anchorMin = new Vector2(0f, 0.5f);
                rt.anchorMax = new Vector2(0f, 0.5f);
                rt.pivot = new Vector2(0f, 0.5f);
                float xOffset = i * (lotusSize.x + spacing);
                rt.anchoredPosition = new Vector2(xOffset, 0);
            }
        }

        // Cập nhật kích thước tổng của container
        if (rectTransform != null)
        {
            if (vertical)
            {
                float totalHeight = maxHp * lotusSize.y + Mathf.Max(0, maxHp - 1) * spacing;
                rectTransform.sizeDelta = new Vector2(lotusSize.x, totalHeight);
            }
            else
            {
                float totalWidth = maxHp * lotusSize.x + Mathf.Max(0, maxHp - 1) * spacing;
                rectTransform.sizeDelta = new Vector2(totalWidth, lotusSize.y);
            }
        }

        UpdateLotusVisuals();
    }

    private void UpdateLotusVisuals()
    {
        for (int i = 0; i < lotusNodes.Count; i++)
        {
            var img = lotusNodes[i];
            if (img == null) continue;

            bool isActive = i < currentHp;
            if (isActive)
            {
                img.sprite = lotusFullSprite;
                img.color = Color.white;
            }
            else
            {
                img.sprite = lotusEmptySprite;
                img.color = new Color(0.65f, 0.65f, 0.65f, 0.9f);
            }
        }
    }

    private void OnValidate()
    {
        if (Application.isPlaying && lotusNodes.Count > 0)
        {
            RefreshLayout();
        }
    }
}
