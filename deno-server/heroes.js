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
  HERO_9: { id: 'HERO_9', name: 'Triệu Thị Trinh', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['CHIEN_TUONG', 'OAI_NHUOC'] },
  HERO_10: { id: 'HERO_10', name: 'Lý Bí', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['DUNG_NUOC', 'XUNG_DE'] },
  HERO_11: { id: 'HERO_11', name: 'Triệu Túc', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['TUNG_NGHIA', 'TRUNG_KIEN'] },
  HERO_12: { id: 'HERO_12', name: 'Tinh Thiều', faction: FACTIONS.DAI_VIET, maxHp: 3, skills: ['VAN_SACH', 'HAN_LAM'] },
  HERO_13: { id: 'HERO_13', name: 'Phạm Tu', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['TRAN_NAM', 'HOA_DAN'] },
  HERO_14: { id: 'HERO_14', name: 'Triệu Quang Phục', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['DA_TRACH', 'NO_DINH'] },
  HERO_15: { id: 'HERO_15', name: 'Phùng Hưng', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['PHUC_HO', 'AN_DAN'] },
  HERO_16: { id: 'HERO_16', name: 'Phùng Hải', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['LUC_DICH', 'HUNG_SUC'] },
  HERO_17: { id: 'HERO_17', name: 'Mai Thúc Loan', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['VAN_AN', 'DE_NGHIEP'] },
  HERO_18: { id: 'HERO_18', name: 'Khúc Thừa Dụ', faction: FACTIONS.DAI_VIET, maxHp: 3, skills: ['KHOAN_GIAN', 'CHINH_THONG'] },
  HERO_19: { id: 'HERO_19', name: 'Khúc Hạo', faction: FACTIONS.DAI_VIET, maxHp: 3, skills: ['KHOAN_HOA', 'CAI_CACH'] },
  HERO_20: { id: 'HERO_20', name: 'Dương Đình Nghệ', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['NGHIA_TU', 'DUONG_BINH'] },
  HERO_21: { id: 'HERO_21', name: 'Kiều Công Tiễn', faction: FACTIONS.DAI_VIET, maxHp: 3, skills: ['NGHICH_Y', 'DAN_CAU'] },
  HERO_22: { id: 'HERO_22', name: 'Ngô Quyền', faction: FACTIONS.DAI_VIET, maxHp: 3, skills: ['THUY_CHIEN', 'COC_NGAM'] },
  HERO_23: { id: 'HERO_23', name: 'Dương Tam Kha', faction: FACTIONS.DAI_VIET, maxHp: 4, skills: ['DOAT_VI', 'XUNG_VUONG'] },
  HERO_24: { id: 'HERO_24', name: 'Ngô Xương Ngập', faction: FACTIONS.DAI_VIET, maxHp: 3, skills: ['THIEN_CAM', 'AN_TICH'] },
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
  3, 3, 4, 3, 4, 4, 4, 4, 4, 4,
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
  CHIEN_TUONG: { id: 'CHIEN_TUONG', name: 'Chiến Tượng', type: 'PASSIVE', description: 'Khi có trang bị trên ô Ngựa, sát thương gây ra bởi Trảm +1.' },
  OAI_NHUOC: { id: 'OAI_NHUOC', name: 'Oai Nhược', type: 'TRIGGERED', description: 'Khi dùng Trảm Hỏa hoặc Trảm Thủy, mục tiêu chọn: bỏ đúng 2 lá trên tay, trong đó có 1 lá Đỡ, để hóa giải Trảm; hoặc chịu sát thương của đòn Trảm.' },
  DUNG_NUOC: { id: 'DUNG_NUOC', name: 'Dựng Nước', type: 'OPTIONAL', description: 'Đầu Giai đoạn Rút bài, có thể bỏ qua rút bài để hồi 1 Máu và lấy ngẫu nhiên 1 lá Cơ từ xấp bỏ.' },
  XUNG_DE: { id: 'XUNG_DE', name: 'Xưng Đế', type: 'PASSIVE', description: 'Khi đầy Máu, giới hạn bài giữ trên tay +2.' },
  TUNG_NGHIA: { id: 'TUNG_NGHIA', name: 'Tùng Nghĩa', type: 'TRIGGERED', description: 'Có Chiến Mã hoặc Áo Giáp: cuối lượt rút 1 lá, giới hạn trữ bài +1.' },
  TRUNG_KIEN: { id: 'TRUNG_KIEN', name: 'Trung Kiên', type: 'OPTIONAL', description: 'Khi một người sắp tử trận, có thể tự giảm 1 Máu để giúp người đó hồi đến 1 Máu.' },
  VAN_SACH: { id: 'VAN_SACH', name: 'Văn Sách', type: 'ACTIVE', description: 'Một lần mỗi lượt, đổi 1 Bài Cơ Bản lấy 1 Cẩm Nang ngẫu nhiên rồi rút 1 lá.' },
  HAN_LAM: { id: 'HAN_LAM', name: 'Hán Lâm', type: 'OPTIONAL', description: 'Mỗi khi dùng thành công Cẩm Nang, xem lá đầu xấp rút, chọn để trên cùng hoặc xuống đáy, sau đó rút 1 lá.' },
  TRAN_NAM: { id: 'TRAN_NAM', name: 'Trấn Nam', type: 'PASSIVE', description: 'Miễn nhiễm sát thương Giặc Tới; Trảm thường Đen bỏ qua Giáp Đồng Sơn Vi.' },
  HOA_DAN: { id: 'HOA_DAN', name: 'Hóa Dân', type: 'OPTIONAL', description: 'Cuối lượt, nếu đang đeo Áo Giáp, có thể bỏ 1 Trang bị để hồi 1 Máu.' },
  DA_TRACH: { id: 'DA_TRACH', name: 'Dạ Trạch', type: 'PASSIVE', description: 'Khi không còn bài trên tay, không thể trở thành mục tiêu của Trảm thường.' },
  NO_DINH: { id: 'NO_DINH', name: 'Nỏ Đỉnh', type: 'PASSIVE', description: 'Khi còn không quá 2 Máu, Trảm có Tầm đánh không giới hạn.' },
  PHUC_HO: { id: 'PHUC_HO', name: 'Phục Hổ', type: 'PASSIVE', description: 'Trong Huyết Chiến có Phùng Hưng, đối phương của Phùng Hưng phải ra 2 Trảm cho mỗi lần đáp trả.' },
  AN_DAN: { id: 'AN_DAN', name: 'An Dân', type: 'OPTIONAL', description: 'Đầu Giai đoạn Rút bài, có thể bỏ qua rút bài để chuyển 1 Cẩm Nang Trì Hoãn sang người khác.' },
  LUC_DICH: { id: 'LUC_DICH', name: 'Lực Địch', type: 'PASSIVE', description: 'Có thể trang bị tối đa 2 Vũ Khí; Tầm đánh cộng dồn.' },
  HUNG_SUC: { id: 'HUNG_SUC', name: 'Hùng Sức', type: 'ACTIVE', description: 'Trong Giai đoạn Ra bài, bỏ 1 Vũ Khí trên tay để gây 1 sát thương cho mục tiêu trong Tầm 1.' },
  VAN_AN: { id: 'VAN_AN', name: 'Vạn An', type: 'ACTIVE', description: 'Bạn có thể dùng 2 lá bài cùng màu bất kỳ trên tay để xem như sử dụng lá Cẩm Nang Bãi Cọc Bạch Đằng. Lần đầu sử dụng trong lượt, rút 1 lá bài.' },
  DE_NGHIEP: { id: 'DE_NGHIEP', name: 'Đế Nghiệp', type: 'TRIGGERED', description: 'Mỗi khi gây sát thương đơn mục tiêu bằng Cẩm Nang, rút 1 lá.' },
  KHOAN_GIAN: { id: 'KHOAN_GIAN', name: 'Khoan Giản', type: 'TRIGGERED', description: 'Sau Giai đoạn Bỏ bài, bạn được rút X lá, giới hạn trữ bài +X (X là một nửa số trang bị bạn đang mang, làm tròn lên, tối thiểu 1).' },
  CHINH_THONG: { id: 'CHINH_THONG', name: 'Chính Thống', type: 'OPTIONAL', description: 'Đầu lượt, chọn 1 người khác; họ chuyển 1 lá trên tay hoặc lộ toàn bộ bài.' },
  KHOAN_HOA: { id: 'KHOAN_HOA', name: 'Khoan Hòa', type: 'OPTIONAL', description: 'Cuối lượt không gây sát thương: bạn và tối đa 1 người khác rút 1 lá.' },
  CAI_CACH: { id: 'CAI_CACH', name: 'Cải Cách', type: 'ACTIVE', description: 'Trong Giai đoạn Ra bài, giới hạn 1 lần, bạn có thể đổi 2 lá bài lấy 2 lá bài mới.' },
  NGHIA_TU: { id: 'NGHIA_TU', name: 'Nghĩa Tử', type: 'OPTIONAL', description: 'Bỏ 1 lá để chịu thay 1 sát thương cho người khác.' },
  DUONG_BINH: { id: 'DUONG_BINH', name: 'Dưỡng Binh', type: 'TRIGGERED', description: 'Mỗi khi chịu thay sát thương, rút 2 lá.' },
  NGHICH_Y: { id: 'NGHICH_Y', name: 'Nghịch Ý', type: 'OPTIONAL', description: 'Khi trở thành mục tiêu Trảm, bỏ 1 lá để chuyển mục tiêu sang người khác trong tầm.' },
  DAN_CAU: { id: 'DAN_CAU', name: 'Dẫn Cầu', type: 'ACTIVE', description: 'Mỗi lượt 1 lần, đưa 1 lá buộc người khác Trảm mục tiêu chỉ định; nếu không, cướp 2 lá vùng chơi.' },
  THUY_CHIEN: { id: 'THUY_CHIEN', name: 'Thủy Chiến', type: 'ACTIVE', description: 'Dùng lá Rô hoặc Chuồn như Bãi Cọc Bạch Đằng; miễn nhiễm Bãi Cọc Bạch Đằng.' },
  COC_NGAM: { id: 'COC_NGAM', name: 'Cọc Ngầm', type: 'TRIGGERED', description: 'Trảm Thủy gây sát thương lên mục tiêu không giáp +1 sát thương.' },
  DOAT_VI: { id: 'DOAT_VI', name: 'Đoạt Vị', type: 'TRIGGERED', description: 'Khi tiêu diệt người chơi, thu toàn bộ bài tay và trang bị của họ.' },
  XUNG_VUONG: { id: 'XUNG_VUONG', name: 'Xưng Vương', type: 'TRIGGERED', description: 'Giai đoạn Rút bài, nếu có nhiều bài tay nhất, rút thêm 1 lá.' },
  THIEN_CAM: { id: 'THIEN_CAM', name: 'Thiên Cảm', type: 'ACTIVE', description: 'Máu không quá 1: miễn nhiễm Cẩm Nang Trì Hoãn, bỏ chúng; đổi Cẩm Nang Trì Hoãn trên tay lấy 2 lá.' },
  AN_TICH: { id: 'AN_TICH', name: 'Ẩn Tích', type: 'OPTIONAL', description: 'Cuối lượt chưa gây sát thương, đặt úp 1 lá; khi cần Đỡ có thể bỏ lá đó như Đỡ.' },
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
  if (key.includes("TRIEU THI TRINH") || key.includes("BA TRIEU")) return "HERO_9";
  if (key.includes("LY BI")) return "HERO_10";
  if (key.includes("TRIEU TUC")) return "HERO_11";
  if (key.includes("TINH THIEU")) return "HERO_12";
  if (key.includes("PHAM TU")) return "HERO_13";
  if (key.includes("TRIEU QUANG PHUC")) return "HERO_14";
  if (key.includes("PHUNG HUNG")) return "HERO_15";
  if (key.includes("PHUNG HAI")) return "HERO_16";
  if (key.includes("MAI THUC LOAN")) return "HERO_17";
  if (key.includes("KHUC THUA DU")) return "HERO_18";
  if (key.includes("KHUC HAO")) return "HERO_19";
  if (key.includes("DUONG DINH NGHE")) return "HERO_20";
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
