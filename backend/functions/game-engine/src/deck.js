// Kho Dữ Liệu 52 Lá Bài Chuẩn Đại Việt Chiến (Khớp 100% enum C# CardModel.cs)
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
  ACEDIA: 20
};

export function createCard(id, name, suit, rank, category, subType, desc, range = 1, distMod = 0) {
  return { id, name, suit, rank, category, subType, desc, range, distMod };
}

export function createDeck52() {
  const list = [];
  // --- BÍCH (♠ - Spade) ---
  list.push(createCard("D1_S_A", "Diệu Kế Phá Mưu", "Spade", 1, 2, 10, "Vô hiệu hóa 1 Cẩm Nang bất kỳ"));
  list.push(createCard("D1_S_2", "Nỏ Thần Kim Quy", "Spade", 2, 1, 6, "Tầm 1. Không giới hạn số Trảm trong lượt", 1));
  list.push(createCard("D1_S_3", "Vườn Không Nhà Trống", "Spade", 3, 2, 11, "Hủy 1 lá của mục tiêu"));
  list.push(createCard("D1_S_4", "Vườn Không Nhà Trống", "Spade", 4, 2, 11, "Hủy 1 lá của mục tiêu"));
  list.push(createCard("D1_S_5", "Ngựa Trắng Thuần Nông", "Spade", 5, 1, 8, "Ngựa công -1 khoảng cách", 1, -1));
  list.push(createCard("D1_S_6", "Trầm Ảo Sa Bẫy", "Spade", 6, 3, 20, "Phán xét: không phải Cơ (♥) -> bỏ qua Ra bài"));
  list.push(createCard("D1_S_7", "Đột Kích Trộm Lương", "Spade", 7, 2, 12, "Cướp 1 lá của mục tiêu cự ly 1"));
  list.push(createCard("D1_S_8", "Trảm - Lôi", "Spade", 8, 0, 2, "Tấn công gây 1 sát thương Lôi"));
  list.push(createCard("D1_S_9", "Trảm - Lôi", "Spade", 9, 0, 2, "Tấn công gây 1 sát thương Lôi"));
  list.push(createCard("D1_S_10", "Trảm - Lôi", "Spade", 10, 0, 2, "Tấn công gây 1 sát thương Lôi"));
  list.push(createCard("D1_S_J", "Đột Kích Trộm Lương", "Spade", 11, 2, 12, "Cướp 1 lá của mục tiêu cự ly 1"));
  list.push(createCard("D1_S_Q", "Súng Thần Công Hồ Triều", "Spade", 12, 1, 6, "Tầm 5. Mục tiêu không được dùng Đỡ cùng chất", 5));
  list.push(createCard("D1_S_K", "Trảm - Lôi", "Spade", 13, 0, 2, "Tấn công gây 1 sát thương Lôi"));

  // --- CHUỒN (♣ - Club) ---
  list.push(createCard("D1_C_A", "Thần Sấm Báo Ứng", "Club", 1, 3, 18, "Phán xét: Bích 2-9 chịu 3 sát thương Lôi"));
  list.push(createCard("D1_C_2", "Bãi Cọc Ngầm", "Club", 2, 2, 16, "Diện rộng. Mọi người khác phải ra Trảm hoặc mất 1 máu"));
  list.push(createCard("D1_C_3", "Thách Đấu", "Club", 3, 2, 14, "Quyết đấu luân phiên ra Trảm"));
  list.push(createCard("D1_C_4", "Diệu Kế Phá Mưu", "Club", 4, 2, 10, "Vô hiệu hóa 1 Cẩm Nang bất kỳ"));
  list.push(createCard("D1_C_5", "Giáp Đồng Sơn Vi", "Club", 5, 1, 7, "Vô hiệu hóa toàn bộ Trảm Thường"));
  list.push(createCard("D1_C_6", "Trường Đao Nam Sơn", "Club", 6, 1, 6, "Tầm 3. Ép đối phương phải Đỡ 2 lần", 3));
  list.push(createCard("D1_C_7", "Bánh Chưng", "Club", 7, 0, 4, "Hồi phục 1 Máu hoặc cứu Cận Tử"));
  list.push(createCard("D1_C_8", "Trảm Thường", "Club", 8, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D1_C_9", "Trảm Thường", "Club", 9, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D1_C_10", "Trảm Thường", "Club", 10, 0, 0, "Tấn công gây 1 sát thương"));
  list.push(createCard("D1_C_J", "Hủ Rượu", "Club", 11, 0, 5, "Uống trước khi Trảm (+1 công) hoặc tự cứu 0 máu"));
  list.push(createCard("D1_C_Q", "Hủ Rượu", "Club", 12, 0, 5, "Uống trước khi Trảm (+1 công) hoặc tự cứu 0 máu"));
  list.push(createCard("D1_C_K", "Voi Chiến Đại Việt", "Club", 13, 1, 9, "Ngựa thủ +1 khoảng cách", 1, 1));

  // --- RÔ (♦ - Diamond) ---
  list.push(createCard("D1_D_A", "Kiếm Thuận Thiên", "Diamond", 1, 1, 6, "Tầm 2. Thanh bảo kiếm hộ quốc", 2));
  for (let r = 2; r <= 9; r++) {
    list.push(createCard(`D1_D_${r}`, "Đỡ", "Diamond", r, 0, 3, "Hóa giải 1 đòn Trảm"));
  }
  list.push(createCard("D1_D_10", "Trảm - Hỏa", "Diamond", 10, 0, 1, "Tấn công gây 1 sát thương Hỏa"));
  list.push(createCard("D1_D_J", "Cắt Đường Lương", "Diamond", 11, 3, 19, "Phán xét: không phải Chuồn (♣) -> mất lượt rút bài"));
  list.push(createCard("D1_D_Q", "Vườn Không Nhà Trống", "Diamond", 12, 2, 11, "Hủy 1 lá của mục tiêu"));
  list.push(createCard("D1_D_K", "Hủ Rượu", "Diamond", 13, 0, 5, "Uống trước khi Trảm (+1 công) hoặc tự cứu 0 máu"));

  // --- CƠ (♥ - Heart) ---
  list.push(createCard("D1_H_A", "Mở Kho Cứu Tế", "Heart", 1, 2, 15, "Chia bài cứu tế cho mọi người"));
  list.push(createCard("D1_H_2", "Song Cung Mường Nhạ", "Heart", 2, 1, 6, "Tầm 2. Khi Trảm bị Đỡ, có thể bỏ 2 lá ép mất máu", 2));
  list.push(createCard("D1_H_3", "Dụng Binh Như Thần", "Heart", 3, 2, 13, "Rút ngay 2 lá bài"));
  list.push(createCard("D1_H_4", "Dụng Binh Như Thần", "Heart", 4, 2, 13, "Rút ngay 2 lá bài"));
  list.push(createCard("D1_H_5", "Voi Chiến Đại Việt", "Heart", 5, 1, 9, "Ngựa thủ +1 khoảng cách", 1, 1));
  for (let r = 6; r <= 9; r++) {
    list.push(createCard(`D1_H_${r}`, "Bánh Chưng", "Heart", r, 0, 4, "Hồi phục 1 Máu hoặc cứu Cận Tử"));
  }
  list.push(createCard("D1_H_10", "Mưa Tên Liên Châu", "Heart", 10, 2, 17, "Diện rộng. Mọi người khác phải ra Đỡ hoặc mất 1 máu"));
  list.push(createCard("D1_H_J", "Trảm - Hỏa", "Heart", 11, 0, 1, "Tấn công gây 1 sát thương Hỏa"));
  list.push(createCard("D1_H_Q", "Diệu Kế Phá Mưu", "Heart", 12, 2, 10, "Vô hiệu hóa 1 Cẩm Nang bất kỳ"));
  list.push(createCard("D1_H_K", "Diệu Kế Phá Mưu", "Heart", 13, 2, 10, "Vô hiệu hóa 1 Cẩm Nang bất kỳ"));

  return list;
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
