// Kho Dữ Liệu Tướng & Kỹ Năng - Đại Việt Chiến
export const FACTIONS = {
  DAI_VIET: 'DAI_VIET',
  MINH_QUOC: 'MINH_QUOC',
  CHIEM_THANH: 'CHIEM_THANH',
  TOC_MAN: 'TOC_MAN'
};

export const HEROES = {
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

export const SKILLS = {
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
    "47": "LY_THUONG_KIET",
    "53": "TRAN_HUNG_DAO",
    "56": "TRAN_QUOC_TOAN",
    "86": "LE_LOI",
    "87": "NGUYEN_TRAI",
    TRAN_QUOC_TUAN: "TRAN_HUNG_DAO",
    QUANG_TRUNG: "NGUYEN_HUE",
  };
  const byId = aliases[rawId.toUpperCase()] || rawId.toUpperCase();
  if (HEROES[byId]) return byId;

  const key = String(generalName ?? "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/Đ/g, "D")
    .replace(/đ/g, "d")
    .toUpperCase();
  if (key.includes("NGUYEN HUE") || key.includes("QUANG TRUNG")) return "NGUYEN_HUE";
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
