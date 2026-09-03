// Kho Dữ Liệu Bộ Bài Đại Việt Chiến Chuẩn Hóa Theo Bài3.md (Bộ 80 Lá 2v2 & Bộ 150 Lá Đại Chiến)
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
  HARVEST: 15,
  BARBARIAN_INVASION: 16,
  ARROW_RAIN: 17,
  LIGHTNING: 18,
  SUPPLY_SHORTAGE: 19,
  ACEDIA: 20,
  IRON_CHAIN: 21
};

export function createCard(id, name, suit, rank, category, subType, desc, range = 1, distMod = 0) {
  return { id, name, suit, rank, category, subType, desc, range, distMod };
}

export function createDeck80() {
  const list = [];

  // 1. TRẢM THƯỜNG (12 lá)
  list.push(createCard("D_S_2", "Trảm Thường", "Spade", 2, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D_S_3", "Trảm Thường", "Spade", 3, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D_S_4", "Trảm Thường", "Spade", 4, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D_S_5", "Trảm Thường", "Spade", 5, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D_C_8", "Trảm Thường", "Club", 8, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D_C_9", "Trảm Thường", "Club", 9, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D_C_10", "Trảm Thường", "Club", 10, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D_D_2", "Trảm Thường", "Diamond", 2, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D_D_4", "Trảm Thường", "Diamond", 4, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D_D_6", "Trảm Thường", "Diamond", 6, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D_H_7", "Trảm Thường", "Heart", 7, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D_H_8", "Trảm Thường", "Heart", 8, 0, 0, "Tấn công gây 1 sát thương"));

  // 2. TRẢM - LÔI (4 lá)
  list.push(createCard("D_S_8", "Trảm - Lôi", "Spade", 8, 0, 2, "Tấn công gây 1 sát thương Lôi"));
  list.push(createCard("D_S_9", "Trảm - Lôi", "Spade", 9, 0, 2, "Tấn công gây 1 sát thương Lôi"));
  list.push(createCard("D_C_J_Loi", "Trảm - Lôi", "Club", 11, 0, 2, "Tấn công gây 1 sát thương Lôi"));
  list.push(createCard("D_S_K_Loi", "Trảm - Lôi", "Spade", 13, 0, 2, "Tấn công gây 1 sát thương Lôi"));

  // 3. TRẢM - HỎA (4 lá)
  list.push(createCard("D_D_8", "Trảm - Hỏa", "Diamond", 8, 0, 1, "Tấn công gây 1 sát thương Hỏa"));
  list.push(createCard("D_H_10", "Trảm - Hỏa", "Heart", 10, 0, 1, "Tấn công gây 1 sát thương Hỏa"));
  list.push(createCard("D_D_J", "Trảm - Hỏa", "Diamond", 11, 0, 1, "Tấn công gây 1 sát thương Hỏa"));
  list.push(createCard("D_H_A_Hoa", "Trảm - Hỏa", "Heart", 1, 0, 1, "Tấn công gây 1 sát thương Hỏa"));

  // 4. ĐỠ (10 lá)
  list.push(createCard("D_D_2_Do", "Đỡ", "Diamond", 2, 0, 3, "Hóa giải 1 đòn Trảm"));
  list.push(createCard("D_H_3", "Đỡ", "Heart", 3, 0, 3, "Hóa giải 1 đòn Trảm"));
  list.push(createCard("D_D_4_Do", "Đỡ", "Diamond", 4, 0, 3, "Hóa giải 1 đòn Trảm"));
  list.push(createCard("D_H_5", "Đỡ", "Heart", 5, 0, 3, "Hóa giải 1 đòn Trảm"));
  list.push(createCard("D_D_6_Do", "Đỡ", "Diamond", 6, 0, 3, "Hóa giải 1 đòn Trảm"));
  list.push(createCard("D_H_7_Do", "Đỡ", "Heart", 7, 0, 3, "Hóa giải 1 đòn Trảm"));
  list.push(createCard("D_D_8_Do", "Đỡ", "Diamond", 8, 0, 3, "Hóa giải 1 đòn Trảm"));
  list.push(createCard("D_H_9_Do", "Đỡ", "Heart", 9, 0, 3, "Hóa giải 1 đòn Trảm"));
  list.push(createCard("D_D_10_Do", "Đỡ", "Diamond", 10, 0, 3, "Hóa giải 1 đòn Trảm"));
  list.push(createCard("D_H_J_Do", "Đỡ", "Heart", 11, 0, 3, "Hóa giải 1 đòn Trảm"));

  // 5. BÁNH CHƯNG (5 lá)
  list.push(createCard("D_H_2", "Bánh Chưng", "Heart", 2, 0, 4, "Hồi phục 1 Máu hoặc cứu Cận Tử"));
  list.push(createCard("D_H_4", "Bánh Chưng", "Heart", 4, 0, 4, "Hồi phục 1 Máu hoặc cứu Cận Tử"));
  list.push(createCard("D_H_6", "Bánh Chưng", "Heart", 6, 0, 4, "Hồi phục 1 Máu hoặc cứu Cận Tử"));
  list.push(createCard("D_H_8_Banh", "Bánh Chưng", "Heart", 8, 0, 4, "Hồi phục 1 Máu hoặc cứu Cận Tử"));
  list.push(createCard("D_H_K_Banh", "Bánh Chưng", "Heart", 13, 0, 4, "Hồi phục 1 Máu hoặc cứu Cận Tử"));

  // 6. HỦ RƯỢU (3 lá)
  list.push(createCard("D_C_7_Ruou", "Hủ Rượu", "Club", 7, 0, 5, "Uống trước khi Trảm hoặc tự cứu 0 máu"));
  list.push(createCard("D_D_7_Ruou", "Hủ Rượu", "Diamond", 7, 0, 5, "Uống trước khi Trảm hoặc tự cứu 0 máu"));
  list.push(createCard("D_S_Q_Ruou", "Hủ Rượu", "Spade", 12, 0, 5, "Uống trước khi Trảm hoặc tự cứu 0 máu"));

  // 7. XÍCH TÂM TỎA (4 lá)
  list.push(createCard("D_S_K_Xich", "Xích Tâm Tỏa", "Spade", 13, 2, 21, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn"));
  list.push(createCard("D_C_A_Xich", "Xích Tâm Tỏa", "Club", 1, 2, 21, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn"));
  list.push(createCard("D_S_10_Xich", "Xích Tâm Tỏa", "Spade", 10, 2, 21, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn"));
  list.push(createCard("D_C_J_Xich", "Xích Tâm Tỏa", "Club", 11, 2, 21, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn"));

  // 8. DIỆU KẾ PHÁ MƯU (4 lá)
  list.push(createCard("D_H_A_DieuKe", "Diệu Kế Phá Mưu", "Heart", 1, 2, 10, "Vô hiệu hóa 1 Cẩm nang bất kỳ"));
  list.push(createCard("D_C_4_DieuKe", "Diệu Kế Phá Mưu", "Club", 4, 2, 10, "Vô hiệu hóa 1 Cẩm nang bất kỳ"));
  list.push(createCard("D_S_A_DieuKe", "Diệu Kế Phá Mưu", "Spade", 1, 2, 10, "Vô hiệu hóa 1 Cẩm nang bất kỳ"));
  list.push(createCard("D_H_Q_DieuKe", "Diệu Kế Phá Mưu", "Heart", 12, 2, 10, "Vô hiệu hóa 1 Cẩm nang bất kỳ"));

  // 9. VƯỜN KHÔNG NHÀ TRỐNG - QUÁ HÀ CHIẾT KIỀU (4 lá)
  list.push(createCard("D_C_Q_VuonKhong", "Vườn Không Nhà Trống", "Club", 12, 2, 11, "Hủy 1 lá của mục tiêu"));
  list.push(createCard("D_S_3_VuonKhong", "Vườn Không Nhà Trống", "Spade", 3, 2, 11, "Hủy 1 lá của mục tiêu"));
  list.push(createCard("D_S_4_VuonKhong", "Vườn Không Nhà Trống", "Spade", 4, 2, 11, "Hủy 1 lá của mục tiêu"));
  list.push(createCard("D_D_Q_VuonKhong", "Vườn Không Nhà Trống", "Diamond", 12, 2, 11, "Hủy 1 lá của mục tiêu"));

  // 10. ĐỘT KÍCH TRỘM LƯƠNG - THUẬN THỦ KHIÊN DƯƠNG (4 lá)
  list.push(createCard("D_S_K_DotKich", "Đột Kích Trộm Lương", "Spade", 13, 2, 12, "Cướp 1 lá của mục tiêu cự ly 1"));
  list.push(createCard("D_S_7_DotKich", "Đột Kích Trộm Lương", "Spade", 7, 2, 12, "Cướp 1 lá của mục tiêu cự ly 1"));
  list.push(createCard("D_S_J_DotKich", "Đột Kích Trộm Lương", "Spade", 11, 2, 12, "Cướp 1 lá của mục tiêu cự ly 1"));
  list.push(createCard("D_D_3_DotKich", "Đột Kích Trộm Lương", "Diamond", 3, 2, 12, "Cướp 1 lá của mục tiêu cự ly 1"));

  // 11. DỤNG BINH NHƯ THẦN - VÔ TRUNG SINH HỮU (3 lá)
  list.push(createCard("D_H_3_DungBinh", "Dụng Binh Như Thần", "Heart", 3, 2, 13, "Rút ngay 2 lá bài"));
  list.push(createCard("D_H_4_DungBinh", "Dụng Binh Như Thần", "Heart", 4, 2, 13, "Rút ngay 2 lá bài"));
  list.push(createCard("D_H_9_DungBinh", "Dụng Binh Như Thần", "Heart", 9, 2, 13, "Rút ngay 2 lá bài"));

  // 12. THÁCH ĐẤU - QUYẾT ĐẤU (3 lá)
  list.push(createCard("D_C_3_ThachDau", "Thách Đấu", "Club", 3, 2, 14, "Quyết đấu luân phiên ra Trảm"));
  list.push(createCard("D_S_A_ThachDau", "Thách Đấu", "Spade", 1, 2, 14, "Quyết đấu luân phiên ra Trảm"));
  list.push(createCard("D_D_A_ThachDau", "Thách Đấu", "Diamond", 1, 2, 14, "Quyết đấu luân phiên ra Trảm"));

  // 13. BÃI CỌC NGẦM - NAM MAN XÂM LẤN (2 lá)
  list.push(createCard("D_C_2_BaiCoc", "Bãi Cọc Ngầm", "Club", 2, 2, 16, "Mọi người khác phải ra Trảm hoặc mất 1 máu"));
  list.push(createCard("D_S_7_BaiCoc", "Bãi Cọc Ngầm", "Spade", 7, 2, 16, "Mọi người khác phải ra Trảm hoặc mất 1 máu"));

  // 14. MƯA TÊN LIÊN CHÂU - VẠN TIỄN TỀ PHÁT (2 lá)
  list.push(createCard("D_H_10_MuaTen", "Mưa Tên Liên Châu", "Heart", 10, 2, 17, "Mọi người khác phải ra Đỡ hoặc mất 1 máu"));
  list.push(createCard("D_H_A_MuaTen", "Mưa Tên Liên Châu", "Heart", 1, 2, 17, "Mọi người khác phải ra Đỡ hoặc mất 1 máu"));

  // 15. MỞ KHO CỨU TẾ - NGŨ CỐC PHONG ĐĂNG (2 lá)
  list.push(createCard("D_H_A_KhoCuuTe", "Mở Kho Cứu Tế", "Heart", 1, 2, 15, "Lật bài từ cọc cho mọi người lần lượt chọn"));
  list.push(createCard("D_H_3_KhoCuuTe", "Mở Kho Cứu Tế", "Heart", 3, 2, 15, "Lật bài từ cọc cho mọi người lần lượt chọn"));

  // 16. CẨM NANG TRÌ HOÃN (5 lá)
  list.push(createCard("D_C_A_SamSet", "Thần Sấm Báo Ứng", "Club", 1, 3, 18, "Phán xét: Bích 2-9 chịu 3 sát thương Lôi"));
  list.push(createCard("D_D_J_CatLuong", "Cắt Đường Lương", "Diamond", 11, 3, 19, "Phán xét: không phải Chuồn -> mất lượt rút bài"));
  list.push(createCard("D_C_J_CatLuong", "Cắt Đường Lương", "Club", 11, 3, 19, "Phán xét: không phải Chuồn -> mất lượt rút bài"));
  list.push(createCard("D_H_6_TramAo", "Trầm Ảo Sa Bẫy", "Heart", 6, 3, 20, "Phán xét: không phải Cơ -> bỏ qua Ra bài"));
  list.push(createCard("D_S_6_TramAo", "Trầm Ảo Sa Bẫy", "Spade", 6, 3, 20, "Phán xét: không phải Cơ -> bỏ qua Ra bài"));

  // 17. TRANG BỊ: VŨ KHÍ (4 lá)
  list.push(createCard("D_D_A_Kiem", "Kiếm Thuận Thiên", "Diamond", 1, 1, 6, "Tầm 2. Thanh bảo kiếm hộ quốc", 2));
  list.push(createCard("D_H_K_SongCung", "Song Cung Mường Nhạ", "Heart", 13, 1, 6, "Tầm 2. Khi Trảm bị đỡ, có thể bỏ 2 lá ép mất máu", 2));
  list.push(createCard("D_C_Q_NoThan", "Nỏ Thần Kim Quy", "Club", 12, 1, 6, "Tầm 3. Không giới hạn số Trảm trong lượt", 3));
  list.push(createCard("D_C_J_TruongDao", "Trường Đao Nam Sơn", "Club", 11, 1, 6, "Tầm 3. Ép đối phương phải đỡ 2 lần", 3));

  // 18. TRANG BỊ: ÁO GIÁP (3 lá)
  list.push(createCard("D_C_K_GiapDong", "Giáp Đồng Sơn Vi", "Club", 13, 1, 7, "Vô hiệu hóa toàn bộ Trảm Thường"));
  list.push(createCard("D_D_K_KhienMay", "Khiên Mây Bện", "Diamond", 13, 1, 7, "Khi cần Đỡ, lật phán xét: chất Đỏ tự động Đỡ"));
  list.push(createCard("D_H_A_AoBao", "Áo Bào Hoàng Tộc", "Heart", 1, 1, 7, "Giảm 1 sát thương nhận vào, tối đa 3 lần"));

  // 19. TRANG BỊ: CHIẾN MÃ (2 lá)
  list.push(createCard("D_H_K_Voi", "Voi Chiến Đại Việt", "Heart", 13, 1, 9, "Ngựa thủ +1 khoảng cách", 1, 1));
  list.push(createCard("D_S_5_Ngua", "Ngựa Trắng Thuần Nông", "Spade", 5, 1, 8, "Ngựa công -1 khoảng cách", 1, -1));

  return list;
}

export function createDeck150() {
  const d80 = createDeck80();
  const extra = createDeck80().slice(0, 70).map(c => ({ ...c, id: "EX_" + c.id }));
  return [...d80, ...extra];
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
