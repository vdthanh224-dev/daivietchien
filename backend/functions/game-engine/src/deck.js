// Kho Dữ Liệu Bộ Bài Đại Việt Chiến Chuẩn Hóa Theo ĐẶC TẢ CẤU TRÚC BỘ BÀI 2v2 (80 Lá) & 8 NGƯỜI (150 Lá)
export const CARD_CATEGORIES = {
  BASIC: 0,
  EQUIPMENT: 1,
  INSTANT_SCROLL: 2,
  DELAYED_SCROLL: 3
};

export const CARD_SUBTYPES = {
  ATTACK_NORMAL: 0,
  ATTACK_FIRE: 1,
  ATTACK_THUNDER: 2,
  DODGE: 3,
  PEACH: 4,
  WINE: 5,
  WEAPON: 6,
  ARMOR: 7,
  OFFENSIVE_HORSE: 8,
  DEFENSIVE_HORSE: 9,
  FLAWLESS_DEFENSE: 10,
  DISMANTLE: 11,
  SNATCH: 12,
  EX_NIHILO: 13,
  DUEL: 14,
  IRON_CHAIN: 15,
  HARVEST: 16,
  BARBARIAN_INVASION: 17,
  ARROW_RAIN: 18,
  LIGHTNING: 19,
  SUPPLY_SHORTAGE: 20,
  ACEDIA: 21
};

export function createCard(id, name, suit, rank, category, subType, desc, range = 1, distMod = 0) {
  return { id, name, suit, rank, category, subType, desc, range, distMod };
}

