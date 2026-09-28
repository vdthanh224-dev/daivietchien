// Kho Dữ Liệu Tướng & Kỹ Năng - Đại Việt Chiến
export const FACTIONS = {
  DAI_VIET: 'DAI_VIET',
  MINH_QUOC: 'MINH_QUOC',
  CHIEM_THANH: 'CHIEM_THANH',
  TOC_MAN: 'TOC_MAN'
};

export const HEROES = {
  HERO_1: { id: 'HERO_1', name: 'Cao Lỗ', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['CHE_NO', 'LIEN_CHAU'] },
  HERO_2: { id: 'HERO_2', name: 'Đào Hãn', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['XA_THUAN', 'PHU_TRAN'] },
  HERO_3: { id: 'HERO_3', name: 'Thi Sách', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['HICH_NGHIA', 'UAT_KHI'] },
  HERO_4: { id: 'HERO_4', name: 'Lê Chân', faction: FACTIONS.DAI_VIET, maxHp: 3, skills: ['TRIEU_DANG', 'LAP_LANG'] },
  HERO_5: { id: 'HERO_5', name: 'Thánh Thiên', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['DUNG_NU', 'THU_MUC'] },
  HERO_6: { id: 'HERO_6', name: 'Vũ Thị Thục', faction: FACTIONS.DAI_VIET, maxHp: 3, skills: ['TRINH_LIET', 'BAT_NA'] },
  HERO_7: { id: 'HERO_7', name: 'Nàng Nội', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['TIEN_PHONG', 'TRAN_TIEN'] },
  HERO_8: { id: 'HERO_8', name: 'Triệu Quốc Đạt', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['KHOI_BINH', 'HUYNH_TRUONG'] },
  TRAN_HUNG_DAO: {
    id: 'TRAN_HUNG_DAO',
    name: 'Trần Hưng Đạo',
    faction: FACTIONS.DAI_VIET,
    maxHp: 4,
    skills: ['KIEP_BACH', 'DAN_TRAN']
  },
  LY_THUONG_KIET: {
    id: 'LY_THUONG_KIET',
    name: 'Lý Thường Kiệt',
    faction: FACTIONS.DAI_VIET,
    maxHp: 4,
    skills: ['THAN_TOAN']
  },
  NGUYEN_HUE: {
    id: 'NGUYEN_HUE',
    name: 'Nguyễn Huệ',
    faction: FACTIONS.DAI_VIET,
    maxHp: 4,
    skills: ['THAN_TOC']
  },
  TRAN_QUOC_TOAN: {
    id: 'TRAN_QUOC_TOAN',
    name: 'Trần Quốc Toản',
    faction: FACTIONS.DAI_VIET,
    maxHp: 4,
    skills: ['THIEU_NIEN']
  },
  LE_LOI: {
    id: 'LE_LOI',
    name: 'Lê Lợi',
    faction: FACTIONS.DAI_VIET,
    maxHp: 4,
    skills: ['BINH_NGO']
  },
  NGUYEN_TRAI: {
    id: 'NGUYEN_TRAI',
    name: 'Nguyễn Trãi',
    faction: FACTIONS.DAI_VIET,
    maxHp: 3,
    skills: ['THAN_CO']
  }
};

export const HERO_MAX_HP = [
  0, 4, 4, 4, 3, 4, 3, 4, 4, 4, 4,
  4, 3, 4, 4, 4, 4, 4, 3, 3, 4,
  3, 4, 4, 3, 4, 4, 4, 4, 4, 4,
  4, 4, 4, 4, 4, 3, 4, 3, 4, 4,
  4, 3, 3, 4, 4, 3, 4, 4, 4, 4,
  4, 4, 4, 4, 3, 4, 4, 4, 4, 4,
  4, 3, 4, 4, 4, 3, 3, 3, 3, 3,
  4, 4, 4, 4, 4, 4, 4, 3, 4, 4,
  4, 4, 4, 4, 3, 4, 3, 4, 4, 4,
  4, 3, 4, 3, 4, 4, 3, 4, 4, 4
];

for (let heroNumber = 1; heroNumber <= 100; heroNumber++) {
  const heroId = `HERO_${heroNumber}`;
  if (!HEROES[heroId]) {
    HEROES[heroId] = {
      id: heroId,
      name: heroId,
      faction: FACTIONS.DAI_VIET,
      maxHp: HERO_MAX_HP[heroNumber] || 4,
      skills: []
    };
  }
}

