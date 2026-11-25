extends RefCounted

## Diverse, historically grounded lobby quotes for all 100 generals (IDs 1..100).
const QUOTES: Dictionary = {
	1: [
		"Nỏ Thần Kim Quy đã lên dây, một phát vạn tiễn!",
		"Thành Cổ Loa vững như bàn thạch, giặc nào dám bén mảng?",
		"Cơ xảo trăm nghề, cũng chỉ vì giữ bình yên non sông.",
	],
	2: [
		"Cung tên bất ly thân, trăm bước xuyên dương.",
		"Giữ chắc cung thuẫn, không để lọt một tên giặc nào!",
		"Tầm mắt đã khóa mục tiêu, chỉ chờ lệnh xuất kích.",
	],
	3: [
		"Hịch nghĩa đã truyền, hào kiệt khắp chốn đều hưởng ứng!",
		"Dù máu chảy đến giọt cuối, chí khí Chu Diên chẳng đổi.",
		"Cùng Trưng Vương phất cờ khởi nghĩa, rửa nhục non sông!",
	],
	4: [
		"An Biên gió lộng, song kiếm dậy sóng Bạch Đằng!",
		"Nữ nhi đất Việt đâu kém đấng mày râu trên sa trường.",
		"Giặc tới bờ cõi, sóng triều sẽ nhấn chìm tất cả!",
	],
	5: [
		"Sét đánh Ngọc Lâm, dũng nữ phá tan đồn giặc!",
		"Đã ra trận là chỉ tiến không lùi!",
		"Thế mạnh như chớp giật, kẻ địch khó lòng trở tay.",
	],
	6: [
		"Dù hiểm nguy trùng trùng, tiết liệt chẳng hề lay chuyển.",
		"Kiếm múa hoa sen, quét sạch bóng thù nơi Tiên La!",
		"Chí lớn trong lòng, ngại gì phong ba bão táp.",
	],
	7: [
		"Tiên phong xông trận, mở đường cho đại quân tiến bước!",
		"Nhanh như gió cuốn, địch chưa kịp đỡ đã gãy giáo.",
		"Có ta dẫn đầu, tướng sĩ cứ vững tin tiến lên!",
	],
	8: [
		"Cửu Chân tụ nghĩa, anh em đồng lòng phá giặc!",
		"Máu Lạc Hồng chảy trong tim, quyết chẳng cúi đầu!",
		"Khi cờ khởi nghĩa phất lên, muôn dân cùng đứng dậy.",
	],
	9: [
		"Ta muốn cưỡi cơn gió mạnh, đạp luồng sóng dữ!",
		"Chém cá kình ở biển Đông, lấy lại giang sơn!",
		"Đâu chịu khom lưng làm tì thiếp cho người phương Bắc!",
	],
	10: [
		"Non sông Nam Việt tự chủ, lập quốc hiệu Vạn Xuân!",
		"Dân ta tự làm chủ vận mệnh đất nước ngàn đời!",
		"Binh pháp trị quốc, giữ cho xã tắc muôn thuở thanh bình.",
	],
	11: [
		"Chu Diên trung kiên, một lòng phò tá Nam Đế.",
		"Giáp sắt chiến mã sẵn sàng bảo vệ chủ tướng.",
		"Tuổi cao chí chẳng giảm, trung nghĩa sáng tựa nhật nguyệt.",
	],
	12: [
		"Một lá thư hay có thể định yên cả ván cờ lớn.",
		"Văn võ song toàn, mưu lược thắng người từ trước khi ra trận.",
		"Đừng xem thường mưu sĩ chốn Hán Lâm!",
	],
	13: [
		"Trấn giữ phương Nam, giặc nghe danh đã khiếp vía.",
		"Gừng càng già càng cay, một đao chém tan quân xâm lược!",
		"Giữ chắc biên ải, tuyệt đối không nhường một tấc đất.",
	],
	14: [
		"Đầm Dạ Trạch sương mù giăng kín, chỉ ta rõ lối tiến lui.",
		"Chờ thời xuất kích, lấy ít địch nhiều thắng lớn!",
		"Đêm tối là đồng minh của Triệu Việt Vương.",
	],
	15: [
		"Tay không đả hổ Đường Lâm, sá chi lũ giặc cỏ!",
		"Lấy lòng an dân làm gốc, lấy dũng khí làm đầu.",
		"Ai dám nghênh chiến một hiệp với Bố Cái Đại Vương?",
	],
	16: [
		"Sức khỏe dời non, song chùy vung lên đất trời rung chuyển!",
		"Một thanh binh khí chưa đủ, hãy chuẩn bị đón cả hai!",
		"Hùng sức xung phong, đánh thẳng vào trung quân địch.",
	],
	17: [
		"Thành Vạn An sừng sững, Hoan Châu dựng cờ độc lập!",
		"Thà đứng dậy mà chiến đấu còn hơn quỳ gối gánh vải!",
		"Hắc Đế hiệu triệu, bốn phương nghĩa sĩ cùng về.",
	],
	18: [
		"Lấy khoan giản trị dân, nước nhà tự khắc hưng thịnh.",
		"Bình tĩnh thu xếp cục diện, từng bước giành lại tự chủ.",
		"Giữ vững chính thống, trăm họ ấm no là thắng lợi lớn nhất.",
	],
	19: [
		"Chính sự cốt ở khoan hòa, khiến muôn dân được nhờ.",
		"Cải cách hợp lòng người, nền tự chủ thêm vững bền.",
		"Thưởng phạt phân minh, chia sẻ cùng đồng đội để cùng thắng.",
	],
	20: [
		"Ba nghìn nghĩa tử đồng cam cộng khổ, sống chết có nhau!",
		"Dưỡng binh chờ thời, một khi ra tay là phải toàn thắng.",
		"Ái Châu hào kiệt tụ hội, thề quét sạch ngoại xâm!",
	],
	21: [
		"Thế cục biến đổi khôn lường, kẻ thức thời mới giữ được mình.",
		"Mũi giáo hướng về ta ư? Khéo léo dẫn sang kẻ khác thôi.",
		"Trên bàn cờ quyền lực, mỗi quân bài đều có giá của nó.",
	],
	22: [
		"Cọc ngầm Bạch Đằng đã đóng kín lòng sông, chờ thủy triều rút!",
		"Hoằng Tháo có liều mạng tiến vào cũng chỉ còn đường diệt vong!",
		"Chấm dứt ngàn năm Bắc thuộc, mở ra kỷ nguyên độc lập!",
	],
	23: [
		"Thời thế tạo anh hùng, quyền bính trong tay chẳng dễ buông.",
		"Đoạt lấy thời cơ trước khi kẻ khác kịp trở tay!",
		"Cổ Loa gió nổi, ai đủ bản lĩnh tranh hùng cùng ta?",
	],
	24: [
		"Tránh mũi nhọn nhất thời, giữ sức chờ ngày quật khởi.",
		"Cẩn trọng ẩn tàng bài tẩy, địch khó lòng đoán thấu.",
		"Thiên Cảm trong lòng, sóng gió nào rồi cũng qua.",
	],
	25: [
		"Nam Tấn Vương xuất quân, mũi nhọn phá mọi trận tuyến!",
		"Loạn lạc phải dẹp yên, kỷ cương triều chính mới vững.",
		"Một đường kiếm quyết đoán, bình sạn trừ gian.",
	],
	26: [
		"Đỗ Động Giang thành cao hào sâu, giữ vững thế cát cứ!",
		"Phòng thủ kiên cố, chờ kẻ địch tự hao binh tổn tướng.",
		"Không dễ gì khuất phục được hào khí đất Cổ Hiền.",
	],
	27: [
		"Án binh bất động tại Hồi Hồ, lấy tĩnh chế động.",
		"Đánh ít mà chắc, bảo toàn lực lượng cho hồi kết.",
		"Làn khói Hồi Hồ che khuất mắt quân trinh sát.",
	],
	28: [
		"Tây Phù Liệt giao tranh liệt chiến, kẻ thắng mới có quyền nói!",
		"Dám đối mặt huyết chiến với Nguyễn Siêu này không?",
		"Càng đánh càng hăng, máu chiến chẳng bao giờ nguội.",
	],
	29: [
		"Tế Giang sóng nước mênh mông, tầm công vươn xa ngàn dặm!",
		"Chiến mã của địch không chạy thoát nổi mũi tên này đâu.",
		"Cướp thời cơ trên từng tấc đất giao tranh.",
	],
	30: [
		"Thuở nhỏ lấy cờ lau tập trận, nay thu giang sơn về một mối!",
		"Mười hai sứ quân rồi sẽ quy phục dưới cờ Vạn Thắng Vương!",
		"Thống nhất non sông Đại Cồ Việt, lập nên cơ đồ muôn thuở!",
	],
	31: [
		"Gánh vác việc quân quốc, chẳng ngại tự tổn thân mình vì đại cuộc.",
		"Nam Việt Vương đứng mũi chịu sào, bảo vệ cơ nghiệp Hoa Lư.",
		"Chữ hiếu chữ trung, trọn vẹn cả đôi đường.",
	],
	32: [
		"Thề cùng định quốc bảo vệ giang sơn nhà Đinh đến hơi thở cuối!",
		"Thấy bạn gặp nguy sao nỡ khoanh tay đứng nhìn?",
		"Lòng trung tiết này, trời đất chứng giám!",
	],
	33: [
		"Định Quốc Công đứng đây, gian thần đừng hòng lộng hành!",
		"Trung nghĩa một lòng, sẵn sàng huyết chiến dẹp loạn!",
		"Giữ gìn phép nước nghiêm minh, đó là bổn phận của ta.",
	],
	34: [
		"Thanh liêm chính trực, hết lòng phụng sự triều đình Hoa Lư.",
		"Khi đồng minh vững vàng, cả đội hình cùng mạnh lên.",
		"Bảo toàn khí tiết ngay cả trong cơn nguy biến nhất.",
	],
	35: [
		"Thập Đạo Tướng Quân xuất trận, phá Tống bình Chiêm!",
		"Sông Bạch Đằng năm xưa lại một lần nữa dậy sóng!",
		"Đã tung đòn Phá Tống, đối phương đừng mong đỡ nổi!",
	],
	36: [
		"Vì xã tắc an nguy, long bào này trao cho người xứng đáng.",
		"Nhiếp chính cân bằng triều cục, lấy nhu thắng cương.",
		"Một bước đi khôn ngoan cứu nguy cho cả trăm họ.",
	],
	37: [
		"Cuồng nộ dâng trào, một lượt chén rượu xoay chuyển càn khôn!",
		"Đã muốn liều mạng với ta thì đừng trách đao kiếm vô tình!",
		"Thế công như vũ bão, chẳng ai cản được cơn bạo nộ này.",
	],
	38: [
		"Thuận lòng trời, hợp ý dân, tiến bước dời cơ nghiệp mới.",
		"Mưu định sẵn trong tay, mọi nước đi đều nằm trong tính toán.",
		"Phò tá minh quân là niềm vinh hạnh lớn nhất đời ta.",
	],
	39: [
		"Đất Thăng Long rồng cuộn hổ ngồi, xứng làm kinh đô muôn đời!",
		"Thiên thời địa lợi đã định, hãy dời đô để mở vận thái bình!",
		"Dân giàu nước mạnh, đó mới là chí lớn của bậc đế vương.",
	],
	40: [
		"Thân chinh ra trận, đánh một đòn chưa đủ phải bồi thêm đòn nữa!",
		"Thế công nối tiếp không ngừng, dồn địch vào chân tường!",
		"Uy nghi thiên tử ngự giá thân chinh, ba quân chấn động!",
	],
	41: [
		"Quốc hiệu Đại Việt vang danh bốn phương từ đây!",
		"Phối hợp đủ sắc bài, biến hóa khôn lường tựa binh pháp.",
		"Chăm lo lê dân, xây dựng cơ đồ cường thịnh.",
	],
	42: [
		"Lời can gián tuy nghịch nhĩ nhưng giữ cho nước nhà khỏi họa!",
		"Định triều ổn định lòng quân, tháo gỡ mọi cạm bẫy trì hoãn.",
		"Giữ lấy đạo lý công bằng giữa chốn triều đường.",
	],
	43: [
		"Khuyến nông tích lương, hậu phương vững thì tiền tuyến mới thắng!",
		"Nhiếp chính nhẹ nhàng mà uy nghiêm, điều hòa toàn cục.",
		"Giữ cho mỗi đồng đội đều đủ tài nguyên chiến đấu.",
	],
	44: [
		"Thổ binh vùng biên am hiểu núi rừng, đánh gần cực kỳ sắc bén!",
		"Vây hãm Ung Châu, triệt đường tiếp viện của quân địch.",
		"Trên lưng chiến mã giữa đại ngàn, không ai sánh bằng!",
	],
	45: [
		"Giữ vững Động Giáp, đánh Tống chẳng nề hà hiểm nguy.",
		"Bị tập kích càng phải đứng vững, phản công mạnh mẽ hơn!",
		"Quân kỳ Đông Giáp tung bay suốt dải biên thùy.",
	],
	46: [
		"Thiết diện vô tư, vàng bạc châu báu chẳng đổi được lòng trung!",
		"Mọi mưu đồ cướp phá, chia rẽ đều vô hiệu trước ta.",
		"Phụng sự tiên đế trọn lời thề, tâm sáng như gương.",
	],
	47: [
		"Nam quốc sơn hà Nam đế cư!",
		"Ngồi yên đợi giặc không bằng đem quân đánh trước phủ đầu giặc!",
		"Tiến thoái tự nhiên, công thủ toàn diện trên phòng tuyến Như Nguyệt!",
		"Phá Tống bình Chiêm, uy danh vang dội ngàn thu!",
	],
	48: [
		"Mở đầu vương triều Đông A hào hùng, giữ vững kỷ cương!",
		"Trang bị chỉnh tề, hồi phục nguyên khí tiếp tục chiến đấu!",
		"Khi vua tôi đồng lòng, giang sơn tất vững như Thái Sơn.",
	],
	49: [
		"Đầu thần chưa rơi xuống đất, xin bệ hạ đừng lo!",
		"Chế ngự cường hào, mọi trang bị của địch đều phải dè chừng.",
		"Kỷ cương phép nước là nền tảng để đánh thắng ngoại xâm.",
	],
	50: [
		"Tâm tư sâu kín, nhẫn nhịn chịu thiệt vì đại cục nhà Trần.",
		"Ghi nhớ từng vết thương, gửi lại mũi Trảm cho đồng đội.",
		"An Sinh Vương dù trải phong sương vẫn giữ khí phách hoàng tộc.",
	],
	51: [
		"Hội nghị Bình Than tụ nghĩa, cùng chung tay giữ nước!",
		"Cả hai vua tôi đồng sức, đánh thắng giặc Nguyên hung hãn.",
		"Mở kho cứu tế, tiếp sức cho ba quân tướng sĩ.",
	],
	52: [
		"Xã tắc hai phen chồn ngựa đá, non sông nghìn thuở vững âu vàng.",
		"Lúc nguy nan giữ vững thiền tâm, chuyển bại thành thắng!",
		"Cởi long bào lên Yên Tử, lòng vẫn hướng về muôn dân.",
	],
	53: [
		"Ta thường tới bữa quên ăn, nửa đêm vỗ gối, ruột đau như cắt!",
		"Dẫu trăm thân này phơi ngoài nội cỏ, nghìn xác này gói trong da ngựa cũng cam lòng!",
		"Hịch Tướng Sĩ đã ban, ba quân hãy sát thát giữ nước!",
		"Giặc Nguyên khét tiếng, gặp trận Vạn Kiếp Bạch Đằng cũng tan tành!",
	],
	54: [
		"Chương Dương cướp giáo giặc, Hàm Tử bắt quân thù!",
		"Thái bình rồi hãy gắng sức, để non sông này muôn thuở vững bền.",
		"Giáp trụ hoàn chỉnh, rong ruổi khắp chiến trường!",
	],
	55: [
		"Hàm Tử Quan đại phá quân giặc, uy danh vang tận phương Bắc!",
		"Biết địch biết ta, trăm trận trăm thắng!",
		"Hòa đồng với muôn dân miền núi, tạo nên sức mạnh đoàn kết.",
	],
	56: [
		"Phá Cường Địch, Báo Hoàng Ân — sáu chữ vàng khắc cốt ghi tâm!",
		"Tuổi trẻ chí lớn, không có vũ khí vẫn đánh tan quân thù!",
		"Quả cam bóp nát trong tay, quyết tâm ra trận diệt giặc!",
	],
	57: [
		"Ta thà làm quỷ nước Nam, chứ không thèm làm vương đất Bắc!",
		"Lấy thân mình chắn trước vòng vây, bảo vệ vua tôi rút lui an toàn.",
		"Cái chết nhẹ tựa lông hồng khi lòng trung còn rạng rỡ!",
	],
	58: [
		"Vân Đồn gió lớn, toàn bộ thuyền lương giặc đã nằm trong tay ta!",
		"Cắt đứt đường tiếp tế, quân địch tự khắc tan rã!",
		"Chẳng có chiếc thuyền lương nào vượt qua nổi tầm mắt Nhân Huệ Vương!",
	],
	59: [
		"Múa giáo non sông trải mấy thu, ba quân khí thế át sao Ngưu!",
		"Đan sọt ngẫm việc binh cơ, phục kích xuất kỳ bất ý!",
		"Nam nhi vị liễu công danh trái, tu thính nhân gian thuyết Vũ Hầu.",
	],
	60: [
		"Dưới lòng sông Bạch Đằng, thuyền giặc chỉ là mục tiêu của ta!",
		"Lặn sâu ngàn thước, đục thủng đáy chiến thuyền quân Nguyên!",
		"Sóng nước vô tình với giặc, nhưng luôn che chở cho Yết Kiêu.",
	],
	61: [
		"Đàn voi chiến Đại Việt tiến bước, mặt đất rung chuyển!",
		"Khoảng cách xa ư? Voi chiến của ta giữ vững phòng tuyến bất khả xâm phạm.",
		"Cưỡi voi xông pha, giặc thấy bóng đã hoảng loạn bỏ chạy.",
	],
	62: [
		"Đứng giữa doanh trại Thoát Hoan, khí phách sứ giả Đại Việt chẳng run sợ!",
		"Một tấc lưỡi sắc hơn vạn binh, bẻ gãy nhuệ khí quân thù.",
		"Thân vào hang cọp vẫn giữ vẹn quốc thể nước Nam.",
	],
	63: [
		"Dân binh Bắc Giang đồng lòng, đòn đánh tráng khí không dễ đỡ!",
		"Mũi tên từ rừng sâu bắn ra khiến kỵ binh giặc khiếp đảm.",
		"Bảo vệ quê hương từ từng khóm tre con suối.",
	],
	64: [
		"Trí dũng song toàn, đoạt cờ giặc xoay chuyển tình thế hiểm nghèo!",
		"Trong cái rủi lại tìm ra cơ hội phản kích!",
		"Liều mình giữa vòng vây để giữ liên lạc cho đại quân.",
	],
	65: [
		"Khoái Châu tiến bước, mở đường máu giữa trận địa Bạch Đằng!",
		"Giặc tới ư? Đồng đội của ta đã sẵn sàng tránh khỏi mũi tên!",
		"Tiên phong xông trận, bắt sống đại tướng giặc!",
	],
	66: [
		"Lòng ngay thẳng cương trực, mưu kế tầm thường đừng hòng cản bước!",
		"Giữ phép nước công minh, chẳng nể nang bất kỳ thế lực nào.",
		"Một khi đã hành động thì dứt khoát tới cùng!",
	],
	67: [
		"Thất Trảm Sớ dâng lên, quyết trừ gian nịnh cứu nguy triều chính!",
		"Đạo làm thầy muôn đời, chính khí ngất trời không khuất phục.",
		"Sẵn sàng bỏ quan về Chí Linh nếu lời ngay chẳng được nghe.",
	],
	68: [
		"Giang sơn hùng vĩ Bạch Đằng, lưu danh chiến công muôn thuở!",
		"Đất trời cho chỗ hiểm, nhưng thắng bại cốt ở đức người!",
		"Vung bút viết bài phú bất hủ ngợi ca hào khí Đông A.",
	],
	69: [
		"Lưỡng Quốc Trạng Nguyên, tài trí khiến triều đình phương Bắc kính phục!",
		"Bài vở trên tay nhiều thêm cũng chẳng làm khó được ta.",
		"Một câu đối hay đủ giữ thể diện cho cả nước Nam.",
	],
	70: [
		"Chữ nghĩa tài hoa, lấy ngoại giao khéo léo thu phục lòng người.",
		"Trao một đi, đổi lại trang bị quý cho thế trận phe ta!",
		"Sứ mệnh nặng nề mấy, Đoàn Nhữ Hài này cũng hoàn thành.",
	],
	71: [
		"Giữ vững thế thủ, cạm bẫy trì hoãn chẳng làm lung lay được ta!",
		"Cẩn trọng từng nước đi giữa thời buổi giao tranh rối ren.",
		"Kiên trì phòng bị là cách giữ mình qua cơn biến động.",
	],
	72: [
		"Ngự giá trực chiến, mỗi đòn đánh ra buộc địch phải dốc hết sức chống đỡ!",
		"Bậc quân vương không bao giờ lùi bước trước gian nan.",
		"Khí thế áp đảo, đòn Trảm thường cũng nặng tựa ngàn cân!",
	],
	73: [
		"Hỏa pháo khai hỏa, đánh tan chiến thuyền giặc trên sông Hải Triều!",
		"Ánh lửa rực trời, kẻ trúng đòn khó lòng toàn mạng.",
		"Một phát pháo định càn khôn, giữ yên biên ải phía Nam!",
	],
	74: [
		"Đồng minh gặp nạn, binh tiếp ứng lập tức lên đường!",
		"Đoàn kết nội bộ tạo thành phòng tuyến vững chắc.",
		"Hậu cần sẵn sàng chi viện trong mọi tình huống.",
	],
	75: [
		"Áo giáp sáng loáng, mỗi lần khoác giáp lại thêm nhuệ khí!",
		"Công thủ vẹn toàn, chuẩn bị kỹ càng trước khi giao phong.",
		"Giữ chắc chiến tuyến, không để địch tìm ra sơ hở.",
	],
	76: [
		"Cải chế triều chính, dám làm những điều xưa nay chưa từng có!",
		"Thành Tây Đô đá xanh sừng sững giữa đất Thanh Hóa.",
		"Thay cũ đổi mới, chuyển bài bỏ thành vũ khí mới!",
	],
	77: [
		"Tiền giấy lưu thông, bài thừa trao tay đồng đội cùng dùng!",
		"Không bỏ phí bất kỳ nguồn lực nào trên bàn đấu.",
		"Gánh vác triều Đại Ngu giữa muôn trùng thử thách.",
	],
	78: [
		"Súng Thần Công uy chấn thiên hạ, hỏa lực vang dội!",
		"Mỗi lá bài đen trong tay đều có thể hóa thành hỏa pháo!",
		"Trí tuệ chế tạo hỏa khí giúp Đại Việt sánh ngang thiên hạ.",
	],
	79: [
		"Dù thế lực suy vi, chí phục hưng nhà Trần vẫn bùng cháy!",
		"Lúc nguy nan nhất chính là lúc tinh thần quật khởi mạnh mẽ nhất!",
		"Còn một hơi thở, còn giương cao ngọn cờ Hậu Trần!",
	],
	80: [
		"Kế nghiệp tiên đế, quyết không để cơ đồ Đông A rơi vào tay giặc Minh!",
		"Nhận lại di sản đồng đội, tiếp tục trận chiến chưa hoàn thành!",
		"Ý chí kiên cường bất khuất cho đến giờ phút cuối cùng.",
	],
	81: [
		"Quốc thù chưa trả, đầu đã vội bạc trắng giữa trăng thu!",
		"Mài gươm dưới bóng nguyệt, một nhát Trảm không gì đỡ nổi!",
		"Hào khí Thuật Hoài vang vọng mãi trong lòng người đất Việt!",
	],
	82: [
		"Chiến thắng Bô Cô oanh liệt, trận pháp bày ra giặc khó thoát!",
		"Vườn không nhà trống một lượt khóa chặt hai mục tiêu!",
		"Cha con đồng lòng, đánh cho quân Minh một trận kinh hồn!",
	],
	83: [
		"Giữa dòng nước dữ, lá chắn thủy binh vẫn vững vàng!",
		"Nhanh trí ứng biến, biến mọi lá vàng thành thế thủ an toàn.",
		"Trung nghĩa một lòng với cơ nghiệp Hậu Trần.",
	],
	84: [
		"Khi sống không giết được giặc, chết cũng hóa lệ quỷ diệt thù!",
		"Kỵ binh xung kích, rút ngắn mọi khoảng cách trên chiến trường!",
		"Dũng mãnh vô song, quân Minh nghe tên đều run sợ.",
	],
	85: [
		"Thà giữ trọn khí tiết người Việt còn hơn khuất phục trước Trương Phụ!",
		"Ngồi trước hiểm nguy vẫn ung dung tự tại, làm địch phải nể phục.",
		"Thân có thể mất, nhưng danh tiết Nguyễn Biểu còn mãi!",
	],
	86: [
		"Thuận Thiên Kiếm trong tay, khởi nghĩa Lam Sơn tất thắng!",
		"Mười năm nằm gai nếm mật, quyết giành lại non sông gấm vóc!",
		"Đánh một trận sạch không kình ngạc, mở nền thái bình muôn thuở!",
	],
	87: [
		"Đem đại nghĩa để thắng hung tàn, lấy chí nhân để thay cường bạo!",
		"Một áng Bình Ngô Đại Cáo đủ làm tan rã mười vạn binh giặc!",
		"Việc nhân nghĩa cốt ở yên dân, mưu phạt tâm công là thượng sách.",
	],
	88: [
		"Khoác hoàng bào thay chúa công xông pha giữa vòng vây Chí Linh!",
		"Hy sinh thân mình để ngọn lửa Lam Sơn mãi không tắt!",
		"Chỉ cần chúa công bình an, mạng sống này có đáng là bao!",
	],
	89: [
		"Thủy kế Tụy Động, Chúc Động nhấn chìm đại quân Vương Thông!",
		"Tả tướng quốc xuất binh, thế trận như nước lũ cuốn phăng giặc Minh!",
		"Hùng tâm tráng chí, giúp Lam Sơn từ yếu thành mạnh.",
	],
	90: [
		"Lời thề Lũng Nhai khắc cốt ghi tâm, đồng tâm hiệp lực bình Ngô!",
		"Đòn Trảm Thủy đánh thẳng, xuyên qua mọi lớp giáp giặc!",
		"Một đời trung liệt cùng cờ nghĩa Lam Sơn.",
	],
	91: [
		"Thiết kỵ tung hoành, chiến mã địch chẳng cản nổi mũi giáo!",
		"Từ những ngày đầu ở Lũng Nhai tới ngày toàn thắng Xương Giang!",
		"Phò tá triều Lê vững bền suốt ba thế hệ.",
	],
	92: [
		"Trấn giữ phương Tây, lấy tĩnh chế động giảm nhẹ mọi tổn thương!",
		"Chặt đứt viện binh Mộc Thạnh, khiến giặc tuyệt đường rút lui.",
		"Bình tĩnh phòng thủ, không chút sơ hở nào!",
	],
	93: [
		"Ải Chi Lăng địa thế hiểm trở, kỵ binh Liễu Thăng đành chôn thây!",
		"Dũng tướng Lam Sơn, lúc nào cũng sẵn sàng huyết chiến!",
		"Chặt đầu Liễu Thăng, bẻ gãy mũi nhọn mười vạn viện binh!",
	],
	94: [
		"Mật vũ che mắt địch, giữ kín bài phòng ngự cho thời khắc quyết định.",
		"Cẩn mật từng bước đi, lật bài đúng lúc khiến kẻ địch bất ngờ.",
		"Công thần Lũng Nhai, âm thầm gánh vác đại sự.",
	],
	95: [
		"Đội quân khuyển binh đêm tập kích, đánh cho giặc Minh kinh hồn bạt vía!",
		"Trảm trúng là đoạt ngay bài tẩy trên tay đối thủ!",
		"Nhanh nhẹn sắc bén, chẳng bỏ sót một sơ hở nào của quân thù.",
	],
	96: [
		"Bình định bốn phương, buộc địch phải tự cắt tay chân tháo chạy!",
		"Kỷ luật quân đội nghiêm minh, thắng không kiêu bại không nản.",
		"Đánh thẳng vào hậu cần, làm quân địch tan rã từ bên trong.",
	],
	97: [
		"Một kế tiến quân vào Nghệ An xoay chuyển toàn bộ cục diện Lam Sơn!",
		"Tầm nhìn chiến lược vượt xa khoảng cách bàn đấu.",
		"Tin tình báo chính xác giúp đại quân luôn đi trước một bước.",
	],
	98: [
		"Kẻ mạnh hơn ta ư? Đòn Trảm này sẽ xuyên thủng mọi lớp phòng ngự!",
		"Dũng hãn xông lên, lấy nhuệ khí áp đảo số đông!",
		"Đã nhắm vào đối thủ nào là truy kích tới cùng.",
	],
	99: [
		"Khai biên mở cõi, thắng trận lại càng thêm sung sức!",
		"Uy danh Hoan Châu vang xa, giặc ngoại bang chẳng dám xâm phạm.",
		"Mang tinh thần Lam Sơn bảo vệ vững chắc bờ cõi phương Nam.",
	],
	100: [
		"Trấn ải biên thùy, mọi cạm bẫy trì hoãn đều vô hiệu trước ta!",
		"Đứng vững nơi đầu sóng ngọn gió, bảo toàn trận tuyến cho đồng đội.",
		"Đã nhận nhiệm vụ trấn ải, quyết không lùi nửa bước!",
	],
}