export function createDeck80() {
  const list = [];

  // ==========================================
  // 1. TRẢM THƯỜNG — 22 LÁ (11 Đen, 11 Đỏ)
  // ==========================================
  // Trảm Thường Đen — 11 lá
  list.push(createCard("D80_TN_S2", "Trảm Thường", "Spade", 2, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_S3", "Trảm Thường", "Spade", 3, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_S4", "Trảm Thường", "Spade", 4, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_S5", "Trảm Thường", "Spade", 5, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_S6", "Trảm Thường", "Spade", 6, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_S7", "Trảm Thường", "Spade", 7, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_C8", "Trảm Thường", "Club", 8, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_C9", "Trảm Thường", "Club", 9, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_C10", "Trảm Thường", "Club", 10, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_CJ", "Trảm Thường", "Club", 11, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_CQ", "Trảm Thường", "Club", 12, 0, 0, "Tấn công gây 1 sát thương thường"));

  // Trảm Thường Đỏ — 11 lá
  list.push(createCard("D80_TN_D2", "Trảm Thường", "Diamond", 2, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_D3", "Trảm Thường", "Diamond", 3, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_D4", "Trảm Thường", "Diamond", 4, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_D5", "Trảm Thường", "Diamond", 5, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_D6", "Trảm Thường", "Diamond", 6, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_H7", "Trảm Thường", "Heart", 7, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_H8", "Trảm Thường", "Heart", 8, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_H9", "Trảm Thường", "Heart", 9, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_D10", "Trảm Thường", "Diamond", 10, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_HJ", "Trảm Thường", "Heart", 11, 0, 0, "Tấn công gây 1 sát thương thường"));
  list.push(createCard("D80_TN_HQ", "Trảm Thường", "Heart", 12, 0, 0, "Tấn công gây 1 sát thương thường"));

  // ==========================================
  // 2. TRẢM - LÔI — 6 LÁ (Toàn bộ Đen)
  // ==========================================
  list.push(createCard("D80_TL_S8", "Trảm - Lôi", "Spade", 8, 0, 2, "Tấn công gây 1 sát thương thuộc tính Lôi"));
  list.push(createCard("D80_TL_S9", "Trảm - Lôi", "Spade", 9, 0, 2, "Tấn công gây 1 sát thương thuộc tính Lôi"));
  list.push(createCard("D80_TL_C10", "Trảm - Lôi", "Club", 10, 0, 2, "Tấn công gây 1 sát thương thuộc tính Lôi"));
  list.push(createCard("D80_TL_CJ", "Trảm - Lôi", "Club", 11, 0, 2, "Tấn công gây 1 sát thương thuộc tính Lôi"));
  list.push(createCard("D80_TL_SK", "Trảm - Lôi", "Spade", 13, 0, 2, "Tấn công gây 1 sát thương thuộc tính Lôi"));
  list.push(createCard("D80_TL_CA", "Trảm - Lôi", "Club", 1, 0, 2, "Tấn công gây 1 sát thương thuộc tính Lôi"));

  // ==========================================
  // 3. TRẢM - HỎA — 6 LÁ (Toàn bộ Đỏ)
  // ==========================================
  list.push(createCard("D80_TH_D8", "Trảm - Hỏa", "Diamond", 8, 0, 1, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn"));
  list.push(createCard("D80_TH_D9", "Trảm - Hỏa", "Diamond", 9, 0, 1, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn"));
  list.push(createCard("D80_TH_H10", "Trảm - Hỏa", "Heart", 10, 0, 1, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn"));
  list.push(createCard("D80_TH_DJ", "Trảm - Hỏa", "Diamond", 11, 0, 1, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn"));
  list.push(createCard("D80_TH_HQ", "Trảm - Hỏa", "Heart", 12, 0, 1, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn"));
  list.push(createCard("D80_TH_HA", "Trảm - Hỏa", "Heart", 1, 0, 1, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn"));

  // ==========================================
  // 4. ĐỠ — 14 LÁ (Toàn bộ Đỏ)
  // ==========================================
  list.push(createCard("D80_DO_D2", "Đỡ", "Diamond", 2, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_H3", "Đỡ", "Heart", 3, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_D4", "Đỡ", "Diamond", 4, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_H5", "Đỡ", "Heart", 5, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_D6", "Đỡ", "Diamond", 6, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_H7", "Đỡ", "Heart", 7, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_D8", "Đỡ", "Diamond", 8, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_H9", "Đỡ", "Heart", 9, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_D10", "Đỡ", "Diamond", 10, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_HJ", "Đỡ", "Heart", 11, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_DQ", "Đỡ", "Diamond", 12, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_HQ", "Đỡ", "Heart", 12, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_DK", "Đỡ", "Diamond", 13, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  list.push(createCard("D80_DO_HK", "Đỡ", "Heart", 13, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));

  // ==========================================
  // 5. BÁNH CHƯNG — 6 LÁ (Toàn bộ Cơ ♥)
  // ==========================================
  list.push(createCard("D80_BC_H2", "Bánh Chưng", "Heart", 2, 0, 4, "Hồi phục 1 Máu hoặc cứu đồng minh Cận Tử"));
  list.push(createCard("D80_BC_H4", "Bánh Chưng", "Heart", 4, 0, 4, "Hồi phục 1 Máu hoặc cứu đồng minh Cận Tử"));
  list.push(createCard("D80_BC_H6", "Bánh Chưng", "Heart", 6, 0, 4, "Hồi phục 1 Máu hoặc cứu đồng minh Cận Tử"));
  list.push(createCard("D80_BC_H8", "Bánh Chưng", "Heart", 8, 0, 4, "Hồi phục 1 Máu hoặc cứu đồng minh Cận Tử"));
  list.push(createCard("D80_BC_H10", "Bánh Chưng", "Heart", 10, 0, 4, "Hồi phục 1 Máu hoặc cứu đồng minh Cận Tử"));
  list.push(createCard("D80_BC_HK", "Bánh Chưng", "Heart", 13, 0, 4, "Hồi phục 1 Máu hoặc cứu đồng minh Cận Tử"));

  // ==========================================
  // 6. HỦ RƯỢU — 4 LÁ
  // ==========================================
  list.push(createCard("D80_HR_C7", "Hủ Rượu", "Club", 7, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"));
  list.push(createCard("D80_HR_D7", "Hủ Rượu", "Diamond", 7, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"));
  list.push(createCard("D80_HR_SQ", "Hủ Rượu", "Spade", 12, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"));
  list.push(createCard("D80_HR_HJ", "Hủ Rượu", "Heart", 11, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"));

  // ==========================================
  // 7. XÍCH TÂM TỎA — 2 LÁ (Toàn bộ Đen)
  // ==========================================
  list.push(createCard("D80_XT_SK", "Xích Tâm Tỏa", "Spade", 13, 2, 15, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích"));
  list.push(createCard("D80_XT_CA", "Xích Tâm Tỏa", "Club", 1, 2, 15, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích"));

  // ==========================================
  // 8. VŨ KHÍ — 7 LÁ
  // ==========================================
  list.push(createCard("D80_VK_DA_ThuanThien", "Kiếm Thuận Thiên", "Diamond", 1, 1, 6, "Tầm 2. Trảm của bạn bỏ qua Trang bị Giáp của mục tiêu", 2));
  list.push(createCard("D80_VK_HK_SongCung", "Song Cung Mường Nhạ", "Heart", 13, 1, 6, "Tầm 2. Khi Trảm bị Đỡ, có thể bỏ 2 lá trên tay ép chịu 1 sát thương", 2));
  list.push(createCard("D80_VK_SK_SongCung", "Song Cung Mường Nhạ", "Spade", 13, 1, 6, "Tầm 2. Khi Trảm bị Đỡ, có thể bỏ 2 lá trên tay ép chịu 1 sát thương", 2));
  list.push(createCard("D80_VK_CQ_NoThan", "Nỏ Thần Kim Quy", "Club", 12, 1, 6, "Tầm 3. Không giới hạn số lá Trảm trong cùng Giai đoạn Ra bài", 3));
  list.push(createCard("D80_VK_CJ_TruongDao", "Trường Đao Nam Sơn", "Club", 11, 1, 6, "Tầm 3. Khi Trảm bị Đỡ, bỏ thêm 1 Trảm ép dùng thêm 1 Đỡ", 3));
  list.push(createCard("D80_VK_DQ_ThuongNgau", "Thương Ngâu Lãng Bạc", "Diamond", 12, 1, 6, "Tầm 4. Khi Trảm trúng, hủy 1 lá trên tay hoặc trang bị đối phương", 4));
  list.push(createCard("D80_VK_SA_SungThanCong", "Súng Thần Công Hồ Triều", "Spade", 1, 1, 6, "Tầm 5. Mục tiêu không được sử dụng Đỡ cùng chất với lá Trảm", 5));

  // ==========================================
  // 9. ÁO GIÁP — 3 LÁ
  // ==========================================
  list.push(createCard("D80_AG_CK_GiapDong", "Giáp Đồng Sơn Vi", "Club", 13, 1, 7, "Vô hiệu hóa toàn bộ đòn Trảm Thường không mang Lôi/Hỏa"));
  list.push(createCard("D80_AG_DK_KhienMay", "Khiên Mây Bện", "Diamond", 13, 1, 7, "Bị Trảm/Mưa Tên: lật phán xét Đỏ tự động Đỡ, Đen thất bại"));
  list.push(createCard("D80_AG_HA_AoBao", "Áo Bào Hoàng Tộc", "Heart", 1, 1, 7, "Tất cả sát thương nhận vào được giảm 1, tối đa 3 lần"));

  // ==========================================
  // 10. CHIẾN MÃ — 4 LÁ
  // ==========================================
  list.push(createCard("D80_CM_HK_VoiChien", "Voi Chiến Đại Việt", "Heart", 13, 1, 9, "Ngựa Thủ: Tăng +1 Khoảng cách từ người chơi khác tới bạn", 1, 1));
  list.push(createCard("D80_CM_CK_VoiChien", "Voi Chiến Đại Việt", "Club", 13, 1, 9, "Ngựa Thủ: Tăng +1 Khoảng cách từ người chơi khác tới bạn", 1, 1));
  list.push(createCard("D80_CM_SJ_NguaTrang", "Ngựa Trắng Thuần Nông", "Spade", 11, 1, 8, "Ngựa Công: Giảm -1 Khoảng cách từ bạn tới tất cả người khác", 1, -1));
  list.push(createCard("D80_CM_DJ_NguaTrang", "Ngựa Trắng Thuần Nông", "Diamond", 11, 1, 8, "Ngựa Công: Giảm -1 Khoảng cách từ bạn tới tất cả người khác", 1, -1));

  // ==========================================
  // 11. CẨM NANG TỨC THỜI — 8 LÁ
  // ==========================================
  list.push(createCard("D80_CN_HA_DieuKe", "Diệu Kế Phá Mưu", "Heart", 1, 2, 10, "Vô hiệu hóa 1 Cẩm Nang bất kỳ HOẶC hủy 1 lá trên tay/bàn người khác"));
  list.push(createCard("D80_CN_CQ_VuonKhong", "Vườn Không Nhà Trống", "Club", 12, 2, 11, "Chọn 1 mục tiêu: ép tự bỏ 1 lá trên tay HOẶC hủy 1 trang bị"));
  list.push(createCard("D80_CN_SK_DotKich", "Đột Kích Trộm Lương", "Spade", 13, 2, 12, "Cướp 1 lá tay, trang bị hoặc Trì Hoãn của mục tiêu cự ly 1"));
  list.push(createCard("D80_CN_H3_DungBinh", "Dụng Binh Như Thần", "Heart", 3, 2, 13, "Rút ngay 2 lá bài từ xấp bài"));
  list.push(createCard("D80_CN_ThachDau", "Thách Đấu", "Diamond", 1, 2, 14, "Thách đấu 1 mục tiêu, hai bên luân phiên đánh Trảm, ai không đánh được chịu 1 sát thương"));
  list.push(createCard("D80_CN_D4_MoKho", "Mở Kho Cứu Tế", "Diamond", 4, 2, 16, "Mở kho phát bài cho tất cả người chơi còn sống"));
  list.push(createCard("D80_CN_BaiCoc", "Bãi Cọc Ngầm", "Spade", 7, 2, 17, "Ép tất cả người chơi khác phải đánh 1 Trảm hoặc chịu 1 sát thương"));
  list.push(createCard("D80_CN_MuaTen", "Mưa Tên Liên Châu", "Heart", 1, 2, 18, "Ép tất cả người chơi khác phải đánh 1 Đỡ hoặc chịu 1 sát thương"));

  // ==========================================
  // 12. CẨM NANG TRÌ HOÃN — 3 LÁ
  // ==========================================
  list.push(createCard("D80_TH_CA_SamSet", "Thần Sấm Báo Ứng", "Club", 1, 3, 19, "Phán xét: Bích ♠ từ 2 đến 9 chịu 3 sát thương Lôi, trượt chuyển người kế"));
  list.push(createCard("D80_TH_DQ_CatLuong", "Cắt Đường Lương", "Diamond", 12, 3, 20, "Phán xét: Nếu KHÔNG PHẢI Chuồn ♣ -> bỏ qua Giai đoạn Rút bài"));
  list.push(createCard("D80_TH_HK_TramAo", "Trầm Ảo Sa Bẫy", "Heart", 13, 3, 21, "Phán xét: Nếu KHÔNG PHẢI Cơ ♥ -> bỏ qua Giai đoạn Ra bài"));

  return list;
}

export function createDeck150() {
  const list = [];

  // ==========================================
  // 1. TRẢM THƯỜNG — 42 LÁ (21 Đen, 21 Đỏ)
  // ==========================================
  // ♠ × 11: ♠2..♠Q
  const spadeRanks = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  for (let r of spadeRanks) {
    list.push(createCard(`D150_TN_S${r}`, "Trảm Thường", "Spade", r, 0, 0, "Tấn công gây 1 sát thương thường"));
  }
  // ♣ × 10: ♣2..♣J
  const clubRanks = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  for (let r of clubRanks) {
    list.push(createCard(`D150_TN_C${r}`, "Trảm Thường", "Club", r, 0, 0, "Tấn công gây 1 sát thương thường"));
  }
  // ♦ × 10: ♦2..♦J
  const diaRanks = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  for (let r of diaRanks) {
    list.push(createCard(`D150_TN_D${r}`, "Trảm Thường", "Diamond", r, 0, 0, "Tấn công gây 1 sát thương thường"));
  }
  // ♥ × 11: ♥2..♥Q
  const heartRanks = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  for (let r of heartRanks) {
    list.push(createCard(`D150_TN_H${r}`, "Trảm Thường", "Heart", r, 0, 0, "Tấn công gây 1 sát thương thường"));
  }

  // ==========================================
  // 2. TRẢM - LÔI — 12 LÁ (Toàn bộ Đen, 6 ♠, 6 ♣, mã 8..K)
  // ==========================================
  const loiRanks = [8, 9, 10, 11, 12, 13];
  for (let r of loiRanks) {
    list.push(createCard(`D150_TL_S${r}`, "Trảm - Lôi", "Spade", r, 0, 2, "Tấn công gây 1 sát thương Lôi"));
    list.push(createCard(`D150_TL_C${r}`, "Trảm - Lôi", "Club", r, 0, 2, "Tấn công gây 1 sát thương Lôi"));
  }

  // ==========================================
  // 3. TRẢM - HỎA — 12 LÁ (Toàn bộ Đỏ, 6 ♦, 6 ♥, mã 8..K)
  // ==========================================
  const hoaRanks = [8, 9, 10, 11, 12, 13];
  for (let r of hoaRanks) {
    list.push(createCard(`D150_TH_D${r}`, "Trảm - Hỏa", "Diamond", r, 0, 1, "Tấn công gây 1 sát thương Hỏa"));
    list.push(createCard(`D150_TH_H${r}`, "Trảm - Hỏa", "Heart", r, 0, 1, "Tấn công gây 1 sát thương Hỏa"));
  }

  // ==========================================
  // 4. ĐỠ — 26 LÁ (Toàn bộ Đỏ, 13 ♦, 13 ♥: từ 2 đến K + A)
  // ==========================================
  for (let r = 1; r <= 13; r++) {
    list.push(createCard(`D150_DO_D${r}`, "Đỡ", "Diamond", r, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
    list.push(createCard(`D150_DO_H${r}`, "Đỡ", "Heart", r, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"));
  }

  // ==========================================
  // 5. BÁNH CHƯNG — 12 LÁ (Toàn bộ Cơ ♥ từ 2 đến K)
  // ==========================================
  for (let r = 2; r <= 13; r++) {
    list.push(createCard(`D150_BC_H${r}`, "Bánh Chưng", "Heart", r, 0, 4, "Hồi 1 Máu hoặc cứu đồng minh Cận Tử"));
  }

  // ==========================================
  // 6. HỦ RƯỢU — 7 LÁ (♣J, ♦J, ♠Q, ♣Q, ♦K, ♠K, ♥A)
  // ==========================================
  list.push(createCard("D150_HR_CJ", "Hủ Rượu", "Club", 11, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"));
  list.push(createCard("D150_HR_DJ", "Hủ Rượu", "Diamond", 11, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"));
  list.push(createCard("D150_HR_SQ", "Hủ Rượu", "Spade", 12, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"));
  list.push(createCard("D150_HR_CQ", "Hủ Rượu", "Club", 12, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"));
  list.push(createCard("D150_HR_DK", "Hủ Rượu", "Diamond", 13, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"));
  list.push(createCard("D150_HR_SK", "Hủ Rượu", "Spade", 13, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"));
  list.push(createCard("D150_HR_HA", "Hủ Rượu", "Heart", 1, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"));

  // ==========================================
  // 7. XÍCH TÂM TỎA — 4 LÁ (Toàn bộ Đen: ♠Q, ♣Q, ♠K, ♣A)
  // ==========================================
  list.push(createCard("D150_XT_SQ", "Xích Tâm Tỏa", "Spade", 12, 2, 15, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích"));
  list.push(createCard("D150_XT_CQ", "Xích Tâm Tỏa", "Club", 12, 2, 15, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích"));
  list.push(createCard("D150_XT_SK", "Xích Tâm Tỏa", "Spade", 13, 2, 15, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích"));
  list.push(createCard("D150_XT_CA", "Xích Tâm Tỏa", "Club", 1, 2, 15, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích"));

  // ==========================================
  // 8. VŨ KHÍ — 12 LÁ (Mỗi loại 2 lá)
  // ==========================================
  list.push(createCard("D150_VK_DA_ThuanThien", "Kiếm Thuận Thiên", "Diamond", 1, 1, 6, "Tầm 2. Trảm bỏ qua Trang bị Giáp mục tiêu", 2));
  list.push(createCard("D150_VK_D2_ThuanThien", "Kiếm Thuận Thiên", "Diamond", 2, 1, 6, "Tầm 2. Trảm bỏ qua Trang bị Giáp mục tiêu", 2));
  list.push(createCard("D150_VK_HK_SongCung", "Song Cung Mường Nhạ", "Heart", 13, 1, 6, "Tầm 2. Trảm bị Đỡ: bỏ 2 lá ép chịu 1 sát thương", 2));
  list.push(createCard("D150_VK_SK_SongCung", "Song Cung Mường Nhạ", "Spade", 13, 1, 6, "Tầm 2. Trảm bị Đỡ: bỏ 2 lá ép chịu 1 sát thương", 2));
  list.push(createCard("D150_VK_CQ_NoThan", "Nỏ Thần Kim Quy", "Club", 12, 1, 6, "Tầm 3. Không giới hạn số Trảm trong lượt", 3));
  list.push(createCard("D150_VK_SA_NoThan", "Nỏ Thần Kim Quy", "Spade", 1, 1, 6, "Tầm 3. Không giới hạn số Trảm trong lượt", 3));
  list.push(createCard("D150_VK_CJ_TruongDao", "Trường Đao Nam Sơn", "Club", 11, 1, 6, "Tầm 3. Trảm bị Đỡ: bỏ thêm 1 Trảm ép dùng thêm 1 Đỡ", 3));
  list.push(createCard("D150_VK_DQ_TruongDao", "Trường Đao Nam Sơn", "Diamond", 12, 1, 6, "Tầm 3. Trảm bị Đỡ: bỏ thêm 1 Trảm ép dùng thêm 1 Đỡ", 3));
  list.push(createCard("D150_VK_DQ_ThuongNgau", "Thương Ngâu Lãng Bạc", "Diamond", 12, 1, 6, "Tầm 4. Trảm trúng: hủy 1 lá tay hoặc trang bị", 4));
  list.push(createCard("D150_VK_C5_ThuongNgau", "Thương Ngâu Lãng Bạc", "Club", 5, 1, 6, "Tầm 4. Trảm trúng: hủy 1 lá tay hoặc trang bị", 4));
  list.push(createCard("D150_VK_SA_SungThanCong", "Súng Thần Công Hồ Triều", "Spade", 1, 1, 6, "Tầm 5. Mục tiêu không được dùng Đỡ cùng chất với Trảm", 5));
  list.push(createCard("D150_VK_DA_SungThanCong", "Súng Thần Công Hồ Triều", "Diamond", 1, 1, 6, "Tầm 5. Mục tiêu không được dùng Đỡ cùng chất với Trảm", 5));

  // ==========================================
  // 9. ÁO GIÁP — 6 LÁ (Mỗi loại 2 lá)
  // ==========================================
  list.push(createCard("D150_AG_CK_GiapDong", "Giáp Đồng Sơn Vi", "Club", 13, 1, 7, "Vô hiệu hóa toàn bộ Trảm Thường"));
  list.push(createCard("D150_AG_S2_GiapDong", "Giáp Đồng Sơn Vi", "Spade", 2, 1, 7, "Vô hiệu hóa toàn bộ Trảm Thường"));
  list.push(createCard("D150_AG_DK_KhienMay", "Khiên Mây Bện", "Diamond", 13, 1, 7, "Khi bị Trảm: lật phán xét Đỏ tự động Đỡ, Đen thất bại"));
  list.push(createCard("D150_AG_C2_KhienMay", "Khiên Mây Bện", "Club", 2, 1, 7, "Khi bị Trảm: lật phán xét Đỏ tự động Đỡ, Đen thất bại"));
  list.push(createCard("D150_AG_HA_AoBao", "Áo Bào Hoàng Tộc", "Heart", 1, 1, 7, "Giảm 1 sát thương nhận vào, tối đa 3 lần"));
  list.push(createCard("D150_AG_D3_AoBao", "Áo Bào Hoàng Tộc", "Diamond", 3, 1, 7, "Giảm 1 sát thương nhận vào, tối đa 3 lần"));

  // ==========================================
  // 10. CHIẾN MÃ — 7 LÁ (3 Voi Chiến, 4 Ngựa Trắng)
  // ==========================================
  list.push(createCard("D150_CM_HK_VoiChien", "Voi Chiến Đại Việt", "Heart", 13, 1, 9, "Ngựa Thủ: +1 Khoảng cách từ người khác tới bạn", 1, 1));
  list.push(createCard("D150_CM_CK_VoiChien", "Voi Chiến Đại Việt", "Club", 13, 1, 9, "Ngựa Thủ: +1 Khoảng cách từ người khác tới bạn", 1, 1));
  list.push(createCard("D150_CM_DK_VoiChien", "Voi Chiến Đại Việt", "Diamond", 13, 1, 9, "Ngựa Thủ: +1 Khoảng cách từ người khác tới bạn", 1, 1));
  list.push(createCard("D150_CM_SJ_NguaTrang", "Ngựa Trắng Thuần Nông", "Spade", 11, 1, 8, "Ngựa Công: -1 Khoảng cách từ bạn tới tất cả người khác", 1, -1));
  list.push(createCard("D150_CM_DJ_NguaTrang", "Ngựa Trắng Thuần Nông", "Diamond", 11, 1, 8, "Ngựa Công: -1 Khoảng cách từ bạn tới tất cả người khác", 1, -1));
  list.push(createCard("D150_CM_CJ_NguaTrang", "Ngựa Trắng Thuần Nông", "Club", 11, 1, 8, "Ngựa Công: -1 Khoảng cách từ bạn tới tất cả người khác", 1, -1));
  list.push(createCard("D150_CM_H5_NguaTrang", "Ngựa Trắng Thuần Nông", "Heart", 5, 1, 8, "Ngựa Công: -1 Khoảng cách từ bạn tới tất cả người khác", 1, -1));

  // ==========================================
  // 11. CẨM NANG TỨC THỜI — 14 LÁ
  // ==========================================
  list.push(createCard("D150_CN_HA_DieuKe", "Diệu Kế Phá Mưu", "Heart", 1, 2, 10, "Vô hiệu hóa 1 Cẩm Nang HOẶC hủy 1 lá trên tay/bàn"));
  list.push(createCard("D150_CN_SA_DieuKe", "Diệu Kế Phá Mưu", "Spade", 1, 2, 10, "Vô hiệu hóa 1 Cẩm Nang HOẶC hủy 1 lá trên tay/bàn"));
  list.push(createCard("D150_CN_CQ_VuonKhong", "Vườn Không Nhà Trống", "Club", 12, 2, 11, "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 trang bị"));
  list.push(createCard("D150_CN_S3_VuonKhong", "Vườn Không Nhà Trống", "Spade", 3, 2, 11, "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 trang bị"));
  list.push(createCard("D150_CN_SK_DotKich", "Đột Kích Trộm Lương", "Spade", 13, 2, 12, "Cướp 1 lá tay, trang bị hoặc Trì Hoãn của mục tiêu cự ly 1"));
  list.push(createCard("D150_CN_H3_DungBinh", "Dụng Binh Như Thần", "Heart", 3, 2, 13, "Rút ngay 2 lá bài từ xấp bài"));
  list.push(createCard("D150_CN_S7_BaiCoc", "Bãi Cọc Ngầm", "Spade", 7, 2, 17, "Ép tất cả người chơi khác phải đánh 1 Trảm hoặc chịu 1 sát thương"));
  list.push(createCard("D150_CN_C7_BaiCoc", "Bãi Cọc Ngầm", "Club", 7, 2, 17, "Ép tất cả người chơi khác phải đánh 1 Trảm hoặc chịu 1 sát thương"));
  list.push(createCard("D150_CN_HA_MuaTen", "Mưa Tên Liên Châu", "Heart", 1, 2, 18, "Ép tất cả người chơi khác phải đánh 1 Đỡ hoặc chịu 1 sát thương"));
  list.push(createCard("D150_CN_DA_MuaTen", "Mưa Tên Liên Châu", "Diamond", 1, 2, 18, "Ép tất cả người chơi khác phải đánh 1 Đỡ hoặc chịu 1 sát thương"));
  list.push(createCard("D150_CN_DA_ThachDau", "Thách Đấu", "Diamond", 1, 2, 14, "Thách đấu 1 mục tiêu, hai bên luân phiên đánh Trảm, ai không đánh được chịu 1 sát thương"));
  list.push(createCard("D150_CN_SA_ThachDau", "Thách Đấu", "Spade", 1, 2, 14, "Thách đấu 1 mục tiêu, hai bên luân phiên đánh Trảm, ai không đánh được chịu 1 sát thương"));
  list.push(createCard("D150_CN_H3_MoKho", "Mở Kho Cứu Tế", "Heart", 3, 2, 16, "Mở kho phát bài cho tất cả người chơi còn sống"));
  list.push(createCard("D150_CN_D4_MoKho", "Mở Kho Cứu Tế", "Diamond", 4, 2, 16, "Mở kho phát bài cho tất cả người chơi còn sống"));

  // ==========================================
  // 12. CẨM NANG TRÌ HOÃN — 4 LÁ (1 Thần Sấm, 2 Cắt Lương, 1 Trầm Ảo)
  // ==========================================
  list.push(createCard("D150_TH_CA_SamSet", "Thần Sấm Báo Ứng", "Club", 1, 3, 19, "Phán xét: Bích ♠ 2..9 chịu 3 sát thương Lôi, trượt chuyển tiếp"));
  list.push(createCard("D150_TH_DQ_CatLuong", "Cắt Đường Lương", "Diamond", 12, 3, 20, "Phán xét: Không phải Chuồn ♣ -> bỏ qua Rút bài"));
  list.push(createCard("D150_TH_C4_CatLuong", "Cắt Đường Lương", "Club", 4, 3, 20, "Phán xét: Không phải Chuồn ♣ -> bỏ qua Rút bài"));
  list.push(createCard("D150_TH_HK_TramAo", "Trầm Ảo Sa Bẫy", "Heart", 13, 3, 21, "Phán xét: Không phải Cơ ♥ -> bỏ qua Ra bài"));

  return list;
}

// Hàm hỗ trợ các quy mô bộ bài linh hoạt theo Mục V:
// 1v1: 60 lá | 2v2: 80 lá | 3-4 người: 100 lá | 5-6 người: 125 lá | 7-8 người: 150 lá
export function createDeck(mode = 80) {
  if (mode >= 150) return createDeck150();
  if (mode <= 60) return createDeck80().slice(0, 60);
  if (mode === 80) return createDeck80();
  if (mode === 100) {
    const d80 = createDeck80();
    const extra = createDeck150().slice(80, 100);
    return [...d80, ...extra];
  }
  if (mode === 125) {
    const d80 = createDeck80();
    const extra = createDeck150().slice(80, 125);
    return [...d80, ...extra];
  }
  return createDeck80();
}

export function createFullDeck104() {
  return createDeck80();
}

export function createDeck52() {
  return createDeck80();
}

export function isSlash(card) {
  return card && (card.subType === CARD_SUBTYPES.ATTACK_NORMAL || card.subType === CARD_SUBTYPES.ATTACK_FIRE || card.subType === CARD_SUBTYPES.ATTACK_THUNDER);
}

export function isDodge(card) {
  return card && card.subType === CARD_SUBTYPES.DODGE;
}

export function isPeach(card) {
  return card && card.subType === CARD_SUBTYPES.PEACH;
}

export function isWine(card) {
  return card && card.subType === CARD_SUBTYPES.WINE;
}