export const SKILLS = {
  CHE_NO: { id: 'CHE_NO', name: 'Chế Nỏ', type: 'TOGGLE', description: 'Bật: mọi lá Bích trên tay thành Nỏ Thần Kim Quy.' },
  LIEN_CHAU: { id: 'LIEN_CHAU', name: 'Liên Châu', type: 'OPTIONAL', description: 'Khi đeo Nỏ Thần Kim Quy dùng Trảm, bỏ thêm 1 lá để chọn thêm 1 mục tiêu trong tầm.' },
  XA_THUAN: { id: 'XA_THUAN', name: 'Xạ Thuẫn', type: 'PASSIVE', description: 'Mặc định tăng 2 tầm Ngựa công.' },
  PHU_TRAN: { id: 'PHU_TRAN', name: 'Phù Trấn', type: 'TRIGGERED', description: 'Khi dùng Trảm mà không đeo vũ khí, rút 1 lá bài.' },
  HICH_NGHIA: { id: 'HICH_NGHIA', name: 'Hịch Nghĩa', type: 'TRIGGERED', description: 'Khi rơi vào Cận Tử, lập tức rút 3 lá bài.' },
  UAT_KHI: { id: 'UAT_KHI', name: 'Uất Khí', type: 'OPTIONAL', description: 'Khi mất Máu mà chưa Cận Tử, có thể cho 1 người khác rút 1 lá bài.' },
  TRIEU_DANG: { id: 'TRIEU_DANG', name: 'Triều Dâng', type: 'ACTIVE', description: 'Một lần mỗi lượt, hủy 1 trang bị của người khác.' },
  LAP_LANG: { id: 'LAP_LANG', name: 'Lập Làng', type: 'TRIGGERED', description: 'Cuối lượt, nếu chưa gây sát thương, rút 2 lá bài.' },
  DUNG_NU: { id: 'DUNG_NU', name: 'Dũng Nữ', type: 'PASSIVE', description: 'Mục tiêu có Máu hiện tại nhiều hơn bạn phải dùng 2 lá Đỡ để triệt tiêu Trảm của bạn.' },
  THU_MUC: { id: 'THU_MUC', name: 'Thủ Mục', type: 'OPTIONAL', description: 'Trước sát thương Trảm, có thể bỏ 1 lá Đỏ để giảm 1 sát thương.' },
  TRINH_LIET: { id: 'TRINH_LIET', name: 'Trinh Liệt', type: 'TRIGGERED', description: 'Khi chịu sát thương Trảm, rút 1 lá bài trong vùng chơi của nguồn gây sát thương.' },
  BAT_NA: { id: 'BAT_NA', name: 'Bát Nạ', type: 'ACTIVE', description: 'Mỗi lượt, biến 1 Bài Cơ Bản thành Trảm thường không tính giới hạn.' },
  TIEN_PHONG: { id: 'TIEN_PHONG', name: 'Tiên Phong', type: 'PASSIVE', description: 'Lượt đầu rút thêm 2 lá, không giới hạn Trảm.' },
  TRAN_TIEN: { id: 'TRAN_TIEN', name: 'Trận Tiền', type: 'TRIGGERED', description: 'Khi hạ gục 1 người, rút 2 lá.' },
  KHOI_BINH: { id: 'KHOI_BINH', name: 'Khởi Binh', type: 'OPTIONAL', description: 'Khi người khác dùng Trảm gây sát thương thành công, có thể cho bạn và người đó mỗi người rút 1 lá.' },
  HUYNH_TRUONG: { id: 'HUYNH_TRUONG', name: 'Huynh Trưởng', type: 'OPTIONAL', description: 'Khi mất Máu, có thể đưa 1 lá cho người khác, rồi rút 1 lá.' },
  KIEP_BACH: {
    id: 'KIEP_BACH',
    name: 'Kiếp Bách',
    type: 'TRIGGERED',
    description: 'Sau khi bạn gây sát thương cho người khác, bạn có thể rút 1 lá bài.'
  },
  DAN_TRAN: {
    id: 'DAN_TRAN',
    name: 'Dẫn Trận',
    type: 'PASSIVE',
    description: 'Khoảng cách từ bạn đến người khác -1.'
  },
  THAN_TOAN: {
    id: 'THAN_TOAN',
    name: 'Thần Toán',
    type: 'TRIGGERED',
    description: 'Khi một lá bài phán xét sắp có hiệu lực, bạn có thể xem và thay thế nó bằng 1 lá bài trên tay.'
  },
  THAN_TOC: {
    id: 'THAN_TOC',
    name: 'Thần Tốc',
    type: 'ACTIVE',
    description: 'Bạn có thể bỏ qua giai đoạn Phán xét và Rút bài để coi như đã đánh ra 1 lá [Trảm] (không tính vào giới hạn lượt).'
  },
  THIEU_NIEN: {
    id: 'THIEU_NIEN',
    name: 'Thiếu Niên',
    type: 'TRIGGERED',
    description: 'Khi bạn nhận sát thương, nếu số lá bài trên tay bạn ít hơn máu tối đa, bạn rút thêm 1 lá.'
  },
  BINH_NGO: {
    id: 'BINH_NGO',
    name: 'Bình Ngô',
    type: 'ACTIVE',
    description: 'Giai đoạn ra bài, bạn có thể bỏ 2 lá bài để coi như đánh ra 1 lá [Nam Man Xâm Lấn] hoặc [Vạn Tiễn Tề Phát].'
  },
  THAN_CO: {
    id: 'THAN_CO',
    name: 'Thần Cơ',
    type: 'TRIGGERED',
    description: 'Khi bạn đánh ra lá bài Cẩm nang tức thời, bạn có thể rút 1 lá bài.'
  }
};

