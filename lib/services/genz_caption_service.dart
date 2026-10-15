import 'dart:math';
class GenZCaptionService {
  GenZCaptionService._();

  static final GenZCaptionService instance = GenZCaptionService._();

  factory GenZCaptionService() => instance;

  final Random _random = Random();

  static const Map<String, List<String>> _categoryDefaultCaptionsVi = {
    'Ăn uống': [
      'Nạp năng lượng tâm hồn 🍚',
      'Ăn ngon giải xui 🍕',
      'Gì khó có đồ ăn lo 🍔',
      'Chiều chuộng cái bụng 😋',
      'Nạp năng lượng cho chiếc bụng đói 🍜',
      'Hệ tư tưởng ăn uống không ngừng nghỉ 🤤',
      'Chiếc bụng đói đã được giải cứu 🧋',
      'Ăn miếng bánh uống ngụm trà đời nở hoa 🍰',
    ],
    'Mua sắm': [
      'Chốt đơn không suy nghĩ 🛒',
      'Thích là nhích thôi 🛍️',
      'Tự thưởng bản thân ✨',
      'Chữa lành bằng shopping 💸',
      'Chốt đơn trong sự bàng hoàng của ví 💅',
      'Unbox niềm vui mới tinh tươm hôm nay 💳',
      'Mua sắm là niềm đam mê bất tận 📦',
    ],
    'Đi lại': [
      'Bật chế độ vi vu cùng phố phường 🛵',
      'Tấp vào đổ đầy bình xăng vi vu tiếp ⛽',
      'Lượn lờ hóng gió cho nhẹ đầu 🏍️',
      'Đường còn dài nhưng xăng thì không còn đầy 🚗',
      'Bác tài công nghệ cứu rỗi ngày mưa gió 🌧️',
      'Vi vu trên từng cây số 🚌',
      'Chuyến đi chữa lành tâm trạng 🛣️',
    ],
    'Giải trí': [
      'Cống hiến cho niềm vui 💸',
      'Hết mình vì đam mê ✨',
      'Nạp 100% mood ⚡',
      'Sạc lại năng lượng 🔋',
      'Chill một chút cho đời bớt căng thẳng 🍿',
      'Cuối tuần xả hơi hết mình cùng bạn bè 🎬',
      'Một chiếc kèo xả stress hết nước chấm 🥳',
    ],
    'Học tập': [
      'Đầu tư cho chất xám không bao giờ lỗ 📚',
      'Nâng cấp tri thức chuẩn bị hoá rồng 💡',
      'Học hành chăm chỉ vì tương lai rạng ngời ✍️',
      'Sách vở là chân ái, học hỏi là đam mê 🎓',
      'Mỗi ngày nạp thêm chút kiến thức mới 📖',
      'Nâng cấp não bộ level up 🧠',
      'Học thêm điều hay đời thêm thú vị ✨',
    ],
    'Lương': [
      'Ví vừa được cấp cứu ⚡',
      'Ting ting biến hình 💅',
      'Lương về sống sót qua ngày 🌾',
      'Sức mạnh tài chính trở lại 🔋',
      'Ting ting! Lúa về bản làng rồi bà con ơi 💸',
      'Lương về sưởi ấm con tim người lao động 🤑',
      'Động lực cày cuốc cả tháng đã cập bến 🏦',
    ],
    'Quà tặng': [
      'Gửi gắm chút yêu thương đến người thương 🎁',
      'Món quà nhỏ thay vạn lời muốn nói 🎀',
      'Trao đi yêu thương nhận lại nụ cười tươi 💐',
      'Tấm lòng là chính, quà tặng là mười 💖',
      'Một chút bất ngờ làm nên ngày vui 🌟',
      'Tặng quà cho người thương là hạnh phúc 🧸',
      'Yêu thương đong đầy trong từng món quà ✨',
    ],
    'Quỹ nhóm': [
      'Góp quỹ cùng hội bạn quẩy hết mình 🍻',
      'Đóng họ đúng hạn cho tình bạn keo sơn 🤝',
      'Nuôi quỹ nhóm chờ ngày cùng nhau bung xoã 🏕️',
      'Chung tay vì những kèo ăn chơi bất tận 🥳',
      'Tình bạn là chính, quỹ nhóm là thật 💸',
      'Góp một tay cho kèo xịn mịn sắp tới 🍕',
      'Hội bạn thân luôn đầy ắp niềm vui ✨',
    ],
    'Khác': [
      'Một khoản chi cần thiết cho cuộc sống ✨',
      'Thêm một khoảnh khắc đáng nhớ hôm nay 📸',
      'Chi tiêu thông minh quản lý tài chính đỉnh 💼',
      'Ghi lại để sau này khỏi hỏi tiền đi đâu 🧐',
      'Cuộc sống có những khoản phải chi như thế 🍃',
      'Chi tiêu hợp lý cho ngày thêm vui 🌟',
      'Khoảnh khắc thường ngày đáng yêu 🍀',
    ],
  };


