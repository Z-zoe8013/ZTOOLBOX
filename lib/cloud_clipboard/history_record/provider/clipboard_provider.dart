import 'package:flutter/material.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/data/clipboard_history_service.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/data/model.dart';

class ClipboardProvider extends ChangeNotifier {
  final ClipboardHistoryService _service = ClipboardHistoryService();

  String _currentFolderName = '全部';
  List<ClipboardHistoryModel> _historyList = [];

  String get currentFolderName => _currentFolderName;
  List<ClipboardHistoryModel> get historyList => _historyList;

  ClipboardHistoryService get service => _service;

  void selectFolder(String folderName) {
    _currentFolderName = folderName;
    _loadHistoryList();
  }

  void resetFolder() {
    _currentFolderName = '全部';
    _loadHistoryList();
  }

  Future<void> _loadHistoryList() async {
    try {
      _historyList = await _service.getFilteredHistory(
        _currentFolderName == '全部' ? null : _currentFolderName,
      );
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
