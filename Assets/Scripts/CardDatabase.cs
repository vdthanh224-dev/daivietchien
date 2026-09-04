using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Kho Dữ Liệu Bộ Bài Đại Việt Chiến Chuẩn Hóa Theo ĐẶC TẢ CẤU TRÚC BỘ BÀI 2v2 (80 Lá) & 8 NGƯỜI (150 Lá)
/// </summary>
public static class CardDatabase
{
    public static List<CardModel> CreateDeck(int deckMode = 80)
    {
        if (deckMode >= 150) return CreateDeck150();
        if (deckMode <= 60) return CreateDeck80().GetRange(0, 60);
        if (deckMode == 80) return CreateDeck80();
        if (deckMode == 100)
        {
            var d80 = CreateDeck80();
            var extra = CreateDeck150().GetRange(80, 20);
            d80.AddRange(extra);
            return d80;
        }
        if (deckMode == 125)
        {
            var d80 = CreateDeck80();
            var extra = CreateDeck150().GetRange(80, 45);
            d80.AddRange(extra);
            return d80;
        }
        return CreateDeck80();
    }

    #region BỘ BÀI 80 LÁ (Chế Độ Song Hùng 2v2)
    public static List<CardModel> CreateDeck80()
    {
        var list = new List<CardModel>();

        // ==========================================
        // 1. TRẢM THƯỜNG — 22 LÁ (11 Đen, 11 Đỏ)
        // ==========================================
        // Đen 11 lá
        list.Add(CreateCard("D80_TN_S2", "Trảm Thường", CardSuit.Spade, CardRank.Two, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_S3", "Trảm Thường", CardSuit.Spade, CardRank.Three, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_S4", "Trảm Thường", CardSuit.Spade, CardRank.Four, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_S5", "Trảm Thường", CardSuit.Spade, CardRank.Five, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_S6", "Trảm Thường", CardSuit.Spade, CardRank.Six, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_S7", "Trảm Thường", CardSuit.Spade, CardRank.Seven, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_C8", "Trảm Thường", CardSuit.Club, CardRank.Eight, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_C9", "Trảm Thường", CardSuit.Club, CardRank.Nine, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_C10", "Trảm Thường", CardSuit.Club, CardRank.Ten, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_CJ", "Trảm Thường", CardSuit.Club, CardRank.Jack, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_CQ", "Trảm Thường", CardSuit.Club, CardRank.Queen, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));

        // Đỏ 11 lá
        list.Add(CreateCard("D80_TN_D2", "Trảm Thường", CardSuit.Diamond, CardRank.Two, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_D3", "Trảm Thường", CardSuit.Diamond, CardRank.Three, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_D4", "Trảm Thường", CardSuit.Diamond, CardRank.Four, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_D5", "Trảm Thường", CardSuit.Diamond, CardRank.Five, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_D6", "Trảm Thường", CardSuit.Diamond, CardRank.Six, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_H7", "Trảm Thường", CardSuit.Heart, CardRank.Seven, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_H8", "Trảm Thường", CardSuit.Heart, CardRank.Eight, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_H9", "Trảm Thường", CardSuit.Heart, CardRank.Nine, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_D10", "Trảm Thường", CardSuit.Diamond, CardRank.Ten, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_HJ", "Trảm Thường", CardSuit.Heart, CardRank.Jack, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));
        list.Add(CreateCard("D80_TN_HQ", "Trảm Thường", CardSuit.Heart, CardRank.Queen, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));

        // ==========================================
        // 2. TRẢM - LÔI — 6 LÁ (Toàn bộ Đen)
        // ==========================================
        list.Add(CreateCard("D80_TL_S8", "Trảm - Lôi", CardSuit.Spade, CardRank.Eight, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương thuộc tính Lôi.", "UI/cards/card_slash_thunder"));
        list.Add(CreateCard("D80_TL_S9", "Trảm - Lôi", CardSuit.Spade, CardRank.Nine, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương thuộc tính Lôi.", "UI/cards/card_slash_thunder"));
        list.Add(CreateCard("D80_TL_C10", "Trảm - Lôi", CardSuit.Club, CardRank.Ten, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương thuộc tính Lôi.", "UI/cards/card_slash_thunder"));
        list.Add(CreateCard("D80_TL_CJ", "Trảm - Lôi", CardSuit.Club, CardRank.Jack, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương thuộc tính Lôi.", "UI/cards/card_slash_thunder"));
        list.Add(CreateCard("D80_TL_SK", "Trảm - Lôi", CardSuit.Spade, CardRank.King, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương thuộc tính Lôi.", "UI/cards/card_slash_thunder"));
        list.Add(CreateCard("D80_TL_CA", "Trảm - Lôi", CardSuit.Club, CardRank.Ace, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương thuộc tính Lôi.", "UI/cards/card_slash_thunder"));

        // ==========================================
        // 3. TRẢM - HỎA — 6 LÁ (Toàn bộ Đỏ)
        // ==========================================
        list.Add(CreateCard("D80_TH_D8", "Trảm - Hỏa", CardSuit.Diamond, CardRank.Eight, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn.", "UI/cards/card_slash_fire"));
        list.Add(CreateCard("D80_TH_D9", "Trảm - Hỏa", CardSuit.Diamond, CardRank.Nine, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn.", "UI/cards/card_slash_fire"));
        list.Add(CreateCard("D80_TH_H10", "Trảm - Hỏa", CardSuit.Heart, CardRank.Ten, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn.", "UI/cards/card_slash_fire"));
        list.Add(CreateCard("D80_TH_DJ", "Trảm - Hỏa", CardSuit.Diamond, CardRank.Jack, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn.", "UI/cards/card_slash_fire"));
        list.Add(CreateCard("D80_TH_HQ", "Trảm - Hỏa", CardSuit.Heart, CardRank.Queen, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn.", "UI/cards/card_slash_fire"));
        list.Add(CreateCard("D80_TH_HA", "Trảm - Hỏa", CardSuit.Heart, CardRank.Ace, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn.", "UI/cards/card_slash_fire"));

        // ==========================================
        // 4. ĐỠ — 14 LÁ (Toàn bộ Đỏ)
        // ==========================================
        list.Add(CreateCard("D80_DO_D2", "Đỡ", CardSuit.Diamond, CardRank.Two, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_H3", "Đỡ", CardSuit.Heart, CardRank.Three, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_D4", "Đỡ", CardSuit.Diamond, CardRank.Four, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_H5", "Đỡ", CardSuit.Heart, CardRank.Five, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_D6", "Đỡ", CardSuit.Diamond, CardRank.Six, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_H7", "Đỡ", CardSuit.Heart, CardRank.Seven, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_D8", "Đỡ", CardSuit.Diamond, CardRank.Eight, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_H9", "Đỡ", CardSuit.Heart, CardRank.Nine, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_D10", "Đỡ", CardSuit.Diamond, CardRank.Ten, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_HJ", "Đỡ", CardSuit.Heart, CardRank.Jack, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_DQ", "Đỡ", CardSuit.Diamond, CardRank.Queen, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_HQ", "Đỡ", CardSuit.Heart, CardRank.Queen, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_DK", "Đỡ", CardSuit.Diamond, CardRank.King, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        list.Add(CreateCard("D80_DO_HK", "Đỡ", CardSuit.Heart, CardRank.King, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));

        // ==========================================
        // 5. BÁNH CHƯNG — 6 LÁ (Toàn bộ Cơ ♥)
        // ==========================================
        list.Add(CreateCard("D80_BC_H2", "Bánh Chưng", CardSuit.Heart, CardRank.Two, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu hoặc cứu Cận Tử.", "UI/cards/card_banh_chung"));
        list.Add(CreateCard("D80_BC_H4", "Bánh Chưng", CardSuit.Heart, CardRank.Four, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu hoặc cứu Cận Tử.", "UI/cards/card_banh_chung"));
        list.Add(CreateCard("D80_BC_H6", "Bánh Chưng", CardSuit.Heart, CardRank.Six, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu hoặc cứu Cận Tử.", "UI/cards/card_banh_chung"));
        list.Add(CreateCard("D80_BC_H8", "Bánh Chưng", CardSuit.Heart, CardRank.Eight, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu hoặc cứu Cận Tử.", "UI/cards/card_banh_chung"));
        list.Add(CreateCard("D80_BC_H10", "Bánh Chưng", CardSuit.Heart, CardRank.Ten, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu hoặc cứu Cận Tử.", "UI/cards/card_banh_chung"));
        list.Add(CreateCard("D80_BC_HK", "Bánh Chưng", CardSuit.Heart, CardRank.King, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu hoặc cứu Cận Tử.", "UI/cards/card_banh_chung"));

        // ==========================================
        // 6. HỦ RƯỢU — 4 LÁ
        // ==========================================
        list.Add(CreateCard("D80_HR_C7", "Hủ Rượu", CardSuit.Club, CardRank.Seven, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước khi Trảm (+1 sát thương) HOẶC tự cứu khi 0 máu.", "UI/cards/card_wine"));
        list.Add(CreateCard("D80_HR_D7", "Hủ Rượu", CardSuit.Diamond, CardRank.Seven, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước khi Trảm (+1 sát thương) HOẶC tự cứu khi 0 máu.", "UI/cards/card_wine"));
        list.Add(CreateCard("D80_HR_SQ", "Hủ Rượu", CardSuit.Spade, CardRank.Queen, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước khi Trảm (+1 sát thương) HOẶC tự cứu khi 0 máu.", "UI/cards/card_wine"));
        list.Add(CreateCard("D80_HR_HJ", "Hủ Rượu", CardSuit.Heart, CardRank.Jack, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước khi Trảm (+1 sát thương) HOẶC tự cứu khi 0 máu.", "UI/cards/card_wine"));

        // ==========================================
        // 7. XÍCH TÂM TỎA — 2 LÁ (Toàn bộ Đen)
        // ==========================================
        list.Add(CreateCard("D80_XT_SK", "Xích Tâm Tỏa", CardSuit.Spade, CardRank.King, 1, CardCategory.InstantScroll, CardSubType.IronChain, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn. Sát thương Hỏa/Lôi sẽ truyền qua xích!", "UI/cards/card_iron_chain"));
        list.Add(CreateCard("D80_XT_CA", "Xích Tâm Tỏa", CardSuit.Club, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.IronChain, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn. Sát thương Hỏa/Lôi sẽ truyền qua xích!", "UI/cards/card_iron_chain"));

        // ==========================================
        // 8. VŨ KHÍ — 7 LÁ
        // ==========================================
        list.Add(CreateCard("D80_VK_DA_ThuanThien", "Kiếm Thuận Thiên", CardSuit.Diamond, CardRank.Ace, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 2. Trảm bỏ qua Trang bị Giáp của mục tiêu.", "UI/cards/card_weapon_thuan_thien", 2));
        list.Add(CreateCard("D80_VK_HK_SongCung", "Song Cung Mường Nhạ", CardSuit.Heart, CardRank.King, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 2. Khi Trảm bị Đỡ, có thể bỏ 2 bài ép chịu 1 sát thương.", "UI/cards/card_weapon_song_cung", 2));
        list.Add(CreateCard("D80_VK_SK_SongCung", "Song Cung Mường Nhạ", CardSuit.Spade, CardRank.King, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 2. Khi Trảm bị Đỡ, có thể bỏ 2 bài ép chịu 1 sát thương.", "UI/cards/card_weapon_song_cung", 2));
        list.Add(CreateCard("D80_VK_CQ_NoThan", "Nỏ Thần Kim Quy", CardSuit.Club, CardRank.Queen, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 3. Không giới hạn số lá Trảm đánh ra trong lượt.", "UI/cards/card_weapon_no_than", 3));
        list.Add(CreateCard("D80_VK_CJ_TruongDao", "Trường Đao Nam Sơn", CardSuit.Club, CardRank.Jack, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 3. Khi Trảm bị Đỡ, có thể bỏ thêm 1 Trảm ép Đỡ lần nữa.", "UI/cards/card_weapon_truong_dao", 3));
        list.Add(CreateCard("D80_VK_DQ_ThuongNgau", "Thương Ngâu Lãng Bạc", CardSuit.Diamond, CardRank.Queen, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 4. Khi Trảm trúng, hủy 1 lá trên tay hoặc trang bị.", "UI/cards/card_weapon_thuan_thien", 4));
        list.Add(CreateCard("D80_VK_SA_SungThanCong", "Súng Thần Công Hồ Triều", CardSuit.Spade, CardRank.Ace, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 5. Mục tiêu không được dùng Đỡ cùng chất với Trảm.", "UI/cards/card_weapon_no_than", 5));

        // ==========================================
        // 9. ÁO GIÁP — 3 LÁ
        // ==========================================
        list.Add(CreateCard("D80_AG_CK_GiapDong", "Giáp Đồng Sơn Vi", CardSuit.Club, CardRank.King, 1, CardCategory.Equipment, CardSubType.Armor, "Vô hiệu hóa toàn bộ Trảm Thường.", "UI/cards/card_armor_giap_dong"));
        list.Add(CreateCard("D80_AG_DK_KhienMay", "Khiên Mây Bện", CardSuit.Diamond, CardRank.King, 1, CardCategory.Equipment, CardSubType.Armor, "Khi cần Đỡ, lật phán xét: chất Đỏ tự động Đỡ.", "UI/cards/card_armor_khien_may"));
        list.Add(CreateCard("D80_AG_HA_AoBao", "Áo Bào Hoàng Tộc", CardSuit.Heart, CardRank.Ace, 1, CardCategory.Equipment, CardSubType.Armor, "Tất cả sát thương nhận vào giảm 1 (tối đa 3 lần).", "UI/cards/card_armor_ao_bao"));

        // ==========================================
        // 10. CHIẾN MÃ — 4 LÁ
        // ==========================================
        list.Add(CreateCard("D80_CM_HK_VoiChien", "Voi Chiến Đại Việt", CardSuit.Heart, CardRank.King, 1, CardCategory.Equipment, CardSubType.DefensiveHorse, "Tăng +1 khoảng cách từ người khác tới bạn (Ngựa thủ).", "UI/cards/card_mount_voi_chien", 1, 1));
        list.Add(CreateCard("D80_CM_CK_VoiChien", "Voi Chiến Đại Việt", CardSuit.Club, CardRank.King, 1, CardCategory.Equipment, CardSubType.DefensiveHorse, "Tăng +1 khoảng cách từ người khác tới bạn (Ngựa thủ).", "UI/cards/card_mount_voi_chien", 1, 1));
        list.Add(CreateCard("D80_CM_SJ_NguaTrang", "Ngựa Trắng Thuần Nông", CardSuit.Spade, CardRank.Jack, 1, CardCategory.Equipment, CardSubType.OffensiveHorse, "Giảm -1 khoảng cách từ bạn tới tất cả người khác (Ngựa công).", "UI/cards/card_mount_ngua_trang", 1, -1));
        list.Add(CreateCard("D80_CM_DJ_NguaTrang", "Ngựa Trắng Thuần Nông", CardSuit.Diamond, CardRank.Jack, 1, CardCategory.Equipment, CardSubType.OffensiveHorse, "Giảm -1 khoảng cách từ bạn tới tất cả người khác (Ngựa công).", "UI/cards/card_mount_ngua_trang", 1, -1));

        // ==========================================
        // 11. CẨM NANG TỨC THỜI — 3 LÁ
        // ==========================================
        list.Add(CreateCard("D80_CN_HA_DieuKe", "Diệu Kế Phá Mưu", CardSuit.Heart, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.FlawlessDefense, "Vô hiệu hóa 1 Cẩm Nang bất kỳ HOẶC hủy 1 lá trên tay/bàn.", "UI/cards/card_flawless"));
        list.Add(CreateCard("D80_CN_CQ_VuonKhong", "Vườn Không Nhà Trống", CardSuit.Club, CardRank.Queen, 1, CardCategory.InstantScroll, CardSubType.Dismantle, "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 lá trang bị của họ.", "UI/cards/card_dismantle"));
        list.Add(CreateCard("D80_CN_SK_DotKich", "Đột Kích Trộm Lương", CardSuit.Spade, CardRank.King, 1, CardCategory.InstantScroll, CardSubType.Snatch, "Cướp 1 lá bài trên tay hoặc trang bị của mục tiêu cự ly 1.", "UI/cards/card_snatch"));

        // ==========================================
        // 12. CẨM NANG TRÌ HOÃN — 3 LÁ
        // ==========================================
        list.Add(CreateCard("D80_TH_CA_SamSet", "Thần Sấm Báo Ứng", CardSuit.Club, CardRank.Ace, 1, CardCategory.DelayedScroll, CardSubType.Lightning, "Gài vùng phán xét. Bích 2-9 chịu 3 sát thương Lôi.", "UI/cards/card_lightning"));
        list.Add(CreateCard("D80_TH_DQ_CatLuong", "Cắt Đường Lương", CardSuit.Diamond, CardRank.Queen, 1, CardCategory.DelayedScroll, CardSubType.SupplyShortage, "Gài mục tiêu. Phán xét không phải Chuồn -> Mất lượt rút bài.", "UI/cards/card_supply_shortage"));
        list.Add(CreateCard("D80_TH_HK_TramAo", "Trầm Ảo Sa Bẫy", CardSuit.Heart, CardRank.King, 1, CardCategory.DelayedScroll, CardSubType.Acedia, "Trì hoãn mục tiêu. Phán xét không phải Cơ -> Bỏ qua Ra bài.", "UI/cards/card_acedia"));

        return list;
    }
    #endregion

    #region BỘ BÀI 150 LÁ (Chế Độ Đại Chiến 8 Người / Quốc Chiến)
    public static List<CardModel> CreateDeck150()
    {
        var list = new List<CardModel>();

        // 1. Trảm Thường — 42 lá (21 Đen, 21 Đỏ)
        int[] spadeRanks = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 };
        foreach (int r in spadeRanks)
            list.Add(CreateCard($"D150_TN_S{r}", "Trảm Thường", CardSuit.Spade, (CardRank)r, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));

        int[] clubRanks = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 };
        foreach (int r in clubRanks)
            list.Add(CreateCard($"D150_TN_C{r}", "Trảm Thường", CardSuit.Club, (CardRank)r, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));

        int[] diaRanks = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 };
        foreach (int r in diaRanks)
            list.Add(CreateCard($"D150_TN_D{r}", "Trảm Thường", CardSuit.Diamond, (CardRank)r, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));

        int[] heartRanks = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 };
        foreach (int r in heartRanks)
            list.Add(CreateCard($"D150_TN_H{r}", "Trảm Thường", CardSuit.Heart, (CardRank)r, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương thường.", "UI/cards/card_slash"));

        // 2. Trảm - Lôi — 12 lá
        int[] loiRanks = { 8, 9, 10, 11, 12, 13 };
        foreach (int r in loiRanks)
        {
            list.Add(CreateCard($"D150_TL_S{r}", "Trảm - Lôi", CardSuit.Spade, (CardRank)r, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương Lôi.", "UI/cards/card_slash_thunder"));
            list.Add(CreateCard($"D150_TL_C{r}", "Trảm - Lôi", CardSuit.Club, (CardRank)r, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương Lôi.", "UI/cards/card_slash_thunder"));
        }

        // 3. Trảm - Hỏa — 12 lá
        int[] hoaRanks = { 8, 9, 10, 11, 12, 13 };
        foreach (int r in hoaRanks)
        {
            list.Add(CreateCard($"D150_TH_D{r}", "Trảm - Hỏa", CardSuit.Diamond, (CardRank)r, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công gây 1 sát thương Hỏa.", "UI/cards/card_slash_fire"));
            list.Add(CreateCard($"D150_TH_H{r}", "Trảm - Hỏa", CardSuit.Heart, (CardRank)r, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công gây 1 sát thương Hỏa.", "UI/cards/card_slash_fire"));
        }

        // 4. Đỡ — 26 lá
        for (int r = 1; r <= 13; r++)
        {
            list.Add(CreateCard($"D150_DO_D{r}", "Đỡ", CardSuit.Diamond, (CardRank)r, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
            list.Add(CreateCard($"D150_DO_H{r}", "Đỡ", CardSuit.Heart, (CardRank)r, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm.", "UI/cards/card_dodge"));
        }

        // 5. Bánh Chưng — 12 lá
        for (int r = 2; r <= 13; r++)
        {
            list.Add(CreateCard($"D150_BC_H{r}", "Bánh Chưng", CardSuit.Heart, (CardRank)r, 1, CardCategory.Basic, CardSubType.Peach, "Hồi 1 Máu hoặc cứu Cận Tử.", "UI/cards/card_banh_chung"));
        }

        // 6. Hủ Rượu — 7 lá
        list.Add(CreateCard("D150_HR_CJ", "Hủ Rượu", CardSuit.Club, CardRank.Jack, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước Trảm (+1 ST) hoặc tự cứu khi 0 máu.", "UI/cards/card_wine"));
        list.Add(CreateCard("D150_HR_DJ", "Hủ Rượu", CardSuit.Diamond, CardRank.Jack, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước Trảm (+1 ST) hoặc tự cứu khi 0 máu.", "UI/cards/card_wine"));
        list.Add(CreateCard("D150_HR_SQ", "Hủ Rượu", CardSuit.Spade, CardRank.Queen, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước Trảm (+1 ST) hoặc tự cứu khi 0 máu.", "UI/cards/card_wine"));
        list.Add(CreateCard("D150_HR_CQ", "Hủ Rượu", CardSuit.Club, CardRank.Queen, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước Trảm (+1 ST) hoặc tự cứu khi 0 máu.", "UI/cards/card_wine"));
        list.Add(CreateCard("D150_HR_DK", "Hủ Rượu", CardSuit.Diamond, CardRank.King, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước Trảm (+1 ST) hoặc tự cứu khi 0 máu.", "UI/cards/card_wine"));
        list.Add(CreateCard("D150_HR_SK", "Hủ Rượu", CardSuit.Spade, CardRank.King, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước Trảm (+1 ST) hoặc tự cứu khi 0 máu.", "UI/cards/card_wine"));
        list.Add(CreateCard("D150_HR_HA", "Hủ Rượu", CardSuit.Heart, CardRank.Ace, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước Trảm (+1 ST) hoặc tự cứu khi 0 máu.", "UI/cards/card_wine"));

        // 7. Xích Tâm Tỏa — 4 lá
        list.Add(CreateCard("D150_XT_SQ", "Xích Tâm Tỏa", CardSuit.Spade, CardRank.Queen, 1, CardCategory.InstantScroll, CardSubType.IronChain, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích.", "UI/cards/card_iron_chain"));
        list.Add(CreateCard("D150_XT_CQ", "Xích Tâm Tỏa", CardSuit.Club, CardRank.Queen, 1, CardCategory.InstantScroll, CardSubType.IronChain, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích.", "UI/cards/card_iron_chain"));
        list.Add(CreateCard("D150_XT_SK", "Xích Tâm Tỏa", CardSuit.Spade, CardRank.King, 1, CardCategory.InstantScroll, CardSubType.IronChain, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích.", "UI/cards/card_iron_chain"));
        list.Add(CreateCard("D150_XT_CA", "Xích Tâm Tỏa", CardSuit.Club, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.IronChain, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích.", "UI/cards/card_iron_chain"));

        // 8. Vũ Khí — 12 lá
        list.Add(CreateCard("D150_VK_DA_ThuanThien", "Kiếm Thuận Thiên", CardSuit.Diamond, CardRank.Ace, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 2. Trảm bỏ qua Trang bị Giáp.", "UI/cards/card_weapon_thuan_thien", 2));
        list.Add(CreateCard("D150_VK_D2_ThuanThien", "Kiếm Thuận Thiên", CardSuit.Diamond, CardRank.Two, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 2. Trảm bỏ qua Trang bị Giáp.", "UI/cards/card_weapon_thuan_thien", 2));
        list.Add(CreateCard("D150_VK_HK_SongCung", "Song Cung Mường Nhạ", CardSuit.Heart, CardRank.King, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 2. Trảm bị Đỡ: bỏ 2 lá ép chịu 1 ST.", "UI/cards/card_weapon_song_cung", 2));
        list.Add(CreateCard("D150_VK_SK_SongCung", "Song Cung Mường Nhạ", CardSuit.Spade, CardRank.King, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 2. Trảm bị Đỡ: bỏ 2 lá ép chịu 1 ST.", "UI/cards/card_weapon_song_cung", 2));
        list.Add(CreateCard("D150_VK_CQ_NoThan", "Nỏ Thần Kim Quy", CardSuit.Club, CardRank.Queen, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 3. Không giới hạn số Trảm.", "UI/cards/card_weapon_no_than", 3));
        list.Add(CreateCard("D150_VK_SA_NoThan", "Nỏ Thần Kim Quy", CardSuit.Spade, CardRank.Ace, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 3. Không giới hạn số Trảm.", "UI/cards/card_weapon_no_than", 3));
        list.Add(CreateCard("D150_VK_CJ_TruongDao", "Trường Đao Nam Sơn", CardSuit.Club, CardRank.Jack, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 3. Trảm bị Đỡ: bỏ thêm 1 Trảm ép dùng thêm 1 Đỡ.", "UI/cards/card_weapon_truong_dao", 3));
        list.Add(CreateCard("D150_VK_DQ_TruongDao", "Trường Đao Nam Sơn", CardSuit.Diamond, CardRank.Queen, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 3. Trảm bị Đỡ: bỏ thêm 1 Trảm ép dùng thêm 1 Đỡ.", "UI/cards/card_weapon_truong_dao", 3));
        list.Add(CreateCard("D150_VK_DQ_ThuongNgau", "Thương Ngâu Lãng Bạc", CardSuit.Diamond, CardRank.Queen, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 4. Trảm trúng: hủy 1 lá tay hoặc trang bị.", "UI/cards/card_weapon_thuan_thien", 4));
        list.Add(CreateCard("D150_VK_C5_ThuongNgau", "Thương Ngâu Lãng Bạc", CardSuit.Club, CardRank.Five, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 4. Trảm trúng: hủy 1 lá tay hoặc trang bị.", "UI/cards/card_weapon_thuan_thien", 4));
        list.Add(CreateCard("D150_VK_SA_SungThanCong", "Súng Thần Công Hồ Triều", CardSuit.Spade, CardRank.Ace, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 5. Mục tiêu không được dùng Đỡ cùng chất với Trảm.", "UI/cards/card_weapon_no_than", 5));
        list.Add(CreateCard("D150_VK_DA_SungThanCong", "Súng Thần Công Hồ Triều", CardSuit.Diamond, CardRank.Ace, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 5. Mục tiêu không được dùng Đỡ cùng chất với Trảm.", "UI/cards/card_weapon_no_than", 5));

        // 9. Áo Giáp — 6 lá
        list.Add(CreateCard("D150_AG_CK_GiapDong", "Giáp Đồng Sơn Vi", CardSuit.Club, CardRank.King, 1, CardCategory.Equipment, CardSubType.Armor, "Vô hiệu hóa toàn bộ Trảm Thường.", "UI/cards/card_armor_giap_dong"));
        list.Add(CreateCard("D150_AG_S2_GiapDong", "Giáp Đồng Sơn Vi", CardSuit.Spade, CardRank.Two, 1, CardCategory.Equipment, CardSubType.Armor, "Vô hiệu hóa toàn bộ Trảm Thường.", "UI/cards/card_armor_giap_dong"));
        list.Add(CreateCard("D150_AG_DK_KhienMay", "Khiên Mây Bện", CardSuit.Diamond, CardRank.King, 1, CardCategory.Equipment, CardSubType.Armor, "Bị Trảm: lật phán xét Đỏ tự động Đỡ, Đen thất bại.", "UI/cards/card_armor_khien_may"));
        list.Add(CreateCard("D150_AG_C2_KhienMay", "Khiên Mây Bện", CardSuit.Club, CardRank.Two, 1, CardCategory.Equipment, CardSubType.Armor, "Bị Trảm: lật phán xét Đỏ tự động Đỡ, Đen thất bại.", "UI/cards/card_armor_khien_may"));
        list.Add(CreateCard("D150_AG_HA_AoBao", "Áo Bào Hoàng Tộc", CardSuit.Heart, CardRank.Ace, 1, CardCategory.Equipment, CardSubType.Armor, "Giảm 1 sát thương nhận vào (tối đa 3 lần).", "UI/cards/card_armor_ao_bao"));
        list.Add(CreateCard("D150_AG_D3_AoBao", "Áo Bào Hoàng Tộc", CardSuit.Diamond, CardRank.Three, 1, CardCategory.Equipment, CardSubType.Armor, "Giảm 1 sát thương nhận vào (tối đa 3 lần).", "UI/cards/card_armor_ao_bao"));

        // 10. Chiến Mã — 7 lá
        list.Add(CreateCard("D150_CM_HK_VoiChien", "Voi Chiến Đại Việt", CardSuit.Heart, CardRank.King, 1, CardCategory.Equipment, CardSubType.DefensiveHorse, "Ngựa Thủ: +1 Khoảng cách từ người khác tới bạn.", "UI/cards/card_mount_voi_chien", 1, 1));
        list.Add(CreateCard("D150_CM_CK_VoiChien", "Voi Chiến Đại Việt", CardSuit.Club, CardRank.King, 1, CardCategory.Equipment, CardSubType.DefensiveHorse, "Ngựa Thủ: +1 Khoảng cách từ người khác tới bạn.", "UI/cards/card_mount_voi_chien", 1, 1));
        list.Add(CreateCard("D150_CM_DK_VoiChien", "Voi Chiến Đại Việt", CardSuit.Diamond, CardRank.King, 1, CardCategory.Equipment, CardSubType.DefensiveHorse, "Ngựa Thủ: +1 Khoảng cách từ người khác tới bạn.", "UI/cards/card_mount_voi_chien", 1, 1));
        list.Add(CreateCard("D150_CM_SJ_NguaTrang", "Ngựa Trắng Thuần Nông", CardSuit.Spade, CardRank.Jack, 1, CardCategory.Equipment, CardSubType.OffensiveHorse, "Ngựa Công: -1 Khoảng cách từ bạn tới tất cả người khác.", "UI/cards/card_mount_ngua_trang", 1, -1));
        list.Add(CreateCard("D150_CM_DJ_NguaTrang", "Ngựa Trắng Thuần Nông", CardSuit.Diamond, CardRank.Jack, 1, CardCategory.Equipment, CardSubType.OffensiveHorse, "Ngựa Công: -1 Khoảng cách từ bạn tới tất cả người khác.", "UI/cards/card_mount_ngua_trang", 1, -1));
        list.Add(CreateCard("D150_CM_CJ_NguaTrang", "Ngựa Trắng Thuần Nông", CardSuit.Club, CardRank.Jack, 1, CardCategory.Equipment, CardSubType.OffensiveHorse, "Ngựa Công: -1 Khoảng cách từ bạn tới tất cả người khác.", "UI/cards/card_mount_ngua_trang", 1, -1));
        list.Add(CreateCard("D150_CM_H5_NguaTrang", "Ngựa Trắng Thuần Nông", CardSuit.Heart, CardRank.Five, 1, CardCategory.Equipment, CardSubType.OffensiveHorse, "Ngựa Công: -1 Khoảng cách từ bạn tới tất cả người khác.", "UI/cards/card_mount_ngua_trang", 1, -1));

        // 11. Cẩm Nang Tức Thời — 6 lá
        list.Add(CreateCard("D150_CN_HA_DieuKe", "Diệu Kế Phá Mưu", CardSuit.Heart, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.FlawlessDefense, "Vô hiệu hóa 1 Cẩm Nang HOẶC hủy 1 lá trên tay/bàn.", "UI/cards/card_flawless"));
        list.Add(CreateCard("D150_CN_SA_DieuKe", "Diệu Kế Phá Mưu", CardSuit.Spade, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.FlawlessDefense, "Vô hiệu hóa 1 Cẩm Nang HOẶC hủy 1 lá trên tay/bàn.", "UI/cards/card_flawless"));
        list.Add(CreateCard("D150_CN_CQ_VuonKhong", "Vườn Không Nhà Trống", CardSuit.Club, CardRank.Queen, 1, CardCategory.InstantScroll, CardSubType.Dismantle, "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 trang bị.", "UI/cards/card_dismantle"));
        list.Add(CreateCard("D150_CN_S3_VuonKhong", "Vườn Không Nhà Trống", CardSuit.Spade, CardRank.Three, 1, CardCategory.InstantScroll, CardSubType.Dismantle, "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 trang bị.", "UI/cards/card_dismantle"));
        list.Add(CreateCard("D150_CN_SK_DotKich", "Đột Kích Trộm Lương", CardSuit.Spade, CardRank.King, 1, CardCategory.InstantScroll, CardSubType.Snatch, "Cướp 1 lá bài của mục tiêu cự ly 1.", "UI/cards/card_snatch"));
        list.Add(CreateCard("D150_CN_H3_DungBinh", "Dụng Binh Như Thần", CardSuit.Heart, CardRank.Three, 1, CardCategory.InstantScroll, CardSubType.ExNihilo, "Rút ngay 2 lá bài từ bộ bài.", "UI/cards/card_ex_nihilo"));

        // 12. Cẩm Nang Trì Hoãn — 4 lá
        list.Add(CreateCard("D150_TH_CA_SamSet", "Thần Sấm Báo Ứng", CardSuit.Club, CardRank.Ace, 1, CardCategory.DelayedScroll, CardSubType.Lightning, "Phán xét: Bích ♠ 2..9 chịu 3 sát thương Lôi, trượt chuyển tiếp.", "UI/cards/card_lightning"));
        list.Add(CreateCard("D150_TH_DQ_CatLuong", "Cắt Đường Lương", CardSuit.Diamond, CardRank.Queen, 1, CardCategory.DelayedScroll, CardSubType.SupplyShortage, "Phán xét: Không phải Chuồn ♣ -> bỏ qua Rút bài.", "UI/cards/card_supply_shortage"));
        list.Add(CreateCard("D150_TH_C4_CatLuong", "Cắt Đường Lương", CardSuit.Club, CardRank.Four, 1, CardCategory.DelayedScroll, CardSubType.SupplyShortage, "Phán xét: Không phải Chuồn ♣ -> bỏ qua Rút bài.", "UI/cards/card_supply_shortage"));
        list.Add(CreateCard("D150_TH_HK_TramAo", "Trầm Ảo Sa Bẫy", CardSuit.Heart, CardRank.King, 1, CardCategory.DelayedScroll, CardSubType.Acedia, "Phán xét: Không phải Cơ ♥ -> bỏ qua Ra bài.", "UI/cards/card_acedia"));

        return list;
    }
    #endregion

    private static Dictionary<string, CardModel> _cardCache = null;

    public static CardModel GetCardById(string cardId)
    {
        if (string.IsNullOrEmpty(cardId)) return null;
        if (_cardCache == null)
        {
            _cardCache = new Dictionary<string, CardModel>();
            var all = CreateDeck(150);
            foreach (var c in all)
            {
                if (c != null && !string.IsNullOrEmpty(c.id) && !_cardCache.ContainsKey(c.id))
                {
                    _cardCache[c.id] = c;
                }
            }
        }

        if (_cardCache.TryGetValue(cardId, out var card))
        {
            return card;
        }
        return null;
    }

    public static CardModel CreateCard(string id, string name, CardSuit suit, CardRank rank, int deckNum, CardCategory category, CardSubType subType, string desc, string icon, int range = 1, int distMod = 0)
    {
        return new CardModel
        {
            id = id,
            cardName = name,
            suit = suit,
            rank = rank,
            deckNumber = deckNum,
            category = category,
            subType = subType,
            description = desc,
            iconPath = icon,
            attackRange = range,
            distanceModifier = distMod
        };
    }
}
