using System;
using UnityEngine;

public enum EquipmentType
{
    Weapon,          // Vũ khí
    Armor,           // Giáp
    OffensiveMount,  // Ngựa công (-1 khoảng cách tới mục tiêu)
    DefensiveMount,  // Ngựa thủ (+1 khoảng cách bị nhắm tới)
    Treasure         // Bảo vật
}

[CreateAssetMenu(fileName = "NewGeneralData", menuName = "Đại Việt Chiến/General Data")]
public class GeneralData : ScriptableObject
{
    [Header("General Identity")]
    public string generalName = "Lý Thường Kiệt";
    public string faction = "Khác";
    public Sprite avatarSprite;
    public Texture2D avatarTexture;

    [Header("Health Attributes")]
    [Range(1, 10)] public int maxHp = 4;
    [Range(0, 10)] public int currentHp = 4;

    [Header("Hand Cards")]
    [Range(0, 20)] public int handCardCount = 4;

    [Header("Default Equipments (Optional)")]
    public string initialWeapon;
    public string initialArmor;
    public string initialOffensiveMount;
    public string initialDefensiveMount;
    public string initialTreasure;
}