export function getHeroById(heroId) {
  return HEROES[heroId] || null;
}

// Accept both the stable server slugs and legacy Unity numeric/display IDs.
// Display-name aliases keep older clients from silently receiving the wrong
// skill set when they omit the new heroId field.
export function normalizeHeroId(heroId, generalName = "") {
  const rawId = String(heroId ?? "").trim();
  const aliases = {
    CAO_LO: "HERO_1",
    DAO_HAN: "HERO_2",
    THI_SACH: "HERO_3",
    LE_CHAN: "HERO_4",
    "47": "LY_THUONG_KIET",
    "53": "TRAN_HUNG_DAO",
    "56": "TRAN_QUOC_TOAN",
    "86": "LE_LOI",
    "87": "NGUYEN_TRAI",
    TRAN_QUOC_TUAN: "TRAN_HUNG_DAO",
    QUANG_TRUNG: "NGUYEN_HUE",
  };
  const rawUpper = rawId.toUpperCase();
  const numericWireId = rawUpper.match(/^HERO_(\d+)$/)?.[1] || "";
  const byId = aliases[rawUpper] || aliases[numericWireId] || rawUpper;
  if (HEROES[byId]) return byId;

  const numericId = Number(rawId);
  if (Number.isInteger(numericId) && numericId >= 1 && numericId <= 100) {
    return `HERO_${numericId}`;
  }

  const key = String(generalName ?? "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/Đ/g, "D")
    .replace(/đ/g, "d")
    .toUpperCase();
  if (key.includes("NGUYEN HUE") || key.includes("QUANG TRUNG")) return "NGUYEN_HUE";
  if (key.includes("CAO LO")) return "HERO_1";
  if (key.includes("DAO HAN")) return "HERO_2";
  if (key.includes("THI SACH")) return "HERO_3";
  if (key.includes("LE CHAN")) return "HERO_4";
  if (key.includes("TRAN HUNG DAO") || key.includes("TRAN QUOC TUAN")) return "TRAN_HUNG_DAO";
  if (key.includes("LY THUONG KIET")) return "LY_THUONG_KIET";
  if (key.includes("TRAN QUOC TOAN")) return "TRAN_QUOC_TOAN";
  if (key.includes("LE LOI")) return "LE_LOI";
  if (key.includes("NGUYEN TRAI")) return "NGUYEN_TRAI";
  return "TRAN_HUNG_DAO";
}

export function getSkillById(skillId) {
  return SKILLS[skillId] || null;
}

export function heroHasSkill(player, skillId) {
  return !!getHeroById(normalizeHeroId(player?.heroId, player?.generalName))?.skills?.includes(skillId);
}