  static const Map<String, List<String>> _categoryDefaultCaptionsEn = {
    'Ăn uống': [
      'Fixing my mood with food 🍚',
      'Calories well spent 🍕',
      'Food is therapy 🍔',
      'Feeding my inner child 😋',
      'Fueling the engine properly 🍜',
      'Good food good mood 🧋',
      'Life happens, snacks help 🍰',
      'Eating good feeling great 🤤',
    ],
    'Mua sắm': [
      'Retail therapy hit hard 🛒',
      'In my shopping era 🛍️',
      'Treat yourself moment ✨',
      'Cart total = emotional damage 💸',
      'Add to cart cured my soul 💅',
      'Unboxing happiness right now 💳',
      'Money well spent, zero regrets 📦',
    ],
    'Đi lại': [
      'On the road again 🛵',
      'Gas tank full, vibe check passed ⛽',
      'Catching breezy vibes outside 🏍️',
      'Rideshare saving the day 🌧️',
      'Wanderlust mode unlocked 🚗',
      'Cruising through the city 🚌',
      'Moving fast staying chill 🛣️',
    ],
    'Giải trí': [
      'Main character energy 💅',
      'Investing in my happiness 💸',
      '100% worth it ✨',
      'Serotonin boosted ⚡',
      'Recharging social battery 🔋',
      'Weekend chill vibes only 🍿',
      'Fun night out with the crew 🥳',
    ],
    'Học tập': [
      'Investing in brainpower never fails 📚',
      'Leveling up my knowledge 💡',
      'Study mode strictly activated ✍️',
      'Brain gains unlocked 🧠',
      'Upgrading my future self 🎓',
      'Smart moves for tomorrow 📖',
      'Knowledge is the real flex ✨',
    ],
    'Lương': [
      'Secured the bag ⚡',
      'Wallet revived 💸',
      'Payday energy 💅',
      'Financial recovery complete ⚡',
      'The wait is over, funds secured 🤑',
      'Payday brings pure joy 🏦',
      'Hard work finally paid off 💰',
    ],
    'Quà tặng': [
      'A little surprise for someone special 🎁',
      'Spreading love and good vibes 🎀',
      'Small gift, big love 💖',
      'Making someone smile today 💐',
      'Gift giving is my love language ✨',
      'Wrapped with pure love 🌟',
      'Best feeling is giving back 🧸',
    ],
    'Quỹ nhóm': [
      'Squad fund loaded and ready 🍻',
      'Teamwork makes the dream work 🤝',
      'Fueling our next group adventure 🏕️',
      'Squad goals fully funded 🥳',
      'Putting down for the gang 💸',
      'Group pool ready for good times 🍕',
      'Real friends, real memories ✨',
    ],
    'Khác': [
      'Adulting one expense at a time ✨',
      'Logging this moment right here 📸',
      'Staying on top of finances 💼',
      'Keeping the budget in check 🧐',
      'Just daily life things 🍃',
      'Smart spend for today 🌟',
      'Another chapter logged 🍀',
    ],
  };


  String _normalizeCategory(String? category) {
    if (category == null || category.trim().isEmpty) return 'Khác';
    final trimmed = category.trim().toLowerCase();
    switch (trimmed) {
      case 'ăn uống':
      case 'food':
      case 'food & beverage':
      case 'food and beverage':
      case 'dining':
      case 'eat':
        return 'Ăn uống';
      case 'mua sắm':
      case 'shopping':
      case 'shop':
        return 'Mua sắm';
      case 'đi lại':
      case 'di chuyển':
      case 'transport':
      case 'transportation':
      case 'travel':
        return 'Đi lại';
      case 'học tập':
      case 'giáo dục':
      case 'education':
      case 'study':
        return 'Học tập';
      case 'giải trí':
      case 'entertainment':
      case 'fun':
        return 'Giải trí';
      case 'lương':
      case 'income':
      case 'salary':
      case 'wage':
        return 'Lương';
      case 'quà tặng':
      case 'gift':
      case 'gifts':
        return 'Quà tặng';
      case 'quỹ nhóm':
      case 'group fund':
      case 'group':
        return 'Quỹ nhóm';
      default:
        return 'Khác';
    }
  }

