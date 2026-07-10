class Profile {
  final String id;
  final String? username;
  final String? displayName;
  final String? bio;

  Profile({required this.id, this.username, this.displayName, this.bio});

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String?,
      displayName: map['display_name'] as String?,
      bio: map['bio'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'bio': bio,
    };
  }

  String get initial {
    final name = displayName ?? username ?? '';
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
  String get name => displayName ?? username ?? 'Anonymous';
}

class Habit {
  final bool exercise;
  final bool noSugar;
  final bool noSmoking;
  final int exerciseMinutes;

  const Habit({
    this.exercise = false,
    this.noSugar = false,
    this.noSmoking = false,
    this.exerciseMinutes = 0,
  });

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      exercise: map['exercise'] as bool? ?? false,
      noSugar: map['no_sugar'] as bool? ?? false,
      noSmoking: map['no_smoking'] as bool? ?? false,
      exerciseMinutes: map['exercise_minutes'] as int? ?? 0,
    );
  }
}

class HabitHistory {
  final String date;
  final bool exercise;
  final bool noSugar;
  final bool noSmoking;
  final int exerciseMinutes;
  final int? fastingHours;

  HabitHistory({
    required this.date,
    this.exercise = false,
    this.noSugar = false,
    this.noSmoking = false,
    this.exerciseMinutes = 0,
    this.fastingHours,
  });

  factory HabitHistory.fromMap(Map<String, dynamic> map) {
    return HabitHistory(
      date: map['date'] as String,
      exercise: map['exercise'] as bool? ?? false,
      noSugar: map['no_sugar'] as bool? ?? false,
      noSmoking: map['no_smoking'] as bool? ?? false,
      exerciseMinutes: map['exercise_minutes'] as int? ?? 0,
      fastingHours: map['fasting_hours'] as int?,
    );
  }
}

class ActiveTimer {
  final String id;
  final String type;
  final int targetMinutes;
  final String? presetType;
  final bool active;
  final DateTime startedAt;

  ActiveTimer({
    required this.id,
    required this.type,
    required this.targetMinutes,
    this.presetType,
    required this.active,
    required this.startedAt,
  });

  factory ActiveTimer.fromMap(Map<String, dynamic> map) {
    return ActiveTimer(
      id: map['id'] as String,
      type: map['type'] as String,
      targetMinutes: map['target_minutes'] as int,
      presetType: map['preset_type'] as String?,
      active: map['active'] as bool,
      startedAt: DateTime.parse(map['started_at'] as String),
    );
  }
}

class Post {
  final String id;
  final String userId;
  final String type;
  final String? content;
  final String? imageUrl;
  final int? durationMinutes;
  final DateTime createdAt;
  final Profile? profile;
  final List<Reaction> reactions;
  final int hypeCount;

  Post({
    required this.id,
    required this.userId,
    required this.type,
    this.content,
    this.imageUrl,
    this.durationMinutes,
    required this.createdAt,
    this.profile,
    this.reactions = const [],
    this.hypeCount = 0,
  });

  factory Post.fromMap(Map<String, dynamic> map, {Map<String, dynamic>? profileData}) {
    return Post(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      content: map['content'] as String?,
      imageUrl: map['image_url'] as String?,
      durationMinutes: map['duration_minutes'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      profile: profileData != null ? Profile.fromMap(profileData) : null,
    );
  }

  Post copyWith({
    String? id,
    String? userId,
    String? type,
    String? content,
    String? imageUrl,
    int? durationMinutes,
    DateTime? createdAt,
    Profile? profile,
    List<Reaction>? reactions,
    int? hypeCount,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
      profile: profile ?? this.profile,
      reactions: reactions ?? this.reactions,
      hypeCount: hypeCount ?? this.hypeCount,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String get durationFormatted {
    if (durationMinutes == null) return '';
    if (durationMinutes! >= 60) {
      final h = durationMinutes! ~/ 60;
      final m = durationMinutes! % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${durationMinutes}m';
  }
}

class Reaction {
  final String id;
  final String userId;
  final String postId;
  final String emoji;

  Reaction({
    required this.id,
    required this.userId,
    required this.postId,
    required this.emoji,
  });

  factory Reaction.fromMap(Map<String, dynamic> map) {
    return Reaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      postId: map['post_id'] as String,
      emoji: map['emoji'] as String? ?? '\u{1F525}',
    );
  }
}

class SmokingLog {
  final String date;
  final int cigarettes;
  final String? trigger;
  final int? cravingIntensity;

  SmokingLog({
    required this.date,
    required this.cigarettes,
    this.trigger,
    this.cravingIntensity,
  });

  bool get isSmokeFree => cigarettes == 0;
  bool get isSlip => cigarettes > 0 && cigarettes <= 2;
  bool get isRelapse => cigarettes > 2;

  factory SmokingLog.fromMap(Map<String, dynamic> map) {
    return SmokingLog(
      date: map['date'] as String,
      cigarettes: map['cigarettes'] as int? ?? 0,
      trigger: map['trigger'] as String?,
      cravingIntensity: map['craving_intensity'] as int?,
    );
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String? fromUserId;
  final String type;
  final String message;
  final bool read;
  final DateTime createdAt;
  final Profile? fromUser;

  AppNotification({
    required this.id,
    required this.userId,
    this.fromUserId,
    required this.type,
    required this.message,
    this.read = false,
    required this.createdAt,
    this.fromUser,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, {Map<String, dynamic>? fromUser}) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      fromUserId: map['from_user_id'] as String?,
      type: map['type'] as String,
      message: map['message'] as String,
      read: map['read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      fromUser: fromUser != null ? Profile.fromMap(fromUser) : null,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
