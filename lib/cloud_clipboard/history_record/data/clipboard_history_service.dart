import 'dart:async';
import 'package:flutter/foundation.dart';
import 'create_sql.dart';
import 'model.dart';

class ClipboardHistoryService {
  static final ClipboardHistoryService _instance =
      ClipboardHistoryService._internal();
  factory ClipboardHistoryService() => _instance;
  ClipboardHistoryService._internal();

  final ClipboardDatabase _database = ClipboardDatabase();

  Future<int> insertHistory({
    required String content,
    String? favoriteType,
  }) async {
    final history = ClipboardHistoryModel(
      content: content,
      favoriteType: favoriteType,
    );
    final db = await _database.database;
    return db.insert('clipboard_history', history.toMap());
  }

  Future<List<ClipboardHistoryModel>> getAllHistory() async {
    final db = await _database.database;
    final maps = await db.query(
      'clipboard_history',
      orderBy: 'update_time DESC',
    );
    return maps.map((map) => ClipboardHistoryModel.fromMap(map)).toList();
  }

  Future<ClipboardHistoryModel?> getHistoryById(int id) async {
    final db = await _database.database;
    final maps = await db.query(
      'clipboard_history',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? ClipboardHistoryModel.fromMap(maps.first) : null;
  }

  Future<int> updateHistory(
    int id, {
    String? content,
    String? favoriteType,
  }) async {
    final db = await _database.database;
    final updateData = <String, dynamic>{};
    if (content != null) updateData['content'] = content;
    updateData['favorite_type'] = favoriteType; // 支持设置为null
    updateData['update_time'] = DateTime.now().toIso8601String();

    return db.update(
      'clipboard_history',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteHistory(int id) async {
    final db = await _database.database;
    return db.delete('clipboard_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertFavoriteFolder({
    required String folderName,
    int sortNum = 0,
  }) async {
    final folder = FavoriteFolderModel(
      folderName: folderName,
      sortNum: sortNum,
    );
    final db = await _database.database;
    return db.insert('favorite_folders', folder.toMap());
  }

  Future<List<FavoriteFolderModel>> getAllFavoriteFolders() async {
    final db = await _database.database;
    final maps = await db.query(
      'favorite_folders',
      orderBy: 'sort_num ASC, folder_name ASC',
    );
    return maps.map((map) => FavoriteFolderModel.fromMap(map)).toList();
  }

  Future<int> updateFavoriteFolder(
    int folderId, {
    String? folderName,
    int? sortNum,
  }) async {
    // 检查是否是默认收藏夹（默认收藏夹不能被重命名）
    final folders = await getAllFavoriteFolders();
    final folder = folders.firstWhere(
      (f) => f.folderId == folderId,
      orElse: () =>
          FavoriteFolderModel(folderId: -1, folderName: '', sortNum: 0),
    );

    // 如果是默认收藏夹且尝试更改名称，则拒绝操作
    if (folder.folderName == '默认' && folderName != null && folderName != '默认') {
      // 不再抛出异常，而是返回-1表示操作失败
      return -1;
    }

    final db = await _database.database;
    final updateData = <String, dynamic>{};
    if (folderName != null) updateData['folder_name'] = folderName;
    if (sortNum != null) updateData['sort_num'] = sortNum;

    return db.update(
      'favorite_folders',
      updateData,
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
  }

  Future<int> deleteFavoriteFolder(int folderId) async {
    // 检查是否是默认收藏夹（默认收藏夹不能被删除）
    final folders = await getAllFavoriteFolders();
    final folder = folders.firstWhere(
      (f) => f.folderId == folderId,
      orElse: () =>
          FavoriteFolderModel(folderId: -1, folderName: '', sortNum: 0),
    );

    // 如果是默认收藏夹，则拒绝删除操作
    if (folder.folderName == '默认') {
      // 不再抛出异常，而是返回-1表示操作失败
      return -1;
    }

    final db = await _database.database;
    return db.delete(
      'favorite_folders',
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
  }

  Future<List<ClipboardHistoryModel>> getHistoryByFavoriteType(
    String favoriteType,
  ) async {
    final db = await _database.database;
    final maps = await db.query(
      'clipboard_history',
      where: 'favorite_type = ?',
      whereArgs: [favoriteType],
      orderBy: 'update_time DESC',
    );
    return maps.map((map) => ClipboardHistoryModel.fromMap(map)).toList();
  }

  Future<List<ClipboardHistoryModel>> getUnfavoritedHistory() async {
    final db = await _database.database;
    final maps = await db.query(
      'clipboard_history',
      where: 'favorite_type IS NULL',
      orderBy: 'update_time DESC',
    );
    return maps.map((map) => ClipboardHistoryModel.fromMap(map)).toList();
  }

  Future<Map<String, int>> getStatistics() async {
    final db = await _database.database;

    final historyResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clipboard_history',
    );
    final historyCount = historyResult.isNotEmpty
        ? (historyResult.first['count'] as int?) ?? 0
        : 0;

    final folderResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM favorite_folders',
    );
    final folderCount = folderResult.isNotEmpty
        ? (folderResult.first['count'] as int?) ?? 0
        : 0;

    final favoritedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clipboard_history WHERE favorite_type IS NOT NULL',
    );
    final favoritedCount = favoritedResult.isNotEmpty
        ? (favoritedResult.first['count'] as int?) ?? 0
        : 0;

    return {
      'totalHistory': historyCount,
      'totalFolders': folderCount,
      'favoritedItems': favoritedCount,
      'unfavoritedItems': historyCount - favoritedCount,
    };
  }

  /// 根据筛选类型获取历史记录
  /// filterType 可以是：
  /// - null: 显示所有记录
  /// - "未收藏": 显示未收藏的记录
  /// - 具体收藏夹名称: 显示该收藏夹的记录
  Future<List<ClipboardHistoryModel>> getFilteredHistory(
    String? filterType,
  ) async {
    if (filterType == null) {
      // 显示所有记录
      return getAllHistory();
    } else if (filterType == '未收藏') {
      // 显示未收藏记录
      return getUnfavoritedHistory();
    } else {
      // 显示指定收藏夹记录
      return getHistoryByFavoriteType(filterType);
    }
  }

  /// 获取筛选类型对应的统计数据
  Future<Map<String, int>> getFilteredStatistics(String? filterType) async {
    final db = await _database.database;

    if (filterType == null) {
      // 所有记录统计
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM clipboard_history',
      );
      return {
        'count': result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0,
      };
    } else if (filterType == '未收藏') {
      // 未收藏记录统计
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM clipboard_history WHERE favorite_type IS NULL',
      );
      return {
        'count': result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0,
      };
    } else {
      // 指定收藏夹记录统计
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM clipboard_history WHERE favorite_type = ?',
        [filterType],
      );
      return {
        'count': result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0,
      };
    }
  }

  /// 清除未收藏的数据，只保留最新的100条未收藏记录
  /// 收藏的记录不受影响
  Future<void> clearUnfavoritedHistoryExcess() async {
    final db = await _database.database;

    // 使用子查询找到需要删除的记录ID（未收藏且超出前100条的记录）
    await db.rawDelete('''
      DELETE FROM clipboard_history 
      WHERE favorite_type IS NULL 
      AND id NOT IN (
        SELECT id FROM clipboard_history 
        WHERE favorite_type IS NULL 
        ORDER BY update_time DESC 
        LIMIT 100
      )
    ''');

    if (kDebugMode) print('已清理多余的未收藏历史记录');
  }

  Future<void> close() async {
    await _database.close();
    if (kDebugMode) print('剪切板历史服务已关闭');
  }
}