  /// Chuẩn hoá mã ngôn ngữ về 'vi' hoặc 'en'. Mặc định 'vi'.
  String _normalizeLanguageCode(String? languageCode) {
    if (languageCode == null) return 'vi';
    final trimmed = languageCode.trim().toLowerCase();
    if (trimmed.startsWith('en')) return 'en';
    return 'vi';
  }

  static final RegExp _vietnameseDiacriticsRegex = RegExp(
    r'[àáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]',
    caseSensitive: false,
  );

  /// Tập từ vựng và cụm từ tiếng Anh phổ biến để nhận diện văn bản tiếng Anh
  static const Set<String> _englishVocabulary = {
    // Đại từ, giới từ, liên từ, trợ động từ thông dụng
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'with', 'of',
    'by', 'from', 'as', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have',
    'has', 'had', 'do', 'does', 'did', 'i', 'you', 'he', 'she', 'it', 'we', 'they',
    'my', 'your', 'his', 'her', 'its', 'our', 'their', 'this', 'that', 'these', 'those',
    'what', 'which', 'who', 'when', 'where', 'why', 'how', 'some', 'any', 'all', 'just',
    'not', 'so', 'very', 'here', 'there',
    // Hoạt động chi tiêu & đời sống hàng ngày
    'food', 'eat', 'ate', 'eating', 'drink', 'drank', 'drinking', 'coffee', 'tea',
    'boba', 'matcha', 'beer', 'wine', 'water', 'juice', 'rice', 'noodle', 'noodles',
    'bread', 'pizza', 'burger', 'snack', 'lunch', 'dinner', 'breakfast', 'meal',
    'buy', 'bought', 'buying', 'shop', 'shopping', 'store', 'cart', 'order', 'ordered',
    'shirt', 'pants', 'shoes', 'dress', 'bag', 'jacket', 'hoodie', 'clothes',
    'go', 'went', 'going', 'ride', 'taxi', 'uber', 'grab', 'bus', 'train', 'gas',
    'fuel', 'petrol', 'flight', 'ticket', 'trip', 'travel',
    'movie', 'film', 'cinema', 'game', 'gaming', 'play', 'chill', 'party', 'fun',
    'study', 'learn', 'book', 'books', 'course', 'class', 'school',
    'pay', 'paid', 'salary', 'income', 'money', 'cash', 'card', 'bill', 'fee',
    'cost', 'spend', 'spent', 'rent', 'tip', 'wallet', 'bonus', 'payday',
    'gift', 'present', 'give', 'gave', 'donated', 'fund', 'group', 'squad',
  };

  /// Từ vựng đặc trưng của tiếng Việt không dấu (để tránh nhầm sang tiếng Anh)
  static const Set<String> _unaccentedVietnameseStopwords = {
    'va', 'voi', 'cho', 'cua', 'trong', 'tren', 'duoi', 'khong', 'chua', 'duoc',
    'nhung', 'ma', 'la', 'thi', 'se', 'da', 'dang', 'roi', 'nay', 'kia', 'do',
    'toi', 'tao', 'minh', 'ban', 'chung', 'anh', 'em', 'chi', 'bac',
    'an', 'uong', 'di', 'mua', 'tra', 'tien', 'luong', 've', 'com', 'pho', 'bun',
    'xang', 'xe', 'quan', 'ao', 'giay', 'dep', 'hop', 'gia', 'tot',
  };

  /// Nhận diện ngôn ngữ văn bản:
  /// 1. Nếu văn bản có ký tự tiếng Việt có dấu -> 'vi'
  /// 2. Nếu không có dấu tiếng Việt nhưng nhận diện được là tiếng Anh -> 'en'
  /// 3. Nếu là tiếng Việt không dấu hoặc không xác định chắc ngôn ngữ -> ưu tiên uiLanguage
  String _detectLanguage(String text, String uiLanguage) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return _normalizeLanguageCode(uiLanguage);

