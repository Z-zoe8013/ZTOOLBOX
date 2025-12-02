/// 剪切板历史表模型
class ClipboardHistoryModel {
  /// 记录唯一标识（自增主键）
  int? id;

  /// 剪切板内容（核心字段）
  String content;

  /// 收藏夹ID（关联收藏夹表 folder_id，允许为空）
  int? favoriteFolderId;

  /// 记录更新时间（默认当前本地时间）
  DateTime updateTime;

  /// 构造函数
  ClipboardHistoryModel({
    this.id,
    required this.content,
    this.favoriteFolderId,
    DateTime? updateTime,
  }) : updateTime = updateTime ?? DateTime.now();

  /// 从数据库Map转换为模型对象
  factory ClipboardHistoryModel.fromMap(Map<String, dynamic> map) {
    return ClipboardHistoryModel(
      id: map['id'] as int?,
      content: map['content'] as String,
      favoriteFolderId: map['favorite_folder_id'] as int?,
      updateTime: DateTime.parse(map['update_time'] as String),
    );
  }

  /// 模型对象转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'favorite_folder_id': favoriteFolderId,
      'update_time': updateTime.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ClipboardHistoryModel{id: $id, content: $content, favoriteFolderId: $favoriteFolderId, updateTime: $updateTime}';
  }
}

/// 收藏夹表模型
class FavoriteFolderModel {
  /// 收藏夹唯一标识（自增主键）
  int? folderId;

  /// 收藏夹名称（唯一不重复）
  String folderName;

  /// 收藏夹排序序号（数值越小越靠前，支持自定义排序）
  int sortNum;

  /// 构造函数
  ///
  /// [folderId] 收藏夹唯一标识（自增主键）
  /// [folderName] 收藏夹名称（唯一不重复）
  /// [sortNum] 收藏夹排序序号（数值越小越靠前，支持自定义排序）
  FavoriteFolderModel({
    this.folderId,
    required this.folderName,
    this.sortNum = 0,
  });

  /// 从数据库Map转换为模型对象
  factory FavoriteFolderModel.fromMap(Map<String, dynamic> map) {
    return FavoriteFolderModel(
      folderId: map['folder_id'] as int?,
      folderName: map['folder_name'] as String,
      sortNum: map['sort_num'] as int? ?? 0,
    );
  }

  /// 模型对象转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'folder_id': folderId,
      'folder_name': folderName,
      'sort_num': sortNum,
    };
  }

  @override
  String toString() {
    return 'FavoriteFolderModel{folderId: $folderId, folderName: $folderName, sortNum: $sortNum}';
  }
}
