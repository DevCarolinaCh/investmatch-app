// Modelos de mensajería y reuniones

enum MessageType { text, image, file, system }

enum MessageStatus { sending, sent, delivered, read }

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final String? fileUrl;
  final String? fileName;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    required this.type,
    required this.status,
    this.fileUrl,
    this.fileName,
    required this.createdAt,
  });

  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isFile => type == MessageType.file;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      content: json['content'] as String,
      type: MessageType.values.byName(json['type'] as String),
      status: MessageStatus.values.byName(json['status'] as String),
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatarUrl': senderAvatarUrl,
        'content': content,
        'type': type.name,
        'status': status.name,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'createdAt': createdAt.toIso8601String(),
      };
}

class ConversationModel {
  final String id;
  final String projectId;
  final String projectTitle;
  final String investorId;
  final String investorName;
  final String? investorAvatarUrl;
  final String founderId;
  final String founderName;
  final String? founderAvatarUrl;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.projectId,
    required this.projectTitle,
    required this.investorId,
    required this.investorName,
    this.investorAvatarUrl,
    required this.founderId,
    required this.founderName,
    this.founderAvatarUrl,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      projectTitle: json['projectTitle'] as String,
      investorId: json['investorId'] as String,
      investorName: json['investorName'] as String,
      investorAvatarUrl: json['investorAvatarUrl'] as String?,
      founderId: json['founderId'] as String,
      founderName: json['founderName'] as String,
      founderAvatarUrl: json['founderAvatarUrl'] as String?,
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'projectTitle': projectTitle,
        'investorId': investorId,
        'investorName': investorName,
        'investorAvatarUrl': investorAvatarUrl,
        'founderId': founderId,
        'founderName': founderName,
        'founderAvatarUrl': founderAvatarUrl,
        'lastMessage': lastMessage?.toJson(),
        'unreadCount': unreadCount,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

// Modelo de reunión / intro call
enum MeetingStatus { pending, confirmed, cancelled, completed }

class MeetingModel {
  final String id;
  final String conversationId;
  final String requesterId;
  final String requesterName;
  final String receiverId;
  final String receiverName;
  final String projectId;
  final String projectTitle;
  final DateTime scheduledAt;
  final int durationMinutes;
  final MeetingStatus status;
  final String? meetingUrl;
  final String? notes;
  final DateTime createdAt;

  const MeetingModel({
    required this.id,
    required this.conversationId,
    required this.requesterId,
    required this.requesterName,
    required this.receiverId,
    required this.receiverName,
    required this.projectId,
    required this.projectTitle,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    this.meetingUrl,
    this.notes,
    required this.createdAt,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      requesterId: json['requesterId'] as String,
      requesterName: json['requesterName'] as String,
      receiverId: json['receiverId'] as String,
      receiverName: json['receiverName'] as String,
      projectId: json['projectId'] as String,
      projectTitle: json['projectTitle'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      durationMinutes: json['durationMinutes'] as int,
      status: MeetingStatus.values.byName(json['status'] as String),
      meetingUrl: json['meetingUrl'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'projectId': projectId,
        'projectTitle': projectTitle,
        'scheduledAt': scheduledAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'status': status.name,
        'meetingUrl': meetingUrl,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };
}
