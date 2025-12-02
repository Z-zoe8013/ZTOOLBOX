import 'package:flutter/material.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/data/clipboard_history_service.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/data/model.dart';

class ClipboardProvider extends ChangeNotifier {
  final ClipboardHistoryService _service = ClipboardHistoryService();

  String _currentFolderName = '全部';
  int? _currentFolderId; // 添加当前文件夹ID
  List<ClipboardHistoryModel> _historyList = [];

  String get currentFolderName => _currentFolderName;
  int? get currentFolderId => _currentFolderId; // 添加getter
  List<ClipboardHistoryModel> get historyList => _historyList;

  ClipboardHistoryService get service => _service;

  void selectFolder(String folderName, {int? folderId}) {
    _currentFolderName = folderName;
    _currentFolderId = folderId; // 同时设置ID
    _loadHistoryList();
  }

  void resetFolder() {
    _currentFolderName = '全部';
    _currentFolderId = null; // 重置ID
    _loadHistoryList();
  }

  Future<void> _loadHistoryList() async {
    try {
      // 根据是否有folderId来决定使用哪种筛选方式
      final filterValue = _currentFolderName == '全部' 
          ? null 
          : (_currentFolderId ?? _currentFolderName); // 优先使用ID，如果没有则使用名称
      
      _historyList = await _service.getFilteredHistory(filterValue);
      notifyListeners();
    } catch (e) {
      _historyList = [];
      notifyListeners();
    }
  }

  // 刷新历史记录列表
  Future<void> refreshHistoryList() async {
    await _loadHistoryList();
  }
}
