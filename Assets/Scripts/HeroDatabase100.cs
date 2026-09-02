using System;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Dữ liệu 100 Danh Tướng Lịch Sử Đại Việt
/// - ID: 1..100
/// - Tên ngắn gọn (KHÔNG chứa phần ngoặc phụ)
/// - Thế Lực, Số Máu, Tuyệt Kỹ, Mô Tả, Đường dẫn Avatar
/// - Cơ chế 10 Tướng Free mỗi tuần (Reset 00:00 Thứ 2 hàng tuần)
/// - Lọc danh sách tướng khả dụng (Chỉ xuất hiện tướng đã sở hữu + tướng free tuần)
/// </summary>
public static class HeroDatabase100
{
    [System.Serializable]
    public class HeroData
    {
        public int id;
        public string name;
        public string faction;
        public int maxHp;
        public string skillName;
        public string skillDesc;
        public string avatarPath;
    }

    private static readonly Dictionary<int, HeroData> heroDict = new Dictionary<int, HeroData>();
    private static readonly List<HeroData> allHeroesList = new List<HeroData>();

    public static IReadOnlyList<HeroData> AllHeroes => allHeroesList;

    static HeroDatabase100()
    {
        InitAllHeroes();
    }

    public static HeroData GetHero(int id)
    {
        if (heroDict.TryGetValue(id, out var h)) return h;
        return heroDict.TryGetValue(47, out var defH) ? defH : allHeroesList[0]; // Lý Thường Kiệt default
    }

    public static HeroData GetHeroByName(string name)
    {
        if (string.IsNullOrEmpty(name)) return GetHero(47);
        var found = allHeroesList.Find(h => h.name.IndexOf(name, StringComparison.OrdinalIgnoreCase) >= 0);
        return found ?? GetHero(47);
    }

    /// <summary>
    /// Tính toán 10 tướng Free ngẫu nhiên cho tuần hiện tại (Reset mỗi 00:00 Thứ 2 theo giờ Việt Nam UTC+7).
    /// </summary>
    public static HashSet<int> GetWeeklyFreeHeroIds()
    {
        DateTime nowVn = DateTime.UtcNow.AddHours(7);
        int diff = (7 + (nowVn.DayOfWeek - DayOfWeek.Monday)) % 7;
        DateTime lastMonday = nowVn.Date.AddDays(-1 * diff);
        int weekSeed = lastMonday.Year * 1000 + lastMonday.DayOfYear;

        var rng = new System.Random(weekSeed);
        var candidates = new List<int>();
        for (int i = 1; i <= 100; i++) candidates.Add(i);

        var freeSet = new HashSet<int>();
        while (freeSet.Count < 10 && candidates.Count > 0)
        {
            int idx = rng.Next(candidates.Count);
            freeSet.Add(candidates[idx]);
            candidates.RemoveAt(idx);
        }
        return freeSet;
    }

    /// <summary>
    /// Kiểm tra người chơi đã sở hữu tướng này chưa (Dựa vào Appwrite / AuthUI.CurrentGenerals).
    /// Mặc định người chơi luôn sở hữu Lý Thường Kiệt (ID 47).
    /// </summary>
    public static bool IsHeroOwned(int heroId)
    {
        if (AuthUI.IsAdmin) return true; // Tài khoản Admin sở hữu toàn bộ 100 danh tướng
        if (heroId == 47) return true; // Lý Thường Kiệt khởi đầu
        string gens = AuthUI.CurrentGenerals;
        if (string.IsNullOrEmpty(gens)) return heroId == 47;
        var hero = GetHero(heroId);
        string[] parts = gens.Split(',', StringSplitOptions.RemoveEmptyEntries);
        foreach (var p in parts)
        {
            string trimmed = p.Trim();
            if (int.TryParse(trimmed, out int parsedId) && parsedId == heroId) return true;
            if (trimmed.Equals(hero.name, StringComparison.OrdinalIgnoreCase)) return true;
            if (!string.IsNullOrEmpty(hero.avatarPath) && trimmed.Equals(hero.avatarPath.Replace("UI/", ""), StringComparison.OrdinalIgnoreCase)) return true;
        }
        return false;
    }

    /// <summary>
    /// Lấy danh sách tướng được phép xuất hiện trong giao diện Chọn Tướng
    /// (CHỈ xuất hiện tướng đã sở hữu và 10 tướng miễn phí tuần).
    /// </summary>
    public static List<HeroData> GetAvailablePickHeroes()
    {
        // Nếu tài khoản có nhãn admin trong Appwrite -> Xuất hiện toàn bộ 100 danh tướng
        if (AuthUI.IsAdmin)
        {
            return new List<HeroData>(allHeroesList);
        }

        var weeklyFree = GetWeeklyFreeHeroIds();
        var available = new List<HeroData>();
        foreach (var h in allHeroesList)
        {
            if (weeklyFree.Contains(h.id) || IsHeroOwned(h.id))
            {
                available.Add(h);
            }
        }
        return available;
    }

