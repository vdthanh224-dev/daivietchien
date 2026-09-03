using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Kho Dữ Liệu Bộ Bài Đại Việt Chiến Chuẩn Hóa Theo Bài3.md (Bộ 80 Lá 2v2 Song Hùng & Bộ 150 Lá Đại Chiến/Quốc Chiến)
/// </summary>
public static class CardDatabase
{
    public static List<CardModel> CreateDeck(int deckMode = 80)
    {
        if (deckMode >= 150) return CreateDeck150();
        return CreateDeck80();
    }

    #region BỘ BÀI 80 LÁ (Chế Độ Song Hùng 2v2 - Chuẩn Bài3.md)
    public static List<CardModel> CreateDeck80()
    {
        var list = new List<CardModel>();

        // 1. TRẢM THƯỜNG (12 lá)
        list.Add(CreateCard("D_S_2", "Trảm Thường", CardSuit.Spade, CardRank.Two, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương.", "UI/icon_slash"));
        list.Add(CreateCard("D_S_3", "Trảm Thường", CardSuit.Spade, CardRank.Three, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương.", "UI/icon_slash"));
        list.Add(CreateCard("D_S_4", "Trảm Thường", CardSuit.Spade, CardRank.Four, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương.", "UI/icon_slash"));
        list.Add(CreateCard("D_S_5", "Trảm Thường", CardSuit.Spade, CardRank.Five, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương.", "UI/icon_slash"));
        list.Add(CreateCard("D_C_8", "Trảm Thường", CardSuit.Club, CardRank.Eight, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương.", "UI/icon_slash"));
        list.Add(CreateCard("D_C_9", "Trảm Thường", CardSuit.Club, CardRank.Nine, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương.", "UI/icon_slash"));
        list.Add(CreateCard("D_C_10", "Trảm Thường", CardSuit.Club, CardRank.Ten, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương.", "UI/icon_slash"));
        list.Add(CreateCard("D_D_2", "Trảm Thường", CardSuit.Diamond, CardRank.Two, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương.", "UI/icon_slash"));
        list.Add(CreateCard("D_D_4", "Trảm Thường", CardSuit.Diamond, CardRank.Four, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương.", "UI/icon_slash"));
        list.Add(CreateCard("D_D_6", "Trảm Thường", CardSuit.Diamond, CardRank.Six, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương.", "UI/icon_slash"));
        list.Add(CreateCard("D_H_7", "Trảm Thường", CardSuit.Heart, CardRank.Seven, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương.", "UI/icon_slash"));
        list.Add(CreateCard("D_H_8", "Trảm Thường", CardSuit.Heart, CardRank.Eight, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công gây 1 sát thương.", "UI/icon_slash"));

        // 2. TRẢM - LÔI (4 lá)
        list.Add(CreateCard("D_S_8", "Trảm - Lôi", CardSuit.Spade, CardRank.Eight, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương Lôi trong tầm đánh.", "UI/icon_slash_thunder"));
        list.Add(CreateCard("D_S_9", "Trảm - Lôi", CardSuit.Spade, CardRank.Nine, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương Lôi trong tầm đánh.", "UI/icon_slash_thunder"));
        list.Add(CreateCard("D_C_J_Loi", "Trảm - Lôi", CardSuit.Club, CardRank.Jack, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương Lôi trong tầm đánh.", "UI/icon_slash_thunder"));
        list.Add(CreateCard("D_S_K_Loi", "Trảm - Lôi", CardSuit.Spade, CardRank.King, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương Lôi trong tầm đánh.", "UI/icon_slash_thunder"));

        // 3. TRẢM - HỎA (4 lá)
        list.Add(CreateCard("D_D_8", "Trảm - Hỏa", CardSuit.Diamond, CardRank.Eight, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công gây 1 sát thương Hỏa.", "UI/icon_slash_fire"));
        list.Add(CreateCard("D_H_10", "Trảm - Hỏa", CardSuit.Heart, CardRank.Ten, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công gây 1 sát thương Hỏa.", "UI/icon_slash_fire"));
        list.Add(CreateCard("D_D_J", "Trảm - Hỏa", CardSuit.Diamond, CardRank.Jack, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công gây 1 sát thương Hỏa.", "UI/icon_slash_fire"));
        list.Add(CreateCard("D_H_A_Hoa", "Trảm - Hỏa", CardSuit.Heart, CardRank.Ace, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công gây 1 sát thương Hỏa.", "UI/icon_slash_fire"));

        // 4. ĐỠ (10 lá)
        list.Add(CreateCard("D_D_2_Do", "Đỡ", CardSuit.Diamond, CardRank.Two, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.", "UI/icon_dodge"));
        list.Add(CreateCard("D_H_3", "Đỡ", CardSuit.Heart, CardRank.Three, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.", "UI/icon_dodge"));
        list.Add(CreateCard("D_D_4_Do", "Đỡ", CardSuit.Diamond, CardRank.Four, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.", "UI/icon_dodge"));
        list.Add(CreateCard("D_H_5", "Đỡ", CardSuit.Heart, CardRank.Five, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.", "UI/icon_dodge"));
        list.Add(CreateCard("D_D_6_Do", "Đỡ", CardSuit.Diamond, CardRank.Six, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.", "UI/icon_dodge"));
        list.Add(CreateCard("D_H_7_Do", "Đỡ", CardSuit.Heart, CardRank.Seven, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.", "UI/icon_dodge"));
        list.Add(CreateCard("D_D_8_Do", "Đỡ", CardSuit.Diamond, CardRank.Eight, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.", "UI/icon_dodge"));
        list.Add(CreateCard("D_H_9_Do", "Đỡ", CardSuit.Heart, CardRank.Nine, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.", "UI/icon_dodge"));
        list.Add(CreateCard("D_D_10_Do", "Đỡ", CardSuit.Diamond, CardRank.Ten, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.", "UI/icon_dodge"));
        list.Add(CreateCard("D_H_J_Do", "Đỡ", CardSuit.Heart, CardRank.Jack, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.", "UI/icon_dodge"));

        // 5. BÁNH CHƯNG (5 lá)
        list.Add(CreateCard("D_H_2", "Bánh Chưng", CardSuit.Heart, CardRank.Two, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu hoặc cứu Cận Tử.", "UI/icon_banh_chung"));
        list.Add(CreateCard("D_H_4", "Bánh Chưng", CardSuit.Heart, CardRank.Four, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu hoặc cứu Cận Tử.", "UI/icon_banh_chung"));
        list.Add(CreateCard("D_H_6", "Bánh Chưng", CardSuit.Heart, CardRank.Six, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu hoặc cứu Cận Tử.", "UI/icon_banh_chung"));
        list.Add(CreateCard("D_H_8_Banh", "Bánh Chưng", CardSuit.Heart, CardRank.Eight, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu hoặc cứu Cận Tử.", "UI/icon_banh_chung"));
        list.Add(CreateCard("D_H_K_Banh", "Bánh Chưng", CardSuit.Heart, CardRank.King, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu hoặc cứu Cận Tử.", "UI/icon_banh_chung"));

        // 6. HỦ RƯỢU (3 lá)
        list.Add(CreateCard("D_C_7_Ruou", "Hủ Rượu", CardSuit.Club, CardRank.Seven, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước khi Trảm: +1 sát thương HOẶC tự cứu khi 0 máu.", "UI/icon_wine"));
        list.Add(CreateCard("D_D_7_Ruou", "Hủ Rượu", CardSuit.Diamond, CardRank.Seven, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước khi Trảm: +1 sát thương HOẶC tự cứu khi 0 máu.", "UI/icon_wine"));
        list.Add(CreateCard("D_S_Q_Ruou", "Hủ Rượu", CardSuit.Spade, CardRank.Queen, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước khi Trảm: +1 sát thương HOẶC tự cứu khi 0 máu.", "UI/icon_wine"));

        // 7. XÍCH TÂM TỎA (4 lá)
        list.Add(CreateCard("D_S_K_Xich", "Xích Tâm Tỏa", CardSuit.Spade, CardRank.King, 1, CardCategory.InstantScroll, CardSubType.IronChain, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn. Sát thương Hỏa/Lôi sẽ truyền qua xích!", "UI/icon_duel"));
        list.Add(CreateCard("D_C_A_Xich", "Xích Tâm Tỏa", CardSuit.Club, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.IronChain, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn. Sát thương Hỏa/Lôi sẽ truyền qua xích!", "UI/icon_duel"));
        list.Add(CreateCard("D_S_10_Xich", "Xích Tâm Tỏa", CardSuit.Spade, CardRank.Ten, 1, CardCategory.InstantScroll, CardSubType.IronChain, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn. Sát thương Hỏa/Lôi sẽ truyền qua xích!", "UI/icon_duel"));
        list.Add(CreateCard("D_C_J_Xich", "Xích Tâm Tỏa", CardSuit.Club, CardRank.Jack, 1, CardCategory.InstantScroll, CardSubType.IronChain, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn. Sát thương Hỏa/Lôi sẽ truyền qua xích!", "UI/icon_duel"));

        // 8. DIỆU KẾ PHÁ MƯU (4 lá)
        list.Add(CreateCard("D_H_A_DieuKe", "Diệu Kế Phá Mưu", CardSuit.Heart, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.FlawlessDefense, "Vô hiệu hóa 1 Cẩm Nang bất kỳ vừa đánh ra.", "UI/icon_flawless"));
        list.Add(CreateCard("D_C_4_DieuKe", "Diệu Kế Phá Mưu", CardSuit.Club, CardRank.Four, 1, CardCategory.InstantScroll, CardSubType.FlawlessDefense, "Vô hiệu hóa 1 Cẩm Nang bất kỳ vừa đánh ra.", "UI/icon_flawless"));
        list.Add(CreateCard("D_S_A_DieuKe", "Diệu Kế Phá Mưu", CardSuit.Spade, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.FlawlessDefense, "Vô hiệu hóa 1 Cẩm Nang bất kỳ vừa đánh ra.", "UI/icon_flawless"));
        list.Add(CreateCard("D_H_Q_DieuKe", "Diệu Kế Phá Mưu", CardSuit.Heart, CardRank.Queen, 1, CardCategory.InstantScroll, CardSubType.FlawlessDefense, "Vô hiệu hóa 1 Cẩm Nang bất kỳ vừa đánh ra.", "UI/icon_flawless"));

        // 9. VƯỜN KHÔNG NHÀ TRỐNG (4 lá)
        list.Add(CreateCard("D_C_Q_VuonKhong", "Vườn Không Nhà Trống", CardSuit.Club, CardRank.Queen, 1, CardCategory.InstantScroll, CardSubType.Dismantle, "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 lá trang bị của họ.", "UI/icon_dismantle"));
        list.Add(CreateCard("D_S_3_VuonKhong", "Vườn Không Nhà Trống", CardSuit.Spade, CardRank.Three, 1, CardCategory.InstantScroll, CardSubType.Dismantle, "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 lá trang bị của họ.", "UI/icon_dismantle"));
        list.Add(CreateCard("D_S_4_VuonKhong", "Vườn Không Nhà Trống", CardSuit.Spade, CardRank.Four, 1, CardCategory.InstantScroll, CardSubType.Dismantle, "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 lá trang bị của họ.", "UI/icon_dismantle"));
        list.Add(CreateCard("D_D_Q_VuonKhong", "Vườn Không Nhà Trống", CardSuit.Diamond, CardRank.Queen, 1, CardCategory.InstantScroll, CardSubType.Dismantle, "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 lá trang bị của họ.", "UI/icon_dismantle"));

        // 10. ĐỘT KÍCH TRỘM LƯƠNG (4 lá)
        list.Add(CreateCard("D_S_K_DotKich", "Đột Kích Trộm Lương", CardSuit.Spade, CardRank.King, 1, CardCategory.InstantScroll, CardSubType.Snatch, "Cướp 1 lá bài trên tay hoặc trang bị của mục tiêu cự ly 1.", "UI/icon_snatch"));
        list.Add(CreateCard("D_S_7_DotKich", "Đột Kích Trộm Lương", CardSuit.Spade, CardRank.Seven, 1, CardCategory.InstantScroll, CardSubType.Snatch, "Cướp 1 lá bài trên tay hoặc trang bị của mục tiêu cự ly 1.", "UI/icon_snatch"));
        list.Add(CreateCard("D_S_J_DotKich", "Đột Kích Trộm Lương", CardSuit.Spade, CardRank.Jack, 1, CardCategory.InstantScroll, CardSubType.Snatch, "Cướp 1 lá bài trên tay hoặc trang bị của mục tiêu cự ly 1.", "UI/icon_snatch"));
        list.Add(CreateCard("D_D_3_DotKich", "Đột Kích Trộm Lương", CardSuit.Diamond, CardRank.Three, 1, CardCategory.InstantScroll, CardSubType.Snatch, "Cướp 1 lá bài trên tay hoặc trang bị của mục tiêu cự ly 1.", "UI/icon_snatch"));

        // 11. DỤNG BINH NHƯ THẦN (3 lá)
        list.Add(CreateCard("D_H_3_DungBinh", "Dụng Binh Như Thần", CardSuit.Heart, CardRank.Three, 1, CardCategory.InstantScroll, CardSubType.ExNihilo, "Rút ngay 2 lá bài từ bộ bài.", "UI/icon_ex_nihilo"));
        list.Add(CreateCard("D_H_4_DungBinh", "Dụng Binh Như Thần", CardSuit.Heart, CardRank.Four, 1, CardCategory.InstantScroll, CardSubType.ExNihilo, "Rút ngay 2 lá bài từ bộ bài.", "UI/icon_ex_nihilo"));
        list.Add(CreateCard("D_H_9_DungBinh", "Dụng Binh Như Thần", CardSuit.Heart, CardRank.Nine, 1, CardCategory.InstantScroll, CardSubType.ExNihilo, "Rút ngay 2 lá bài từ bộ bài.", "UI/icon_ex_nihilo"));

        // 12. THÁCH ĐẤU (3 lá)
        list.Add(CreateCard("D_C_3_ThachDau", "Thách Đấu", CardSuit.Club, CardRank.Three, 1, CardCategory.InstantScroll, CardSubType.Duel, "Quyết đấu với 1 tướng bất kỳ. Hai bên luân phiên ra Trảm, ai không ra được sẽ mất 1 Máu.", "UI/icon_duel"));
        list.Add(CreateCard("D_S_A_ThachDau", "Thách Đấu", CardSuit.Spade, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.Duel, "Quyết đấu với 1 tướng bất kỳ. Hai bên luân phiên ra Trảm, ai không ra được sẽ mất 1 Máu.", "UI/icon_duel"));
        list.Add(CreateCard("D_D_A_ThachDau", "Thách Đấu", CardSuit.Diamond, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.Duel, "Quyết đấu với 1 tướng bất kỳ. Hai bên luân phiên ra Trảm, ai không ra được sẽ mất 1 Máu.", "UI/icon_duel"));

        // 13. BÃI CỌC NGẦM (2 lá)
        list.Add(CreateCard("D_C_2_BaiCoc", "Bãi Cọc Ngầm", CardSuit.Club, CardRank.Two, 1, CardCategory.InstantScroll, CardSubType.BarbarianInvasion, "Diện rộng. Toàn bộ người chơi khác phải đánh ra 1 Trảm hoặc chịu 1 sát thương.", "UI/icon_barbarian"));
        list.Add(CreateCard("D_S_7_BaiCoc", "Bãi Cọc Ngầm", CardSuit.Spade, CardRank.Seven, 1, CardCategory.InstantScroll, CardSubType.BarbarianInvasion, "Diện rộng. Toàn bộ người chơi khác phải đánh ra 1 Trảm hoặc chịu 1 sát thương.", "UI/icon_barbarian"));

        // 14. MƯA TÊN LIÊN CHÂU (2 lá)
        list.Add(CreateCard("D_H_10_MuaTen", "Mưa Tên Liên Châu", CardSuit.Heart, CardRank.Ten, 1, CardCategory.InstantScroll, CardSubType.ArrowRain, "Diện rộng. Toàn bộ người chơi khác phải đánh ra 1 Đỡ hoặc chịu 1 sát thương.", "UI/icon_arrow_rain"));
        list.Add(CreateCard("D_H_A_MuaTen", "Mưa Tên Liên Châu", CardSuit.Heart, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.ArrowRain, "Diện rộng. Toàn bộ người chơi khác phải đánh ra 1 Đỡ hoặc chịu 1 sát thương.", "UI/icon_arrow_rain"));

        // 15. MỞ KHO CỨU TẾ (2 lá)
        list.Add(CreateCard("D_H_A_KhoCuuTe", "Mở Kho Cứu Tế", CardSuit.Heart, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.Harvest, "Lật bài từ cọc cho mọi người chơi lần lượt chọn 1 lá bài.", "UI/icon_harvest"));
        list.Add(CreateCard("D_H_3_KhoCuuTe", "Mở Kho Cứu Tế", CardSuit.Heart, CardRank.Three, 1, CardCategory.InstantScroll, CardSubType.Harvest, "Lật bài từ cọc cho mọi người chơi lần lượt chọn 1 lá bài.", "UI/icon_harvest"));

        // 16. CẨM NANG TRÌ HOÃN (5 lá)
        list.Add(CreateCard("D_C_A_SamSet", "Thần Sấm Báo Ứng", CardSuit.Club, CardRank.Ace, 1, CardCategory.DelayedScroll, CardSubType.Lightning, "Gài vùng phán xét. Bích 2-9 chịu 3 sát thương Lôi.", "UI/icon_lightning"));
        list.Add(CreateCard("D_D_J_CatLuong", "Cắt Đường Lương", CardSuit.Diamond, CardRank.Jack, 1, CardCategory.DelayedScroll, CardSubType.SupplyShortage, "Gài mục tiêu cự ly 1. Phán xét không phải Chuồn -> Mất lượt rút bài.", "UI/icon_supply_shortage"));
        list.Add(CreateCard("D_C_J_CatLuong", "Cắt Đường Lương", CardSuit.Club, CardRank.Jack, 1, CardCategory.DelayedScroll, CardSubType.SupplyShortage, "Gài mục tiêu cự ly 1. Phán xét không phải Chuồn -> Mất lượt rút bài.", "UI/icon_supply_shortage"));
        list.Add(CreateCard("D_H_6_TramAo", "Trầm Ảo Sa Bẫy", CardSuit.Heart, CardRank.Six, 1, CardCategory.DelayedScroll, CardSubType.Acedia, "Trì hoãn mục tiêu. Phán xét không phải Cơ -> Bỏ qua Ra bài.", "UI/icon_acedia"));
        list.Add(CreateCard("D_S_6_TramAo", "Trầm Ảo Sa Bẫy", CardSuit.Spade, CardRank.Six, 1, CardCategory.DelayedScroll, CardSubType.Acedia, "Trì hoãn mục tiêu. Phán xét không phải Cơ -> Bỏ qua Ra bài.", "UI/icon_acedia"));

        // 17. TRANG BỊ: VŨ KHÍ (4 lá)
        list.Add(CreateCard("D_D_A_Kiem", "Kiếm Thuận Thiên", CardSuit.Diamond, CardRank.Ace, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 2. Thanh bảo kiếm hộ quốc của Bình Định Vương.", "UI/icon_weapon", 2));
        list.Add(CreateCard("D_H_K_SongCung", "Song Cung Mường Nhạ", CardSuit.Heart, CardRank.King, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 2. Khi Trảm bị Đỡ, có thể bỏ 2 bài ép chịu 1 sát thương.", "UI/icon_weapon", 2));
        list.Add(CreateCard("D_C_Q_NoThan", "Nỏ Thần Kim Quy", CardSuit.Club, CardRank.Queen, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 3. Không giới hạn số lá Trảm đánh ra trong lượt.", "UI/icon_weapon", 3));
        list.Add(CreateCard("D_C_J_TruongDao", "Trường Đao Nam Sơn", CardSuit.Club, CardRank.Jack, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 3. Khi Trảm bị Đỡ, có thể bỏ thêm 1 Trảm ép Đỡ lần nữa.", "UI/icon_weapon", 3));

        // 18. TRANG BỊ: ÁO GIÁP (3 lá)
        list.Add(CreateCard("D_C_K_GiapDong", "Giáp Đồng Sơn Vi", CardSuit.Club, CardRank.King, 1, CardCategory.Equipment, CardSubType.Armor, "Vô hiệu hóa toàn bộ Trảm Thường.", "UI/icon_armor"));
        list.Add(CreateCard("D_D_K_KhienMay", "Khiên Mây Bện", CardSuit.Diamond, CardRank.King, 1, CardCategory.Equipment, CardSubType.Armor, "Khi cần Đỡ, lật phán xét: chất Đỏ tự động Đỡ.", "UI/icon_armor"));
        list.Add(CreateCard("D_H_A_AoBao", "Áo Bào Hoàng Tộc", CardSuit.Heart, CardRank.Ace, 1, CardCategory.Equipment, CardSubType.Armor, "Tất cả sát thương nhận vào giảm 1 (tối đa 3 lần).", "UI/icon_armor"));

        // 19. TRANG BỊ: CHIẾN MÃ (2 lá)
        list.Add(CreateCard("D_H_K_Voi", "Voi Chiến Đại Việt", CardSuit.Heart, CardRank.King, 1, CardCategory.Equipment, CardSubType.DefensiveHorse, "Tăng +1 khoảng cách từ người khác tới bạn (Ngựa thủ).", "UI/icon_mount_defense", 0, 1));
        list.Add(CreateCard("D_S_5_Ngua", "Ngựa Trắng Thuần Nông", CardSuit.Spade, CardRank.Five, 1, CardCategory.Equipment, CardSubType.OffensiveHorse, "Giảm -1 khoảng cách từ bạn tới tất cả người khác (Ngựa công).", "UI/icon_mount_offense", 0, -1));

        return list;
    }
    #endregion

    #region BỘ BÀI 150 LÁ (Chế Độ Đại Chiến 8 Người / Quốc Chiến - Chuẩn Bài3.md)
    public static List<CardModel> CreateDeck150()
    {
        var list = new List<CardModel>();
        // Kết hợp 2 bộ 80 lá (hoặc mở rộng đúng 150 lá chuẩn theo Bài3.md)
        list.AddRange(CreateDeck80());

        var list2 = CreateDeck80();
        for (int i = 0; i < 70 && i < list2.Count; i++)
        {
            var c = list2[i];
            var clone = CreateCard("EX_" + c.id, c.cardName, c.suit, c.rank, 2, c.category, c.subType, c.description, c.iconPath, c.attackRange, c.distanceModifier);
            list.Add(clone);
        }

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
