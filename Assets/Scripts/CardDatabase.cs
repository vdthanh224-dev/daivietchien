using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Kho Dữ Liệu Bộ Bài Đại Việt Chiến (104 lá chuẩn gồm Bộ 1 - 52 lá & Bộ 2 - 52 lá)
/// </summary>
public static class CardDatabase
{
    public static List<CardModel> CreateDeck(int deckMode = 52)
    {
        var deck = new List<CardModel>();
        deck.AddRange(CreateDeck1());

        if (deckMode >= 104)
        {
            deck.AddRange(CreateDeck2());
        }

        return deck;
    }

    #region BỘ BÀI 1 (52 Lá - Chế Độ Tiêu Chuẩn 2-4 Người)
    public static List<CardModel> CreateDeck1()
    {
        var list = new List<CardModel>();

        // --- BÍCH (♠) ---
        list.Add(CreateCard("D1_S_A", "Diệu Kế Phá Mưu", CardSuit.Spade, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.FlawlessDefense, "Vô hiệu hóa 1 Cẩm Nang bất kỳ vừa đánh ra HOẶC hủy 1 lá bài bất kỳ.", "UI/icon_flawless"));
        list.Add(CreateCard("D1_S_2", "Nỏ Thần Kim Quy", CardSuit.Spade, CardRank.Two, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 1. Giúp người chơi bỏ giới hạn lượt: Có thể ra không giới hạn số lá Trảm trong cùng một Giai đoạn Ra bài.", "UI/icon_weapon", 1));
        list.Add(CreateCard("D1_S_3", "Vườn Không Nhà Trống", CardSuit.Spade, CardRank.Three, 1, CardCategory.InstantScroll, CardSubType.Dismantle, "Người tấn công chọn 1 mục tiêu, rồi chọn 1 lá trên tay hoặc 1 trang bị của mục tiêu để hủy.", "UI/icon_dismantle"));
        list.Add(CreateCard("D1_S_4", "Vườn Không Nhà Trống", CardSuit.Spade, CardRank.Four, 1, CardCategory.InstantScroll, CardSubType.Dismantle, "Người tấn công chọn 1 mục tiêu, rồi chọn 1 lá trên tay hoặc 1 trang bị của mục tiêu để hủy.", "UI/icon_dismantle"));
        list.Add(CreateCard("D1_S_5", "Ngựa Trắng Thuần Nông", CardSuit.Spade, CardRank.Five, 1, CardCategory.Equipment, CardSubType.OffensiveHorse, "Giảm -1 khoảng cách từ bạn tới tất cả người chơi khác (Ngựa công).", "UI/icon_mount_offense", 0, -1));
        list.Add(CreateCard("D1_S_6", "Trầm Ảo Sa Bẫy", CardSuit.Spade, CardRank.Six, 1, CardCategory.DelayedScroll, CardSubType.Acedia, "Trì hoãn. Kiểm tra: nếu KHÔNG PHẢI Cơ (♥) -> Bỏ qua Giai đoạn Ra bài.", "UI/icon_acedia"));
        list.Add(CreateCard("D1_S_7", "Đột Kích Trộm Lương", CardSuit.Spade, CardRank.Seven, 1, CardCategory.InstantScroll, CardSubType.Snatch, "Cướp 1 lá bài trên tay, vùng trang bị hoặc vùng trì hoãn của mục tiêu cự ly 1.", "UI/icon_snatch"));
        list.Add(CreateCard("D1_S_8", "Trảm - Lôi", CardSuit.Spade, CardRank.Eight, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương Lôi trong tầm đánh.", "UI/icon_slash_thunder"));
        list.Add(CreateCard("D1_S_9", "Trảm - Lôi", CardSuit.Spade, CardRank.Nine, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương Lôi trong tầm đánh.", "UI/icon_slash_thunder"));
        list.Add(CreateCard("D1_S_10", "Trảm - Lôi", CardSuit.Spade, CardRank.Ten, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương Lôi trong tầm đánh.", "UI/icon_slash_thunder"));
        list.Add(CreateCard("D1_S_J", "Đột Kích Trộm Lương", CardSuit.Spade, CardRank.Jack, 1, CardCategory.InstantScroll, CardSubType.Snatch, "Cướp 1 lá bài trên tay, vùng trang bị hoặc vùng trì hoãn của mục tiêu cự ly 1.", "UI/icon_snatch"));
        list.Add(CreateCard("D1_S_Q", "Súng Thần Công Hồ Triều", CardSuit.Spade, CardRank.Queen, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 5. Mục tiêu không được dùng Đỡ có cùng chất với Trảm của bạn.", "UI/icon_weapon", 5));
        list.Add(CreateCard("D1_S_K", "Trảm - Lôi", CardSuit.Spade, CardRank.King, 1, CardCategory.Basic, CardSubType.AttackThunder, "Tấn công gây 1 sát thương Lôi trong tầm đánh.", "UI/icon_slash_thunder"));

        // --- CHUỒN (♣) ---
        list.Add(CreateCard("D1_C_A", "Thần Sấm Báo Ứng", CardSuit.Club, CardRank.Ace, 1, CardCategory.DelayedScroll, CardSubType.Lightning, "Gài vào vùng phán xét của người sử dụng. Đến lượt người đang giữ, lật bài: Bích 2-9 chịu 3 sát thương Lôi; ngược lại chuyển sang người kế tiếp.", "UI/icon_lightning"));
        list.Add(CreateCard("D1_C_2", "Bãi Cọc Ngầm", CardSuit.Club, CardRank.Two, 1, CardCategory.InstantScroll, CardSubType.BarbarianInvasion, "Diện rộng. Từng người chơi khác trên bàn (trừ người dùng) phải đánh ra 1 Trảm HOẶC chịu 1 sát thương.", "UI/icon_barbarian"));
        list.Add(CreateCard("D1_C_3", "Thách Đấu", CardSuit.Club, CardRank.Three, 1, CardCategory.InstantScroll, CardSubType.Duel, "Quyết đấu với 1 người. Luân phiên ra Trảm, bên nào không ra được chịu 1 sát thương.", "UI/icon_duel"));
        list.Add(CreateCard("D1_C_4", "Diệu Kế Phá Mưu", CardSuit.Club, CardRank.Four, 1, CardCategory.InstantScroll, CardSubType.FlawlessDefense, "Vô hiệu hóa 1 Cẩm Nang bất kỳ vừa đánh ra HOẶC hủy 1 lá bài bất kỳ.", "UI/icon_flawless"));
        list.Add(CreateCard("D1_C_5", "Giáp Đồng Sơn Vi", CardSuit.Club, CardRank.Five, 1, CardCategory.Equipment, CardSubType.Armor, "Áo giáp. Vô hiệu hóa toàn bộ Trảm Thường (không mang thuộc tính Hỏa/Lôi).", "UI/icon_armor"));
        list.Add(CreateCard("D1_C_6", "Trường Đao Nam Sơn", CardSuit.Club, CardRank.Six, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 3. Khi Trảm bị Đỡ, có thể bỏ thêm 1 Trảm ép đối phương phải Đỡ thêm lần nữa.", "UI/icon_weapon", 3));
        list.Add(CreateCard("D1_C_7", "Bánh Chưng", CardSuit.Club, CardRank.Seven, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu cho bản thân HOẶC cứu bất kỳ người chơi nào vừa rơi vào trạng thái Cận Tử.", "UI/icon_banh_chung"));
        list.Add(CreateCard("D1_C_8", "Trảm Thường", CardSuit.Club, CardRank.Eight, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công 1 mục tiêu trong tầm đánh. Đối phương phải Đỡ hoặc mất 1 máu.", "UI/icon_slash"));
        list.Add(CreateCard("D1_C_9", "Trảm Thường", CardSuit.Club, CardRank.Nine, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công 1 mục tiêu trong tầm đánh. Đối phương phải Đỡ hoặc mất 1 máu.", "UI/icon_slash"));
        list.Add(CreateCard("D1_C_10", "Trảm Thường", CardSuit.Club, CardRank.Ten, 1, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công 1 mục tiêu trong tầm đánh. Đối phương phải Đỡ hoặc mất 1 máu.", "UI/icon_slash"));
        list.Add(CreateCard("D1_C_J", "Hủ Rượu", CardSuit.Club, CardRank.Jack, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước khi Trảm: Trúng đòn gây +1 sát thương HOẶC tự cứu khi 0 máu.", "UI/icon_wine"));
        list.Add(CreateCard("D1_C_Q", "Hủ Rượu", CardSuit.Club, CardRank.Queen, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước khi Trảm: Trúng đòn gây +1 sát thương HOẶC tự cứu khi 0 máu.", "UI/icon_wine"));
        list.Add(CreateCard("D1_C_K", "Voi Chiến Đại Việt", CardSuit.Club, CardRank.King, 1, CardCategory.Equipment, CardSubType.DefensiveHorse, "Tăng +1 khoảng cách từ người khác tới bạn (Ngựa thủ phòng ngự).", "UI/icon_mount_defense", 0, 1));

        // --- RÔ (♦) ---
        list.Add(CreateCard("D1_D_A", "Kiếm Thuận Thiên", CardSuit.Diamond, CardRank.Ace, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 2. Thanh bảo kiếm hộ quốc của Bình Định Vương.", "UI/icon_weapon", 2));
        for (int r = 2; r <= 9; r++)
        {
            list.Add(CreateCard($"D1_D_{r}", "Đỡ", CardSuit.Diamond, (CardRank)r, 1, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.", "UI/icon_dodge"));
        }
        list.Add(CreateCard("D1_D_10", "Trảm - Hỏa", CardSuit.Diamond, CardRank.Ten, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công 1 sát thương Hỏa. Lan truyền khi mục tiêu bị Xích Liên Hoàn.", "UI/icon_slash_fire"));
        list.Add(CreateCard("D1_D_J", "Cắt Đường Lương", CardSuit.Diamond, CardRank.Jack, 1, CardCategory.DelayedScroll, CardSubType.SupplyShortage, "Chỉ gài mục tiêu cự ly 1. Trì hoãn: nếu phán xét KHÔNG PHẢI Chuồn (♣) -> Bỏ qua Giai đoạn Rút bài.", "UI/icon_supply_shortage"));
        list.Add(CreateCard("D1_D_Q", "Vườn Không Nhà Trống", CardSuit.Diamond, CardRank.Queen, 1, CardCategory.InstantScroll, CardSubType.Dismantle, "Người tấn công chọn 1 mục tiêu, rồi chọn 1 lá trên tay hoặc 1 trang bị của mục tiêu để hủy.", "UI/icon_dismantle"));
        list.Add(CreateCard("D1_D_K", "Hủ Rượu", CardSuit.Diamond, CardRank.King, 1, CardCategory.Basic, CardSubType.Wine, "Dùng trước khi Trảm: Trúng đòn gây +1 sát thương HOẶC tự cứu khi 0 máu.", "UI/icon_wine"));

        // --- CƠ (♥) ---
        list.Add(CreateCard("D1_H_A", "Mở Kho Cứu Tế", CardSuit.Heart, CardRank.Ace, 1, CardCategory.InstantScroll, CardSubType.Harvest, "Lật số lá bằng số người còn sống, mỗi người luân phiên chọn lấy 1 lá.", "UI/icon_harvest"));
        list.Add(CreateCard("D1_H_2", "Song Cung Mường Nhạ", CardSuit.Heart, CardRank.Two, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 2. Khi Trảm bị Đỡ, có thể bỏ 2 bài trên tay ép mục tiêu mất 1 máu.", "UI/icon_weapon", 2));
        list.Add(CreateCard("D1_H_3", "Dụng Binh Như Thần", CardSuit.Heart, CardRank.Three, 1, CardCategory.InstantScroll, CardSubType.ExNihilo, "Đánh ra để rút ngay 2 lá bài từ kho bài rút.", "UI/icon_ex_nihilo"));
        list.Add(CreateCard("D1_H_4", "Dụng Binh Như Thần", CardSuit.Heart, CardRank.Four, 1, CardCategory.InstantScroll, CardSubType.ExNihilo, "Đánh ra để rút ngay 2 lá bài từ kho bài rút.", "UI/icon_ex_nihilo"));
        list.Add(CreateCard("D1_H_5", "Voi Chiến Đại Việt", CardSuit.Heart, CardRank.Five, 1, CardCategory.Equipment, CardSubType.DefensiveHorse, "Tăng +1 khoảng cách từ người khác tới bạn (Ngựa thủ phòng ngự).", "UI/icon_mount_defense", 0, 1));
        for (int r = 6; r <= 9; r++)
        {
            list.Add(CreateCard($"D1_H_{r}", "Bánh Chưng", CardSuit.Heart, (CardRank)r, 1, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu cho bản thân HOẶC cứu bất kỳ người chơi nào vừa rơi vào trạng thái Cận Tử.", "UI/icon_banh_chung"));
        }
        list.Add(CreateCard("D1_H_10", "Mưa Tên Liên Châu", CardSuit.Heart, CardRank.Ten, 1, CardCategory.InstantScroll, CardSubType.ArrowRain, "Diện rộng. Từng người chơi khác trên bàn (trừ người dùng) phải đánh ra 1 Đỡ HOẶC chịu 1 sát thương.", "UI/icon_arrow_rain"));
        list.Add(CreateCard("D1_H_J", "Trảm - Hỏa", CardSuit.Heart, CardRank.Jack, 1, CardCategory.Basic, CardSubType.AttackFire, "Tấn công 1 sát thương Hỏa. Lan truyền khi mục tiêu bị Xích Liên Hoàn.", "UI/icon_slash_fire"));
        list.Add(CreateCard("D1_H_Q", "Diệu Kế Phá Mưu", CardSuit.Heart, CardRank.Queen, 1, CardCategory.InstantScroll, CardSubType.FlawlessDefense, "Vô hiệu hóa 1 Cẩm Nang bất kỳ vừa đánh ra HOẶC hủy 1 lá bài bất kỳ.", "UI/icon_flawless"));
        list.Add(CreateCard("D1_H_K", "Diệu Kế Phá Mưu", CardSuit.Heart, CardRank.King, 1, CardCategory.InstantScroll, CardSubType.FlawlessDefense, "Vô hiệu hóa 1 Cẩm Nang bất kỳ vừa đánh ra HOẶC hủy 1 lá bài bất kỳ.", "UI/icon_flawless"));

        return list;
    }
    #endregion

    #region BỘ BÀI 2 (52 Lá - Bổ Sung Khi Chơi Đại Chiến / Quốc Chiến)
    public static List<CardModel> CreateDeck2()
    {
        var list = new List<CardModel>();

        // --- BÍCH (♠) ---
        list.Add(CreateCard("D2_S_A", "Khiên Mây Bện", CardSuit.Spade, CardRank.Ace, 2, CardCategory.Equipment, CardSubType.Armor, "Áo giáp (Bát Quái). Mỗi khi cần đánh lá [Đỡ], lật 1 lá bài phán xét: nếu là chất ĐỎ (♥, ♦) coi như đã đánh 1 lá [Đỡ].", "UI/icon_armor"));
        list.Add(CreateCard("D2_S_2", "Song Cung Mường Nhạ", CardSuit.Spade, CardRank.Two, 2, CardCategory.Equipment, CardSubType.Weapon, "Tầm 2. Khi Trảm bị Đỡ, có thể bỏ 2 bài trên tay ép mục tiêu mất 1 máu.", "UI/icon_weapon", 2));
        for (int r = 3; r <= 10; r++)
        {
            list.Add(CreateCard($"D2_S_{r}", "Trảm Thường", CardSuit.Spade, (CardRank)r, 2, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công 1 mục tiêu trong tầm đánh. Đối phương phải Đỡ hoặc mất 1 máu.", "UI/icon_slash"));
        }
        list.Add(CreateCard("D2_S_J", "Đột Kích Trộm Lương", CardSuit.Spade, CardRank.Jack, 2, CardCategory.InstantScroll, CardSubType.Snatch, "Cướp 1 lá bài trên tay, vùng trang bị hoặc vùng trì hoãn của mục tiêu trong cự ly 1.", "UI/icon_snatch"));
        list.Add(CreateCard("D2_S_Q", "Đột Kích Trộm Lương", CardSuit.Spade, CardRank.Queen, 2, CardCategory.InstantScroll, CardSubType.Snatch, "Cướp 1 lá bài trên tay, vùng trang bị hoặc vùng trì hoãn của mục tiêu trong cự ly 1.", "UI/icon_snatch"));
        list.Add(CreateCard("D2_S_K", "Đột Kích Trộm Lương", CardSuit.Spade, CardRank.King, 2, CardCategory.InstantScroll, CardSubType.Snatch, "Cướp 1 lá bài trên tay, vùng trang bị hoặc vùng trì hoãn của mục tiêu trong cự ly 1.", "UI/icon_snatch"));

        // --- CHUỒN (♣) ---
        list.Add(CreateCard("D2_C_A", "Thách Đấu", CardSuit.Club, CardRank.Ace, 2, CardCategory.InstantScroll, CardSubType.Duel, "Quyết đấu với 1 người. Luân phiên ra Trảm, bên nào không ra được chịu 1 sát thương.", "UI/icon_duel"));
        list.Add(CreateCard("D2_C_2", "Thương Ngâu Lãng Bạc", CardSuit.Club, CardRank.Two, 2, CardCategory.Equipment, CardSubType.Weapon, "Tầm 4. Trảm gây sát thương thành công được hủy 1 lá bài của mục tiêu.", "UI/icon_weapon", 4));
        for (int r = 3; r <= 10; r++)
        {
            list.Add(CreateCard($"D2_C_{r}", "Trảm Thường", CardSuit.Club, (CardRank)r, 2, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công 1 mục tiêu trong tầm đánh. Đối phương phải Đỡ hoặc mất 1 máu.", "UI/icon_slash"));
        }
        list.Add(CreateCard("D2_C_J", "Trường Đao Nam Sơn", CardSuit.Club, CardRank.Jack, 2, CardCategory.Equipment, CardSubType.Weapon, "Tầm 3. Khi Trảm bị Đỡ, có thể bỏ thêm 1 Trảm ép đối phương phải Đỡ thêm lần nữa.", "UI/icon_weapon", 3));
        list.Add(CreateCard("D2_C_Q", "Vườn Không Nhà Trống", CardSuit.Club, CardRank.Queen, 2, CardCategory.InstantScroll, CardSubType.Dismantle, "Người tấn công chọn 1 mục tiêu, rồi chọn 1 lá trên tay hoặc 1 trang bị của mục tiêu để hủy.", "UI/icon_dismantle"));
        list.Add(CreateCard("D2_C_K", "Vườn Không Nhà Trống", CardSuit.Club, CardRank.King, 2, CardCategory.InstantScroll, CardSubType.Dismantle, "Người tấn công chọn 1 mục tiêu, rồi chọn 1 lá trên tay hoặc 1 trang bị của mục tiêu để hủy.", "UI/icon_dismantle"));

        // --- RÔ (♦) ---
        list.Add(CreateCard("D2_D_A", "Thương Ngâu Lãng Bạc", CardSuit.Diamond, CardRank.Ace, 2, CardCategory.Equipment, CardSubType.Weapon, "Tầm 4. Trảm gây sát thương thành công được hủy 1 lá bài của mục tiêu.", "UI/icon_weapon", 4));
        for (int r = 2; r <= 7; r++)
        {
            list.Add(CreateCard($"D2_D_{r}", "Đỡ", CardSuit.Diamond, (CardRank)r, 2, CardCategory.Basic, CardSubType.Dodge, "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.", "UI/icon_dodge"));
        }
        for (int r = 8; r <= 10; r++)
        {
            list.Add(CreateCard($"D2_D_{r}", "Trảm Thường (Đỏ)", CardSuit.Diamond, (CardRank)r, 2, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công 1 mục tiêu trong tầm đánh. (Trảm Thường Đỏ).", "UI/icon_slash"));
        }
        list.Add(CreateCard("D2_D_J", "Trảm - Hỏa", CardSuit.Diamond, CardRank.Jack, 2, CardCategory.Basic, CardSubType.AttackFire, "Tấn công 1 sát thương Hỏa. Lan truyền khi mục tiêu bị Xích Liên Hoàn.", "UI/icon_slash_fire"));
        list.Add(CreateCard("D2_D_Q", "Vườn Không Nhà Trống", CardSuit.Diamond, CardRank.Queen, 2, CardCategory.InstantScroll, CardSubType.Dismantle, "Người tấn công chọn 1 mục tiêu, rồi chọn 1 lá trên tay hoặc 1 trang bị của mục tiêu để hủy.", "UI/icon_dismantle"));
        list.Add(CreateCard("D2_D_K", "Hủ Rượu", CardSuit.Diamond, CardRank.King, 2, CardCategory.Basic, CardSubType.Wine, "Dùng trước khi Trảm: Trúng đòn gây +1 sát thương HOẶC tự cứu khi 0 máu.", "UI/icon_wine"));

        // --- CƠ (♥) ---
        list.Add(CreateCard("D2_H_A", "Áo Bào Hoàng Tộc", CardSuit.Heart, CardRank.Ace, 2, CardCategory.Equipment, CardSubType.Armor, "Áo giáp hoàng gia. Tất cả sát thương đánh vào bạn đều được giảm 1 điểm (tối đa 3 lần).", "UI/icon_armor"));
        list.Add(CreateCard("D2_H_2", "Ngựa Trắng Thuần Nông", CardSuit.Heart, CardRank.Two, 2, CardCategory.Equipment, CardSubType.OffensiveHorse, "Giảm -1 khoảng cách từ bạn tới tất cả người chơi khác (Ngựa công).", "UI/icon_mount_offense", 0, -1));
        list.Add(CreateCard("D2_H_3", "Thách Đấu", CardSuit.Heart, CardRank.Three, 2, CardCategory.InstantScroll, CardSubType.Duel, "Quyết đấu với 1 người. Luân phiên ra Trảm, bên nào không ra được chịu 1 sát thương.", "UI/icon_duel"));
        list.Add(CreateCard("D2_H_4", "Dụng Binh Như Thần", CardSuit.Heart, CardRank.Four, 2, CardCategory.InstantScroll, CardSubType.ExNihilo, "Đánh ra để rút ngay 2 lá bài từ kho bài rút.", "UI/icon_ex_nihilo"));
        list.Add(CreateCard("D2_H_5", "Ngựa Trắng Thuần Nông", CardSuit.Heart, CardRank.Five, 2, CardCategory.Equipment, CardSubType.OffensiveHorse, "Giảm -1 khoảng cách từ bạn tới tất cả người chơi khác (Ngựa công).", "UI/icon_mount_offense", 0, -1));
        for (int r = 6; r <= 7; r++)
        {
            list.Add(CreateCard($"D2_H_{r}", "Bánh Chưng", CardSuit.Heart, (CardRank)r, 2, CardCategory.Basic, CardSubType.Peach, "Hồi phục 1 Máu cho bản thân HOẶC cứu bất kỳ người chơi nào vừa rơi vào trạng thái Cận Tử.", "UI/icon_banh_chung"));
        }
        for (int r = 8; r <= 11; r++)
        {
            list.Add(CreateCard($"D2_H_{r}", "Trảm Thường (Đỏ)", CardSuit.Heart, (CardRank)r, 2, CardCategory.Basic, CardSubType.AttackNormal, "Tấn công 1 mục tiêu trong tầm đánh. (Trảm Thường Đỏ).", "UI/icon_slash"));
        }
        list.Add(CreateCard("D2_H_Q", "Cắt Đường Lương", CardSuit.Heart, CardRank.Queen, 2, CardCategory.DelayedScroll, CardSubType.SupplyShortage, "Chỉ gài mục tiêu cự ly 1. Trì hoãn: nếu phán xét KHÔNG PHẢI Chuồn (♣) -> Bỏ qua Giai đoạn Rút bài.", "UI/icon_supply_shortage"));
        list.Add(CreateCard("D2_H_K", "Trầm Ảo Sa Bẫy", CardSuit.Heart, CardRank.King, 2, CardCategory.DelayedScroll, CardSubType.Acedia, "Trì hoãn. Kiểm tra: nếu KHÔNG PHẢI Cơ (♥) -> Bỏ qua Giai đoạn Ra bài.", "UI/icon_acedia"));

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
            var all = CreateDeck(104);
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