    // 1. Kiểm tra dấu tiếng Việt
    if (_vietnameseDiacriticsRegex.hasMatch(trimmed)) {
      return 'vi';
    }

    // Tách các từ riêng lẻ
    final words = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return _normalizeLanguageCode(uiLanguage);

    int viCount = 0;
    int enCount = 0;

    for (final word in words) {
      if (_unaccentedVietnameseStopwords.contains(word)) {
        viCount++;
      }
      if (_englishVocabulary.contains(word)) {
        enCount++;
      }
    }

    // 2. Nhận diện tiếng Anh nếu có từ vựng tiếng Anh và không có từ tiếng Việt không dấu
    if (enCount > 0 && viCount == 0) {
      return 'en';
    }

    // 3. Tiếng Việt không dấu hoặc không xác định chắc -> ưu tiên uiLanguage
    return _normalizeLanguageCode(uiLanguage);
  }

  /// 1. Lấy ngẫu nhiên một caption mặc định phù hợp với Category và ngôn ngữ giao diện (uiLanguage).
  /// Luôn tạo caption theo uiLanguage, không dùng nội dung ô nhập để quyết định ngôn ngữ của caption mặc định.
  /// Hoạt động offline, tức thì, có nhóm dự phòng chung nếu category lạ.
  String getDefaultCaption(String category, [String uiLanguage = 'vi']) {
    final lang = _normalizeLanguageCode(uiLanguage);
    final canonicalCategory = _normalizeCategory(category);
    final pool = lang == 'en' ? _categoryDefaultCaptionsEn : _categoryDefaultCaptionsVi;
    final list = pool[canonicalCategory] ?? pool['Khác']!;
    return list[_random.nextInt(list.length)];
  }

  /// 2. Biến đổi caption hiện tại sang phong cách Gen Z ngắn gọn, hài hước, tự nhiên.
  /// Tự nhận diện ngôn ngữ của text (tiếng Việt có dấu -> vi, tiếng Anh -> en, còn lại -> uiLanguage).
  /// Giữ nguyên thông tin quan trọng (tên món, người tag, số lượng, nội dung chính).
  /// Giới hạn độ dài <= 10–12 từ, kết thúc với 1–2 emoji.
  String transformToGenZ(
    String text,
    String category, [
    String uiLanguage = 'vi',
  ]) {
    final trimmed = text.trim();
    final effectiveLang = _detectLanguage(trimmed, uiLanguage);

    if (trimmed.isEmpty) {
      return getDefaultCaption(category, uiLanguage);
    }

    final canonicalCategory = _normalizeCategory(category);

    // Tách các mention @username hoặc hashtag #tag để bảo toàn nguyên vẹn
    final mentions = <String>[];
    final words = trimmed.split(RegExp(r'\s+'));
    final nonMentionWords = <String>[];

    for (final word in words) {
      if (word.startsWith('@') || word.startsWith('#')) {
        mentions.add(word);
      } else {
        nonMentionWords.add(word);
      }
    }

    String coreText = nonMentionWords.join(' ').trim();

    // Loại bỏ các tiền tố hành chính, trang trọng hoặc khô khan
    if (effectiveLang == 'en') {
      final prefixesToRemoveEn = [
        RegExp(r'^(i\s+)?(have\s+)?(just\s+)?(paid\s+for|paid|bought|purchased|spent\s+on|spent|ordered)\s+', caseSensitive: false),
        RegExp(r'^(i\s+)?(have\s+)?(just\s+)?(ate|eaten|drank|went\s+to|had)\s+', caseSensitive: false),
      ];
      for (final pattern in prefixesToRemoveEn) {
        if (pattern.hasMatch(coreText)) {
          coreText = coreText.replaceFirst(pattern, '').trim();
          break;
        }
      }
    } else {
      final prefixesToRemoveVi = [
        RegExp(r'^(tôi\s+)?(đã\s+)?(vừa\s+)?(thanh\s+toán|trả\s+tiền|chuyển\s+khoản)\s+', caseSensitive: false),
        RegExp(r'^(tôi\s+)?(đã\s+)?(vừa\s+)?(mua\s+được|mua|sắm)\s+', caseSensitive: false),
        RegExp(r'^(tôi\s+)?(đã\s+)?(vừa\s+)?(ăn|uống|đi\s+ăn|đi\s+uống)\s+', caseSensitive: false),
        RegExp(r'^(tôi\s+)?(đã\s+)?(vừa\s+)?(đi\s+xe|đi)\s+', caseSensitive: false),
      ];
      for (final pattern in prefixesToRemoveVi) {
        if (pattern.hasMatch(coreText)) {
          coreText = coreText.replaceFirst(pattern, '').trim();
          break;
        }
      }
    }

    // Nếu sau khi lọc tiền tố còn rỗng thì lấy lại text ban đầu
    if (coreText.isEmpty) {
      coreText = trimmed;
    }

    // Tách emoji sẵn có ở cuối câu nếu có
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E0}-\u{1F1FF}]+$',
      unicode: true,
    );
    final existingEmojiMatch = emojiRegex.firstMatch(coreText);
    String existingEmoji = '';
    if (existingEmojiMatch != null) {
      existingEmoji = existingEmojiMatch.group(0) ?? '';
      coreText = coreText.substring(0, existingEmojiMatch.start).trim();
    }

    // Biến đổi ngữ phong Gen Z theo ngữ cảnh danh mục và ngôn ngữ
    String genZCore;
    String targetEmoji;

    if (effectiveLang == 'en') {
      switch (canonicalCategory) {
        case 'Ăn uống':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '😋';
          if (_hasAny(coreText, ['coffee', 'cafe', 'tea', 'boba', 'matcha', 'drink', 'beer', 'juice', 'water'])) {
            genZCore = _formatItem('Grabbing some $coreText to stay alive');
            targetEmoji = '🧋';
          } else if (_hasAny(coreText, ['rice', 'noodle', 'noodles', 'pizza', 'burger', 'pho', 'dinner', 'lunch', 'breakfast'])) {
            genZCore = _formatItem('Treating myself to $coreText');
            targetEmoji = '🍲';
          } else {
            genZCore = _formatItem('Fueling up with $coreText');
          }
          break;

        case 'Mua sắm':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '🛍️';
          if (_hasAny(coreText, ['shirt', 'pants', 'shoes', 'dress', 'bag', 'jacket', 'hoodie', 'clothes'])) {
            genZCore = _formatItem('Secured the $coreText in style');
          } else {
            genZCore = _formatItem('Treated myself to $coreText');
          }
          break;

        case 'Đi lại':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '🛵';
          if (_hasAny(coreText, ['gas', 'fuel', 'petrol'])) {
            genZCore = _formatItem('Tank filled with $coreText ready to roll');
            targetEmoji = '⛽';
          } else if (_hasAny(coreText, ['grab', 'uber', 'taxi', 'ride', 'bus', 'train'])) {
            genZCore = _formatItem('$coreText saving the day');
          } else {
            genZCore = _formatItem('On the move with $coreText');
          }
          break;

        case 'Giải trí':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '🎮';
          if (_hasAny(coreText, ['movie', 'cinema', 'film', 'theater'])) {
            genZCore = _formatItem('Movie time with $coreText');
            targetEmoji = '🎬';
          } else if (_hasAny(coreText, ['game', 'gaming', 'play'])) {
            genZCore = _formatItem('Dopamine hit with $coreText');
          } else {
            genZCore = _formatItem('Unwinding with $coreText');
            targetEmoji = '🍿';
          }
          break;

        case 'Học tập':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '📚';
          if (_hasAny(coreText, ['book', 'course', 'class', 'tuition'])) {
            genZCore = _formatItem('Adding $coreText to the brain bank');
          } else {
            genZCore = _formatItem('Leveling up with $coreText');
            targetEmoji = '💡';
          }
          break;

        case 'Lương':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '💸';
          genZCore = _formatItem('Bag secured: $coreText');
          break;

        case 'Quà tặng':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '🎁';
          genZCore = _formatItem('Gifted with love: $coreText');
          break;

        case 'Quỹ nhóm':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '🤝';
          genZCore = _formatItem('Squad pool for $coreText');
          break;

        default:
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '✨';
          if (coreText.split(RegExp(r'\s+')).length <= 4) {
            genZCore = _formatItem('Handled: $coreText');
          } else {
            genZCore = coreText;
          }
          break;
      }
    } else {
      switch (canonicalCategory) {
        case 'Ăn uống':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '🍜';
          if (_hasAny(coreText, ['cà phê', 'cafe', 'cf', 'trà sữa', 'matcha', 'nước'])) {
            genZCore = _formatItem('Làm ly $coreText chill chill');
            targetEmoji = '🧋';
          } else if (_hasAny(coreText, ['cơm', 'phở', 'bún', 'bánh', 'mì', 'lẩu', 'nướng'])) {
            genZCore = _formatItem('Làm bữa $coreText ấm lòng');
            targetEmoji = '🍲';
          } else {
            genZCore = _formatItem('$coreText ngon hết nước chấm');
          }
          break;

        case 'Mua sắm':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '🛍️';
          if (_hasAny(coreText, ['áo', 'quần', 'giày', 'váy', 'túi', 'son', 'đồ'])) {
            genZCore = _formatItem('Chốt đơn $coreText xinh xỉu');
          } else {
            genZCore = _formatItem('Tậu ngay $coreText cực mê');
          }
          break;

        case 'Đi lại':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '🛵';
          if (_hasAny(coreText, ['xăng', 'đổ xăng', 'nạp xăng'])) {
            genZCore = _formatItem('Đổ đầy bình $coreText vi vu tiếp');
            targetEmoji = '⛽';
          } else if (_hasAny(coreText, ['grab', 'be', 'taxi', 'xe ôm'])) {
            genZCore = _formatItem('$coreText cứu rỗi đôi chân');
          } else {
            genZCore = _formatItem('Vi vu $coreText bon bon trên đường');
          }
          break;

        case 'Giải trí':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '🎮';
          if (_hasAny(coreText, ['phim', 'cinema', 'rạp'])) {
            genZCore = _formatItem('Lên đồ xem $coreText xả stress');
            targetEmoji = '🎬';
          } else if (_hasAny(coreText, ['game', 'chơi', 'quán'])) {
            genZCore = _formatItem('Nạp dopamine cùng $coreText');
          } else {
            genZCore = _formatItem('Chill một chút với $coreText');
          }
          break;

        case 'Học tập':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '📚';
          if (_hasAny(coreText, ['sách', 'vở', 'giáo trình'])) {
            genZCore = _formatItem('Tậu $coreText nạp thêm chất xám');
          } else if (_hasAny(coreText, ['khóa học', 'học', 'tiếng anh'])) {
            genZCore = _formatItem('Nâng cấp tri thức cùng $coreText');
            targetEmoji = '💡';
          } else {
            genZCore = _formatItem('Đầu tư cho chất xám: $coreText');
          }
          break;

        case 'Lương':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '💸';
          genZCore = _formatItem('Ting ting $coreText lúa về bản làng');
          break;

        case 'Quà tặng':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '🎁';
          genZCore = _formatItem('Gửi trọn yêu thương qua $coreText');
          break;

        case 'Quỹ nhóm':
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '🤝';
          genZCore = _formatItem('Góp quỹ $coreText vì tình anh em');
          break;

        default:
          targetEmoji = existingEmoji.isNotEmpty ? existingEmoji : '✨';
          if (coreText.split(RegExp(r'\s+')).length <= 4) {
            genZCore = _formatItem('$coreText siêu ưng');
          } else {
            genZCore = coreText;
          }
          break;
      }
    }

    // Nối lại các mention @username nếu có
    String result = genZCore;
    if (mentions.isNotEmpty) {
      result = '$result ${mentions.join(' ')}';
    }

    // Đính kèm emoji cuối câu (tối đa 1-2 emoji)
    result = '$result $targetEmoji'.trim();

    // Giới hạn an toàn tối đa 10–12 từ để đảm bảo ngắn gọn, súc tích
    final tokenList = result.split(RegExp(r'\s+'));
    if (tokenList.length > 12) {
      // Giữ tối đa 11 từ đầu và kèm emoji cuối
      result = '${tokenList.take(11).join(' ')} $targetEmoji';
    }

    return result;
  }

  bool _hasAny(String source, List<String> keywords) {
    final lower = source.toLowerCase();
    for (final kw in keywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  String _formatItem(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return clean;
    return clean[0].toUpperCase() + clean.substring(1);
  }
}