    /// <summary>
    /// Nạp Sprite Avatar tướng, tự động fallback nếu chưa có file.
    /// </summary>
    public static Sprite GetAvatarSprite(string path)
    {
        if (!string.IsNullOrEmpty(path))
        {
            var spr = Resources.Load<Sprite>(path);
            if (spr != null) return spr;
            var tex = Resources.Load<Texture2D>(path);
            if (tex != null)
            {
                return Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), new Vector2(0.5f, 0.5f), 100f);
            }
        }
        var defSpr = Resources.Load<Sprite>("UI/ly_thuong_kiet");
        if (defSpr != null) return defSpr;
        var defTex = Resources.Load<Texture2D>("UI/ly_thuong_kiet");
        if (defTex != null)
        {
            return Sprite.Create(defTex, new Rect(0, 0, defTex.width, defTex.height), new Vector2(0.5f, 0.5f), 100f);
        }
        var altSpr = Resources.Load<Sprite>("UI/game_avatar");
        if (altSpr != null) return altSpr;
        return null;
    }

    private static void InitAllHeroes()
    {
        heroDict.Clear();
        allHeroesList.Clear();

        AddHero(1, "Cao Lỗ", "Âu Lạc", 4, "Chế Nỏ", "Bạn có thể dùng bất kỳ lá bài chất Bích (♠) như lá trang bị Nỏ Thần Kim Quy.", "UI/cao_lo");
        AddHero(2, "Đào Hãn", "Âu Lạc", 4, "Xạ Thuẫn", "Khoảng cách khi bạn dùng Trảm lên mục tiêu luôn được giảm 2.", "UI/dao_han");
        AddHero(3, "Thi Sách", "Thời Trưng Vương", 4, "Hịch Nghĩa", "Khi bạn rơi vào trạng thái Cận Tử và được cứu sống, bạn lập tức rút 2 lá bài.", "UI/thi_sach");
        AddHero(4, "Lê Chân", "Thời Trưng Vương", 3, "Triều Dâng", "Một lần mỗi lượt, chỉ định hủy 1 lá trang bị của 1 người khác.", "UI/le_chan");
        AddHero(5, "Thánh Thiên", "Thời Trưng Vương", 4, "Dũng Nữ", "Đòn Trảm của bạn khiến mục tiêu phải đánh ra 2 lá Đỡ mới có thể triệt tiêu nếu mục tiêu có lượng Máu hiện tại nhiều hơn bạn.", "UI/thanh_thien");
        AddHero(6, "Bát Nàn", "Thời Trưng Vương", 3, "Trinh Liệt", "Mỗi khi chịu sát thương từ đòn đánh của người chơi khác, bạn được rút ngẫu nhiên 1 lá bài trên tay của người gây sát thương.", "UI/bat_nan");
        AddHero(7, "Nàng Nội", "Thời Trưng Vương", 3, "Tiên Phong", "Trong lượt đầu tiên của trận đấu, bạn được rút thêm 2 lá bài và không bị giới hạn số lần ra lá Trảm trong Giai đoạn Ra bài.", "UI/nang_noi");
        AddHero(8, "Triệu Quốc Đạt", "Khởi nghĩa Bà Triệu", 4, "Khởi Binh", "Khi đồng minh cùng thế lực dùng Trảm gây sát thương thành công, họ có thể chọn cho bạn rút 1 lá bài.", "UI/trieu_quoc_dat");
        AddHero(9, "Triệu Thị Trinh", "Khởi nghĩa Bà Triệu", 4, "Trảm Kình", "Khi bạn đánh ra lá Trảm - Hỏa hoặc Trảm - Lôi, nếu trúng đích, sát thương gây ra được tăng thêm +1.", "UI/ba_trieu");
        AddHero(10, "Lý Bí", "Vạn Xuân", 4, "Dựng Nước", "Đầu Giai đoạn Rút bài, bạn có thể bỏ qua việc rút bài để hồi 1 Máu và thu 1 lá chất Cơ (♥) từ xấp bài bỏ vào tay.", "UI/ly_bi");
        AddHero(11, "Triệu Túc", "Vạn Xuân", 4, "Tùng Nghĩa", "Khi vùng trang bị của bạn có ít nhất 1 lá Chiến Mã hoặc Áo Giáp, giới hạn bài giữ trên tay cuối lượt của bạn được tăng thêm +1.", "UI/trieu_tuc");
        AddHero(12, "Tinh Thiều", "Vạn Xuân", 3, "Văn Sách", "Trong Giai đoạn Ra bài, giới hạn 1 lần, bạn có thể đổi 1 lá Cẩm Nang trên tay lấy 1 lá Bài Cơ Bản ngẫu nhiên từ xấp bài rút.", "UI/tinh_thieu");
        AddHero(13, "Phạm Tu", "Vạn Xuân", 4, "Trấn Nam", "Bạn miễn nhiễm hoàn toàn với sát thương từ Cẩm Nang Bãi Cọc Ngầm. Khi bạn dùng Trảm Thường Đen, mục tiêu không thể kích hoạt hiệu ứng của Giáp Đồng Sơn Vi.", "UI/pham_tu");
        AddHero(14, "Triệu Quang Phục", "Vạn Xuân", 4, "Dạ Trạch", "Khi bạn không còn lá bài nào trên tay, bạn không thể trở thành mục tiêu của các đòn Trảm Thường.", "UI/trieu_quang_phuc");
        AddHero(15, "Phùng Hưng", "Thời Bắc thuộc", 4, "Phục Hổ", "Khi bạn sử dụng lá Thách Đấu hoặc bị người khác chỉ định bởi Thách Đấu, đối phương phải ra 2 lá Trảm cho mỗi lần đáp trả.", "UI/phung_hung");
        AddHero(16, "Phùng Hải", "Thời Bắc thuộc", 4, "Lực Địch", "Bạn có thể trang bị tối đa 2 lá Vũ Khí cùng lúc trên vùng trang bị của mình.", "UI/phung_hai");
        AddHero(17, "Mai Thúc Loan", "Thời Bắc thuộc", 4, "Vạn An", "Bạn có thể dùng 2 lá bài màu Đen bất kỳ trên tay để xem như vừa sử dụng lá Cẩm Nang Bãi Cọc Ngầm.", "UI/mai_thuc_loan");
        AddHero(18, "Khúc Thừa Dụ", "Thời Tự Chủ", 3, "Khoan Giản", "Trong Giai đoạn Bỏ bài, giới hạn số bài bạn được giữ trên tay được cộng thêm bằng đúng số trang bị bạn đang mang.", "UI/khuc_thua_du");
        AddHero(19, "Khúc Hạo", "Thời Tự Chủ", 3, "Khoan Hòa", "Cuối lượt của bạn, nếu bạn không gây sát thương cho bất kỳ ai trong lượt đó, bạn và tối đa 1 người chơi khác do bạn chọn cùng được rút 1 lá bài.", "UI/khuc_hao");
        AddHero(20, "Dương Đình Nghệ", "Thời Tự Chủ", 4, "Nghĩa Tử", "Khi một người chơi khác bị nhận sát thương, bạn có thể bỏ 2 lá bài trên tay để chịu thay 1 sát thương cho họ.", "UI/duong_dinh_nghe");
        AddHero(21, "Kiều Công Tiễn", "Thời Bắc thuộc/Tiền Ngô", 3, "Nghịch Ý", "Khi trở thành mục tiêu của đòn Trảm, bạn có thể bỏ 2 lá bài trên tay để chuyển mục tiêu của đòn Trảm đó sang 1 người chơi khác bất kỳ.", "UI/kieu_cong_tien");
        AddHero(22, "Ngô Quyền", "Thời Ngô", 4, "Thủy Chiến", "Bạn có thể dùng bất kỳ lá bài chất Rô (♦) hoặc Chuồn (♣) như một lá Bãi Cọc Ngầm; bản thân bạn miễn nhiễm sát thương từ Bãi Cọc Ngầm.", "UI/ngo_quyen");
        AddHero(23, "Dương Tam Kha", "Thời Ngô", 4, "Đoạt Vị", "Khi bạn tiêu diệt một người chơi, bạn thu lấy toàn bộ số bài trên tay và vùng trang bị của nạn nhân.", "UI/duong_tam_kha");
        AddHero(24, "Ngô Xương Ngập", "Thời Ngô", 3, "Thiên Cảm", "Khi lượng Máu hiện tại của bạn từ 1 trở xuống, bạn không thể bị đặt các lá Cẩm Nang Trì Hoãn (Cắt Đường Lương, Trầm Ảo Sa Bẫy, Thần Sấm Báo Ứng).", "UI/ngo_xuong_ngap");
        AddHero(25, "Ngô Xương Văn", "Thời Ngô", 4, "Nam Tấn", "Mỗi khi đòn Trảm của bạn gây sát thương thành công lên mục tiêu, bạn được rút ngay 1 lá bài.", "UI/ngo_xuong_van");
        AddHero(26, "Đỗ Cảnh Thạc", "Thời 12 Sứ Quân", 4, "Cát Cứ", "Mỗi khi bị đối phương chọn làm mục tiêu của Vườn Không Nhà Trống hoặc Đột Kích Trộm Lương, bạn lập tức được rút 1 lá bài.", "UI/do_canh_thac");
        AddHero(27, "Kiều Thuận", "Thời 12 Sứ Quân", 4, "Hồi Hồ", "Nếu trong lượt của mình bạn không sử dụng lá Trảm nào, sát thương đầu tiên bạn nhận cho tới lượt kế tiếp của bạn được giảm đi 1 điểm.", "UI/kieu_thuan");
        AddHero(28, "Nguyễn Siêu", "Thời 12 Sứ Quân", 4, "Liệt Chiến", "Khi tham gia vào lá Thách Đấu (do bạn dùng hoặc người khác dùng vào bạn), nếu bạn là người chiến thắng, bạn hồi phục ngay 1 Máu.", "UI/nguyen_sieu");
        AddHero(29, "Lã Đường", "Thời 12 Sứ Quân", 4, "Tế Giang", "Khi dùng Trảm nhắm vào mục tiêu không trang bị lá Chiến Mã (+1 Khoảng cách), Tầm đánh của bạn tính là không giới hạn khoảng cách.", "UI/la_duong");
        AddHero(30, "Đinh Bộ Lĩnh", "Thời Đinh", 4, "Cờ Lau", "Mỗi khi đòn Trảm của bạn gây sát thương lên mục tiêu, bạn được chọn: Rút 1 lá bài từ xấp rút HOẶC phá hủy 1 lá trang bị của nạn nhân.", "UI/dinh_bo_linh");
        AddHero(31, "Đinh Liễn", "Thời Đinh", 4, "Trữ Quân", "Đầu Giai đoạn Rút bài, bạn có thể tự giảm 1 Máu để được rút thêm 2 lá bài.", "UI/dinh_lien");
        AddHero(32, "Đinh Điền", "Thời Đinh", 4, "Trung Tiết", "Khi chúa công hoặc người chơi cùng phe nhận sát thương chí tử, bạn có thể tự mất 1 Máu để họ hồi lại 1 Máu ngay lập tức.", "UI/dinh_dien");
        AddHero(33, "Nguyễn Bặc", "Thời Đinh", 4, "Định Quốc", "Bạn có thể dùng bất kỳ lá bài chất Bích (♠) như lá Thách Đấu.", "UI/nguyen_bac");
        AddHero(34, "Phạm Hạp", "Thời Đinh", 4, "Tận Trung", "Mỗi khi có người chơi khác sử dụng Bánh Chưng để hồi máu, bạn được rút 1 lá bài từ xấp bài rút.", "UI/pham_hap");
        AddHero(35, "Lê Hoàn", "Thời Tiền Lê", 4, "Phá Tống", "Khi đánh ra lá Trảm, bạn có thể bỏ thêm 1 lá bài trên tay để đòn Trảm đó không thể bị đối phương dùng Đỡ triệt tiêu.", "UI/le_hoan");
        AddHero(36, "Dương Vân Nga", "Thời Đinh / Tiền Lê", 3, "Trao Bào", "Trong Giai đoạn Ra bài, bạn có thể chuyển 1 lá bài trang bị từ tay hoặc vùng trang bị của mình cho người chơi khác; người đó hồi 1 Máu và bạn được rút 1 lá bài.", "UI/duong_van_nga");
        AddHero(37, "Lê Long Đĩnh", "Thời Tiền Lê", 4, "Bạo Nộ", "Bạn có thể sử dụng lá Hủ Rượu không giới hạn số lần trong một lượt; cuối lượt nếu không gây sát thương cho ai, bạn phải tự mất 1 Máu.", "UI/le_long_dinh");
        AddHero(38, "Đào Cam Mộc", "Thời Tiền Lê / Lý", 3, "Phò Tá", "Trong Giai đoạn Rút bài, bạn có thể đưa số bài vừa rút được cho 1 người chơi khác thay vì giữ lại cho bản thân.", "UI/dao_cam_moc");
        AddHero(39, "Lý Công Uẩn", "Thời Lý", 4, "Dời Đô", "Trong Giai đoạn Ra bài, giới hạn 1 lần, bạn có thể bỏ toàn bộ bài trên tay để rút lại số lượng lá bài tương đương từ xấp rút.", "UI/ly_cong_uan");
        AddHero(40, "Lý Phật Mã", "Thời Lý", 4, "Thân Chinh", "Khi bạn lần đầu dùng Trảm gây sát thương thành công cho mục tiêu trong lượt, bạn được quyền đánh thêm 1 lá Trảm nữa trong lượt đó.", "UI/ly_phat_ma");
        AddHero(41, "Lý Nhật Tôn", "Thời Lý", 4, "Đại Việt", "Đầu lượt, bạn chọn 1 chất bài (♠, ♥, ♣, ♦); trong lượt đó, mỗi khi bạn đánh ra 1 lá bài có chất đã chọn, bạn lập tức được rút 1 lá bài.", "UI/ly_nhat_ton");
        AddHero(42, "Lý Đạo Thành", "Thời Lý", 3, "Can Gián", "Khi bất kỳ người chơi nào bị đặt Cẩm Nang Trì Hoãn, bạn có thể bỏ 1 lá bài màu Đỏ trên tay để hủy bỏ hoàn toàn lá Cẩm Nang đó.", "UI/ly_dao_thanh");
        AddHero(43, "Ỷ Lan", "Thời Lý", 3, "Nhiếp Chính", "Giai đoạn Rút bài của bạn được rút 3 lá bài thay vì 2. Trong lượt, bạn có thể tặng 1 lá bài trên tay cho đồng minh.", "UI/y_lan");
        AddHero(44, "Tông Đản", "Thời Lý", 4, "Thổ Binh", "Khi tấn công mục tiêu ở Khoảng cách <=2, đòn Trảm của bạn không thể bị vô hiệu hóa bởi các lá Đỡ có giá trị từ 2->5.", "UI/tong_dan");
        AddHero(45, "Thân Cảnh Phúc", "Thời Lý", 4, "Động Phục", "Mỗi khi bạn chịu sát thương từ các lá Cẩm Nang, bạn lập tức được rút 2 lá bài.", "UI/than_canh_phuc");
        AddHero(46, "Tô Hiến Thành", "Thời Lý", 3, "Thiết Diện", "Bạn miễn nhiễm hoàn toàn với các hiệu ứng ép bỏ bài hoặc cướp bài từ Vườn Không Nhà Trống và Đột Kích Trộm Lương.", "UI/to_hien_thanh");
        AddHero(47, "Lý Thường Kiệt", "Thời Lý", 4, "Tiến Thoái", "Bạn có thể sử dụng lá Trảm như lá Đỡ, và sử dụng lá Đỡ như lá Trảm.", "UI/ly_thuong_kiet");
        AddHero(48, "Trần Cảnh", "Thời Trần", 4, "Khai Sáng", "Mỗi khi bạn lắp một lá bài Vũ Khí hoặc Áo Giáp vào vùng trang bị của mình, bạn được hồi ngay 1 Máu.", "UI/tran_canh");
        AddHero(49, "Trần Thủ Độ", "Thời Trần", 4, "Chuyên Chế", "Trong Giai đoạn Ra bài, bạn có thể bỏ 1 lá bài trên tay để chỉ định hủy 1 lá trang bị của người khác đang đeo trang bị; người đó phải ra 1 lá Trảm hoặc mất 1 Máu.", "UI/tran_thu_do");
        AddHero(50, "Trần Liễu", "Thời Trần", 4, "Ấp Phụ", "Khi bạn bị mất Máu do hành động của người chơi khác, bạn được rút 1 lá bài từ xấp rút và lấy 1 lá Trảm từ xấp bài bỏ vào tay (nếu có).", "UI/tran_lieu");
        AddHero(51, "Trần Hoảng", "Thời Trần", 4, "Hội Nghị", "Khi bạn hoặc người chơi khác sử dụng lá Mở Kho Cứu Tế, bạn được chỉ định thêm người, bạn và họ rút thêm 1 lá bài từ xấp bài rút.", "UI/tran_hoang");
        AddHero(52, "Trần Khâm", "Thời Trần", 4, "Thiền Tâm", "Khi rơi vào trạng thái Cận Tử (0 Máu), bạn có thể bỏ 2 lá bài trên tay để tự hồi phục 1 Máu mà không cần dùng Bánh Chưng hay Hủ Rượu.", "UI/tran_kham");
        AddHero(53, "Trần Quốc Tuấn", "Thời Trần", 4, "Hịch Tướng", "Trong Giai đoạn Ra bài, bạn có thể chọn phát động lệnh tập kích: Từng người chơi có thể tự nguyện bỏ 1 lá Trảm để giúp bạn rút 1 lá bài.", "UI/tran_hung_dao");
        AddHero(54, "Trần Quang Khải", "Thời Trần", 4, "Thái Bình", "Cuối lượt của bạn, nếu bạn không sử dụng bất kỳ lá Trảm nào trong lượt đó, bạn có thể lấy 1 lá Áo Giáp hoặc Chiến Mã từ xấp bài bỏ gắn trực tiếp vào vùng trang bị của mình.", "UI/tran_quang_khai");
        AddHero(55, "Trần Nhật Duật", "Thời Trần", 3, "Đồng Hóa", "Khi trở thành mục tiêu của Thách Đấu hoặc Đột Kích Trộm Lương, bạn có thể đổi 1 lá bài trên tay của mình với 1 lá bài ngẫu nhiên trên tay kẻ phát động trước khi giải quyết hiệu ứng.", "UI/tran_nhat_duat");
        AddHero(56, "Trần Quốc Toản", "Thời Trần", 4, "Phá Cường Địch", "Trong lượt, nếu vùng trang bị của bạn chưa gắn Vũ Khí, đòn Trảm đầu tiên bạn đánh ra sẽ gây thêm +1 sát thương nếu trúng đích.", "UI/tran_quoc_toan");
        AddHero(57, "Trần Bình Trọng", "Thời Trần", 4, "Bảo Quốc", "Khi bạn bị hạ gục, bạn có thể chỉ định kẻ tiêu diệt mình phải hủy toàn bộ bài trong vùng trang bị và bỏ 2 lá bài trên tay.", "UI/tran_binh_trong");
        AddHero(58, "Trần Khánh Dư", "Thời Trần", 4, "Đoạt Lương", "Khi bạn sử dụng thành công lá Cắt Đường Lương lên mục tiêu bất kỳ, bạn lập tức được rút 2 lá bài từ xấp rút.", "UI/tran_khanh_du");
        AddHero(59, "Phạm Ngũ Lão", "Thời Trần", 4, "Phục Kích", "Giới hạn 1 lượt 1 lần, bạn có thể dùng bất kỳ lá bài màu Đen nào trên tay như một lá Cẩm Nang Đột Kích Trộm Lương.", "UI/pham_ngu_lao");
        AddHero(60, "Yết Kiêu", "Thời Trần", 4, "Thấu Thủy", "Bạn miễn nhiễm hoàn toàn với sát thương từ lá Bãi Cọc Ngầm. Bạn có thể dùng bất kỳ lá Trảm nào như một lá Trảm - Lôi.", "UI/yet_kieu");
        AddHero(61, "Dã Tượng", "Thời Trần", 4, "Ngự Tượng", "Bạn mặc định sở hữu hiệu ứng tăng khoảng cách của Voi Chiến Đại Việt (+1 Khoảng cách) mà không cần phải trang bị lá bài này, nếu trang bị, khoảng cách phòng thủ của bạn trở thành +2.", "UI/da_tuong");
        AddHero(62, "Đỗ Khắc Chung", "Thời Trần", 3, "Thuyết Khách", "Khi trở thành mục tiêu của đòn Trảm, bạn có thể bỏ 1 lá Cẩm Nang bất kỳ trên tay để vô hiệu hóa hoàn toàn đòn đánh đó.", "UI/do_khac_chung");
        AddHero(63, "Hà Đặc", "Thời Trần", 4, "Tráng Khí", "Khi bạn đánh ra lá Trảm, nếu mục tiêu dùng lá Đỡ để triệt tiêu đòn đánh, bạn lập tức được rút 1 lá bài từ xấp bài rút.", "UI/ha_dac");
        AddHero(64, "Hà Chương", "Thời Trần", 4, "Thác Binh", "Mỗi khi bạn nhận sát thương, bạn được xem 2 lá bài trên cùng của xấp bài rút, lấy 1 lá vào tay và đặt 1 lá còn lại xuống đáy xấp bài.", "UI/ha_chuong");
        AddHero(65, "Nguyễn Khoái", "Thời Trần", 4, "Tiệp Lộ", "Khi bạn sử dụng lá Bãi Cọc Ngầm, bạn có thể chỉ định tối đa 2 người chơi khác không phải chịu ảnh hưởng của lá bài này.", "UI/nguyen_khoai");
        AddHero(66, "Trần Thì Kiến", "Thời Trần", 3, "Cương Trực", "Đối phương không thể sử dụng lá Diệu Kế Phá Mưu để vô hiệu hóa các lá Cẩm Nang do bạn đánh ra.", "UI/tran_thi_kien");
        AddHero(67, "Chu Văn An", "Thời Trần", 3, "Thất Trảm", "Trong Giai đoạn Ra bài, giới hạn 2 lần, bạn có thể bỏ 2 lá bài cùng chất trên tay để phá hủy 1 lá bài bất kỳ trong vùng chơi của một người chơi khác, sau đó rút 1 lá.", "UI/chu_van_an");
        AddHero(68, "Trương Hán Siêu", "Thời Trần", 3, "Bạch Đằng Phú", "Khi bạn sử dụng lá Cẩm Nang Dụng Binh Như Thần, bạn được rút 3 lá bài thay vì 2 lá bài từ xấp rút.", "UI/truong_han_sieu");
        AddHero(69, "Mạc Đĩnh Chi", "Thời Trần", 3, "Lưỡng Quốc", "Giới hạn bài giữ trên tay tối đa trong Giai đoạn Bỏ bài của bạn luôn bằng Máu tối đa của bạn cộng thêm 1.", "UI/mac_dinh_chi");
        AddHero(70, "Đoàn Nhữ Hài", "Thời Trần", 3, "Sứ Giả", "Trong Giai đoạn Ra bài, bạn có thể đưa 1 lá bài trên tay cho một người chơi khác để lấy 1 lá trang bị từ vùng trang bị của họ đưa về tay mình.", "UI/doan_nhu_hai");
        AddHero(71, "Trần Nghệ Tông", "Thời Trần", 4, "Bảo Thủ", "Bạn miễn nhiễm hoàn toàn với hiệu ứng giam cầm của Cẩm Nang Trì Hoãn Trầm Ảo Sa Bẫy.", "UI/tran_nghe_tong");
        AddHero(72, "Trần Duệ Tông", "Thời Trần", 4, "Trực Chiến", "Khi bạn đánh ra lá Trảm, đối phương bắt buộc phải sử dụng lá Đỡ >=7 điểm mới có thể triệt tiêu đòn đánh.", "UI/tran_due_tong");
        AddHero(73, "Trần Khát Chân", "Thời Trần", 4, "Hỏa Pháo", "Khi bạn sử dụng lá Trảm - Hỏa gây sát thương thành công cho mục tiêu, bạn có thể bắt mục tiêu phải bỏ thêm 1 lá bài trên tay hoặc nhận thêm 1 sát thương thường.", "UI/tran_khat_chan");
        AddHero(74, "Đỗ Tử Bình", "Thời Trần", 4, "Úng Binh", "Khi một người chơi cùng thế lực nhận sát thương từ người khác, bạn được quyền rút ngay 1 lá bài từ xấp bài rút.", "UI/do_tu_binh");
        AddHero(75, "Nguyễn Sư Tề", "Thời Trần", 4, "Chấn Giáp", "Mỗi khi bạn lắp một lá Áo Giáp vào vùng trang bị của mình, bạn được rút ngay 1 lá bài từ xấp bài rút.", "UI/nguyen_su_te");
        AddHero(76, "Hồ Quý Ly", "Thời Hồ", 4, "Cải Chế", "Trong Giai đoạn Ra bài, giới hạn 1 lần, bạn có thể bỏ 1 lá bài bất kỳ trên tay để lấy 1 lá Trảm hoặc Đỡ từ xấp bài bỏ vào tay.", "UI/ho_quy_ly");
        AddHero(77, "Hồ Hán Thương", "Thời Hồ", 4, "Tiền Giấy", "Trong Giai đoạn Bỏ bài, các lá bài bạn phải bỏ đi có thể được trao cho các người chơi khác tùy ý thay vì đưa vào xấp bài bỏ.", "UI/ho_han_thuong");
        AddHero(78, "Hồ Nguyên Trừng", "Thời Hồ", 3, "Thần Cơ", "Bạn có thể dùng bất kỳ lá bài Đen nào như lá vũ khí Súng Thần Công Hồ Triều hoặc sử dụng như một lá Trảm - Hỏa.", "UI/ho_nguyen_trung");
        AddHero(79, "Trần Ngỗi", "Hậu Trần", 4, "Phục Hưng", "Đầu Giai đoạn Rút bài, nếu lượng Máu hiện tại của bạn từ 2 trở xuống, bạn được rút thêm 1 lá bài từ xấp rút.", "UI/tran_ngoi");
        AddHero(80, "Trần Quý Khoáng", "Hậu Trần", 4, "Kế Nghiệp", "Khi một đồng minh cùng thế lực bị hạ gục, bạn được thu toàn bộ số bài trên tay và vùng trang bị còn lại của người đó vào tay mình.", "UI/tran_quy_khoang");
        AddHero(81, "Đặng Dung", "Hậu Trần", 4, "Mài Kiếm", "Bạn có thể dùng lá Hủ Rượu như một lá Trảm Thường; đòn Trảm này không thể bị triệt tiêu bởi lá Đỡ.", "UI/dang_dung");
        AddHero(82, "Đặng Tất", "Hậu Trần", 4, "Trận Pháp", "Khi bạn sử dụng lá Cẩm Nang Vườn Không Nhà Trống, bạn có thể chọn đồng thời 2 mục tiêu thay vì 1.", "UI/dang_tat");
        AddHero(83, "Nguyễn Cảnh Chân", "Hậu Trần", 4, "Thủy Binh", "Bạn có thể dùng bất kỳ lá bài chất Chuồn (♣) nào trên tay như một lá Đỡ.", "UI/nguyen_canh_chan");
        AddHero(84, "Nguyễn Cảnh Dị", "Hậu Trần", 4, "Kỵ Chiến", "Khoảng cách tấn công tính từ bạn tới tất cả các người chơi khác luôn được giảm 1 điểm (tương tự hiệu ứng của Ngựa Trắng Thuần Nông). Nếu mang Ngựa Trắng Thuần Nông, khoảng cách sẽ là -2.", "UI/nguyen_canh_di");
        AddHero(85, "Nguyễn Biểu", "Hậu Trần", 3, "Trinh Tiết", "Khi bạn là mục tiêu của lá Thách Đấu, bạn có thể không ra lá Trảm mà không bị mất Máu; thay vào đó, kẻ phát động phải bỏ 1 lá bài trên tay.", "UI/nguyen_bieu");
        AddHero(86, "Lê Lợi", "Khởi nghĩa Lam Sơn", 4, "Khởi Nghĩa", "Khi bạn trang bị vũ khí Kiếm Thuận Thiên, mỗi đòn Trảm của bạn gây trúng đích sẽ gây thêm +1 điểm sát thương. Đầu lượt, nếu trên tay hoặc trang bị chưa có Kiếm Thuận Thiên, nếu Kiếm Thuận Thiên nằm trên chồng bài rút hoặc bài bỏ, thu lấy nó.", "UI/le_loi");
        AddHero(87, "Nguyễn Trãi", "Khởi nghĩa Lam Sơn", 3, "Bình Ngô", "Trong Giai đoạn Ra bài, bạn có thể bỏ 2 lá Cẩm Nang trên tay để chỉ định 1 người chơi phải bỏ toàn bộ bài trên tay xuống xấp bài bỏ.", "UI/nguyen_trai");
        AddHero(88, "Lê Lai", "Khởi nghĩa Lam Sơn", 4, "Liều Thân", "Khi một người chơi khác nhận sát thương chí tử, bạn có thể tự giảm 1 Máu của mình để gánh toàn bộ sát thương đó thay cho mục tiêu.", "UI/le_lai");
        AddHero(89, "Trần Nguyên Hãn", "Khởi nghĩa Lam Sơn", 4, "Thủy Kế", "Bạn có thể sử dụng bất kỳ lá bài mang chất Rô (♦) nào trên tay như một lá Cẩm Nang Bãi Cọc Ngầm.", "UI/tran_nguyen_han");
        AddHero(90, "Lưu Nhân Chú", "Khởi nghĩa Lam Sơn", 4, "Tráng Tiết", "Khi bạn đánh ra lá Trảm - Lôi, đòn đánh này bỏ qua hoàn toàn các hiệu ứng phòng vệ từ các lá Áo Giáp của mục tiêu.", "UI/luu_nhan_chu");
        AddHero(91, "Đinh Liệt", "Khởi nghĩa Lam Sơn", 4, "Thiết Kỵ", "Khi dùng Trảm nhắm vào mục tiêu đang gắn Chiến Mã (+1 Khoảng cách), bạn được quyền bỏ qua hiệu ứng tăng khoảng cách của lá ngựa đó.", "UI/dinh_liet");
        AddHero(92, "Phạm Văn Xảo", "Khởi nghĩa Lam Sơn", 3, "Trấn Tây", "Khi vùng trang bị của bạn hoàn toàn trống, mọi sát thương bạn phải nhận từ các đòn Trảm thường đều được giảm đi 1 điểm.", "UI/pham_van_xao");
        AddHero(93, "Lê Sát", "Khởi nghĩa Lam Sơn", 4, "Dũng Tướng", "Bạn có thể sử dụng bất kỳ lá bài màu Đen nào trên tay như một lá Cẩm Nang Thách Đấu.", "UI/le_sat");
        AddHero(94, "Lê Ngân", "Khởi nghĩa Lam Sơn", 3, "Mật Vũ", "Cuối lượt, bạn có thể đặt úp 1 lá bài trên tay vào khu vực riêng; khi bị nhắm bởi Trảm, bạn có thể lật lá bài này lên để tính như vừa đánh ra 1 lá Đỡ.", "UI/le_ngan");
        AddHero(95, "Nguyễn Xí", "Khởi nghĩa Lam Sơn", 4, "Khuyển Đội", "Mỗi khi đòn Trảm của bạn gây sát thương thành công, bạn được rút ngẫu nhiên 1 lá bài trên tay của nạn nhân.", "UI/nguyen_xi");
        AddHero(96, "Trịnh Khả", "Khởi nghĩa Lam Sơn", 4, "Bình Định", "Khi bạn sử dụng lá Vườn Không Nhà Trống lên mục tiêu, thay vì bạn chọn, nạn nhân phải đồng thời phải tự bỏ 1 lá bài trên tay và chọn phá hủy 1 lá bài trong vùng trang bị (nếu có), sau đó bạn rút 1 lá.", "UI/trinh_kha");
        AddHero(97, "Nguyễn Chích", "Khởi nghĩa Lam Sơn", 3, "Bồ Câu", "Tầm tác dụng của các lá Cẩm Nang do bạn sử dụng không bị giới hạn bởi khoảng cách bàn chơi.", "UI/nguyen_chich");
        AddHero(98, "Bùi Bị", "Khởi nghĩa Lam Sơn", 4, "Dũng Hãn", "Khi bạn sử dụng Trảm nhắm vào mục tiêu có lượng Máu hiện tại nhiều hơn bạn, đòn Trảm đó không thể bị đối phương dùng lá Đỡ triệt tiêu.", "UI/bui_bi");
        AddHero(99, "Lê Khôi", "Khởi nghĩa Lam Sơn", 4, "Khai Biên", "Mỗi khi bạn tiêu diệt thành công một người chơi khác, bạn lập tức được hồi 1 Máu và rút thêm 2 lá bài từ xấp bài rút.", "UI/le_khoi");
        AddHero(100, "Nguyễn Nhữ Lãm", "Khởi nghĩa Lam Sơn", 4, "Trấn Ải", "Bạn hoàn toàn miễn nhiễm với các lá Cẩm Nang Trì Hoãn.", "UI/nguyen_nhu_lam");
    }

    private static void AddHero(int id, string name, string faction, int hp, string skillName, string skillDesc, string avatar)
    {
        var h = new HeroData
        {
            id = id,
            name = name,
            faction = faction,
            maxHp = hp,
            skillName = skillName,
            skillDesc = skillDesc,
            avatarPath = avatar
        };
        heroDict[id] = h;
        allHeroesList.Add(h);
    }
}