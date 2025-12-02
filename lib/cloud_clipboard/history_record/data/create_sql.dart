import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

/// 剪切板历史数据库管理类（单例+全平台适配）
class ClipboardDatabase {
  // 单例模式
  static final ClipboardDatabase _instance = ClipboardDatabase._internal();
  factory ClipboardDatabase() => _instance;
  ClipboardDatabase._internal();

  static Database? _database;
  static bool _ffiInitialized = false;

  /// 获取数据库实例（懒加载）
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库（适配移动端/桌面端）
  Future<Database> _initDatabase() async {
    // 1. 桌面端初始化 SQLite FFI 环境（确保只初始化一次）
    if (kIsWeb) {
      throw UnimplementedError('Web 端暂不支持 SQLite');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      if (!_ffiInitialized) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _ffiInitialized = true;
        debugPrint('SQLite FFI 初始化完成');
      }
    }

    // 2. 获取跨平台存储路径
    final appDir = await _getAppDirectory();
    final dbPath = path.join(appDir.path, 'clipboard_history.db');

    // 3. 打开/创建数据库
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async => _createTables(db),
      onOpen: (db) => _onDatabaseOpen(db),
    );

    return db;
  }

  /// 数据库打开后的配置
  Future<void> _onDatabaseOpen(Database db) async {
    try {
      // 启用外键约束
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      debugPrint('外键约束启用失败: $e');
    }

    // 区分平台执行不同的配置
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        // 桌面端启用 WAL 模式以提升并发性能
        await db.execute('PRAGMA journal_mode = WAL');

        // 设置同步模式平衡性能和安全性
        await db.execute('PRAGMA synchronous = NORMAL');

        // 设置缓存大小
        await db.execute('PRAGMA cache_size = 2000');

        debugPrint('桌面端数据库配置完成：外键约束已启用，WAL模式已启用');
      } catch (e) {
        debugPrint('桌面端数据库配置失败: $e');
      }
    } else {
      // 移动端只启用基本配置
      debugPrint('移动端数据库配置完成：外键约束已启用');
    }
  }

  /// 创建数据表
  Future<void> _createTables(Database db) async {
    try {
      // 创建收藏夹表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorite_folders (
          folder_id INTEGER PRIMARY KEY AUTOINCREMENT,
          folder_name VARCHAR(50) UNIQUE NOT NULL,
          sort_num INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // 创建剪切板历史表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clipboard_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content TEXT NOT NULL,
          favorite_type VARCHAR(50) DEFAULT NULL,
          update_time DATETIME NOT NULL DEFAULT (datetime('now', 'localtime'))
        )
      ''');

      // 创建外键约束 - 插入检查
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS fk_clipboard_history_insert 
        AFTER INSERT ON clipboard_history
        WHEN NEW.favorite_type IS NOT NULL
        BEGIN
          SELECT CASE
            WHEN (SELECT folder_id FROM favorite_folders WHERE folder_name = NEW.favorite_type) IS NULL
            THEN RAISE(ABORT, '外键约束失败：收藏夹类型不存在')
          END;
        END;
      ''');

      // 创建外键约束 - 更新检查
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS fk_clipboard_history_update 
        AFTER UPDATE ON clipboard_history
        WHEN NEW.favorite_type IS NOT NULL AND OLD.favorite_type != NEW.favorite_type
        BEGIN
          SELECT CASE
            WHEN (SELECT folder_id FROM favorite_folders WHERE folder_name = NEW.favorite_type) IS NULL
            THEN RAISE(ABORT, '外键约束失败：收藏夹类型不存在')
          END;
        END;
      ''');

      // 创建外键约束 - 删除级联（当删除收藏夹时，同步删除相关历史记录）
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS fk_clipboard_history_delete_cascade
        AFTER DELETE ON favorite_folders
        WHEN OLD.folder_name IN (SELECT DISTINCT favorite_type FROM clipboard_history WHERE favorite_type IS NOT NULL)
        BEGIN
          DELETE FROM clipboard_history 
          WHERE favorite_type = OLD.folder_name;
        END;
      ''');

      // 创建索引提升查询效率（使用 try-catch 防止索引创建失败影响整体）
      final indexStatements = [
        'CREATE INDEX IF NOT EXISTS idx_update_time ON clipboard_history (update_time DESC)',
        'CREATE INDEX IF NOT EXISTS idx_favorite_type ON clipboard_history (favorite_type)',
        'CREATE INDEX IF NOT EXISTS idx_folder_name ON favorite_folders (folder_name)',
        'CREATE INDEX IF NOT EXISTS idx_folder_sort ON favorite_folders (sort_num, folder_name)',
      ];

      for (final statement in indexStatements) {
        try {
          await db.execute(statement);
        } catch (e) {
          debugPrint('索引创建警告：$e');
          // 索引创建失败不中断数据库创建过程
        }
      }

      // 插入默认文件夹数据
      await _insertDefaultFolders(db);

      debugPrint('数据表创建/检查完成：favorite_folders 和 clipboard_history');
    } catch (e) {
      debugPrint('数据表创建失败：$e');
      rethrow; // 重新抛出错误让调用者处理
    }
  }

  /// 插入默认文件夹数据
  Future<void> _insertDefaultFolders(Database db) async {
    try {
      // 默认文件夹配置
      final defaultFolders = [
        {'folder_name': '默认收藏夹', 'sort_num': 1},
      ];

      // 使用 INSERT OR IGNORE 防止重复插入
      for (final folder in defaultFolders) {
        await db.insert(
          'favorite_folders',
          folder,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      debugPrint('默认文件夹数据插入完成：${defaultFolders.length} 个文件夹');
    } catch (e) {
      debugPrint('默认文件夹数据插入失败：$e');
      // 插入失败不影响数据库创建过程
    }
  }

  /// 获取跨平台应用存储目录
  Future<Directory> _getAppDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isMacOS) {
      return await getApplicationSupportDirectory();
    } else if (Platform.isWindows) {
      return await getApplicationSupportDirectory();
    } else if (Platform.isLinux) {
      return await getApplicationSupportDirectory();
    } else {
      return Directory.current;
    }
  }

  /// 关闭数据库连接
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
