import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/services/video_cache_service.dart';
import '../../../core/services/failed_post_service.dart';
import '../../../core/services/app_widget_service.dart';

class FeedController extends ChangeNotifier {
  final TransactionRepository transactionRepository;
  final UserRepository userRepository;

  FeedController({
    required this.transactionRepository,
    required this.userRepository,
  });

  List<TransactionModel> feedTransactions = [];
  bool isLoading = false;
  String? errorMessage;
  String? targetPostId;
  int scrollToTopTrigger = 0;

  void triggerScrollToTop() {
    scrollToTopTrigger++;
    notifyListeners();
  }

  Future<void> setTargetPostId(
    String? postId, {
    String? groupId,
    TransactionModel? preloadedTx,
  }) async {
    targetPostId = postId;
    if (preloadedTx != null) {
      final alreadyIn = feedTransactions.any((t) => t.id == preloadedTx.id);
      if (!alreadyIn) {
        feedTransactions.add(preloadedTx);
        feedTransactions.sort((a, b) {
          if (a.isFailed && !b.isFailed) return -1;
          if (!a.isFailed && b.isFailed) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
      }
    } else if (postId != null && postId.isNotEmpty) {
      final exists = feedTransactions.any((tx) => tx.id == postId);
      if (!exists) {
        final tx = await transactionRepository.fetchTransactionById(postId,
            groupId: groupId);
        if (tx != null) {
          final alreadyIn = feedTransactions.any((t) => t.id == tx.id);
          if (!alreadyIn) {
            feedTransactions.add(tx);
            feedTransactions.sort((a, b) {
              if (a.isFailed && !b.isFailed) return -1;
              if (!a.isFailed && b.isFailed) return 1;
              return b.createdAt.compareTo(a.createdAt);
            });
          }
        }
      }
    }
    notifyListeners();
  }

  StreamSubscription<List<String>>? _friendSub;
  StreamSubscription<List<Map<String, dynamic>>>? _groupsSub;
  Timer? _pollingTimer;

  String? _currentUid;
  List<String> _currentFriendIds = [];
  List<String> _currentGroupMemberIds = [];
  bool _isFeedActive = false;
  bool get isFeedActive => _isFeedActive;

  void setFeedActive(bool active) {
    if (_isFeedActive == active) return;
    _isFeedActive = active;
    if (_isFeedActive) {
      _startPollingTimer();
    } else {
      _stopPollingTimer();
    }
  }

  void _startPollingTimer() {
    _stopPollingTimer();
    // Chỉ poll định kỳ khi người dùng đang thực sự xem màn Feed (chu kỳ 30s thay vì 8s dồn dập)
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_currentUid != null && !isLoading && _isFeedActive) {
        _fetchFeed(
          uid: _currentUid!,
          friendIds: _currentFriendIds,
          groupMemberIds: _currentGroupMemberIds,
          showLoading: false,
        );
      }
    });
  }

  void _stopPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> load(String uid) async {
    _currentUid = uid;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await _friendSub?.cancel();
    await _groupsSub?.cancel();
    _stopPollingTimer();

    _friendSub = userRepository.streamFriendIds(uid).listen(
      (friendIds) async {
        _currentFriendIds = friendIds;
        await _fetchFeed(
          uid: uid,
          friendIds: _currentFriendIds,
          groupMemberIds: _currentGroupMemberIds,
        );
      },
      onError: (e) {
        debugPrint('Friend stream error: $e');
        feedTransactions = [];
        isLoading = false;
        errorMessage = e.toString();
        notifyListeners();
      },
    );

    _groupsSub = userRepository.streamGroups(uid).listen(
      (groups) async {
        final memberIdsSet = <String>{};
        for (final group in groups) {
          final members = (group['memberIds'] as List?)
                  ?.map((e) => e.toString())
                  .where((e) => e.isNotEmpty) ??
              const Iterable.empty();
          memberIdsSet.addAll(members);
        }
        _currentGroupMemberIds = memberIdsSet.toList();
        await _fetchFeed(
          uid: uid,
          friendIds: _currentFriendIds,
          groupMemberIds: _currentGroupMemberIds,
          showLoading: false,
        );
      },
      onError: (e) {
        debugPrint('Groups stream error in feed: $e');
      },
    );

    if (_isFeedActive) {
      _startPollingTimer();
    }
  }

  Future<void> refresh() async {
    final uid = _currentUid;
    if (uid == null) return;

    await _fetchFeed(
      uid: uid,
      friendIds: _currentFriendIds,
      groupMemberIds: _currentGroupMemberIds,
      showLoading: false,
    );
  }

  Future<void> _fetchFeed({
    required String uid,
    required List<String> friendIds,
    List<String> groupMemberIds = const [],
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        isLoading = true;
        errorMessage = null;
        notifyListeners();
      }

      final allIds = <String>{uid, ...friendIds, ...groupMemberIds}.toList();

      final data = await transactionRepository.fetchFeedPosts(
        viewerUid: uid,
        userIds: allIds,
        friendIds: friendIds,
      );

      final failedPosts = await FailedPostService.instance.getFailedPosts(uid);
      final failedTxs = failedPosts.map((f) => f.toTransactionModel()).toList();

      final Map<String, TransactionModel> dedupMap = {};
      for (final tx in failedTxs) {
        dedupMap[tx.id] = tx;
      }
      for (final tx in data) {
        dedupMap[tx.id] = tx;
      }
      // Retain target post if it was preloaded or added into feedTransactions
      if (targetPostId != null && targetPostId!.isNotEmpty) {
        final existingTarget =
            feedTransactions.where((t) => t.id == targetPostId).firstOrNull;
        if (existingTarget != null && !dedupMap.containsKey(targetPostId)) {
          dedupMap[targetPostId!] = existingTarget;
        }
      }
      feedTransactions = dedupMap.values.toList();
      feedTransactions.sort((a, b) {
        if (a.isFailed && !b.isFailed) return -1;
        if (!a.isFailed && b.isFailed) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      isLoading = false;
      errorMessage = null;
      notifyListeners();

      // Preload ngầm 2 video gần nhất trong Feed thay vì 10 video để tránh ngốn RAM & mạng
      final videoUrls = feedTransactions
          .where((tx) => tx.isVideo && tx.playableVideoUrl.isNotEmpty)
          .take(2)
          .map((tx) => tx.playableVideoUrl)
          .toList();
      if (videoUrls.isNotEmpty) {
        VideoCacheService.instance.preloadBatch(videoUrls);
      }

      AppWidgetService.instance.cacheData(
        feedTransactions: feedTransactions,
      );
    } catch (e) {
      debugPrint('Feed load error: $e');
      feedTransactions = [];
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void addNewTransaction(TransactionModel transaction) {
    final uid = _currentUid;
    if (uid == null) return;

    final alreadyExists = feedTransactions.any((tx) => tx.id == transaction.id);
    if (alreadyExists) return;

    final isMine = transaction.userId == uid;

    final shouldShow = isMine ||
        (transaction.sharedToFeed == true &&
            (transaction.privacy == 'friends' ||
                transaction.privacy == 'close_friends' ||
                transaction.privacy == 'group'));

    if (!shouldShow) return;

    feedTransactions.insert(0, transaction);

    feedTransactions.sort(
      (a, b) {
        if (a.isFailed && !b.isFailed) return -1;
        if (!a.isFailed && b.isFailed) return 1;
        return b.createdAt.compareTo(a.createdAt);
      },
    );

    notifyListeners();

    if (transaction.isVideo && transaction.playableVideoUrl.isNotEmpty) {
      VideoCacheService.instance.preloadVideo(transaction.playableVideoUrl);
    }
  }

  void updateExistingTransaction(TransactionModel updatedTransaction) {
    final index =
        feedTransactions.indexWhere((tx) => tx.id == updatedTransaction.id);
    if (index != -1) {
      feedTransactions[index] = updatedTransaction;
      notifyListeners();
    }
  }

  void removeDeletedTransaction(String transactionId) {
    feedTransactions.removeWhere((tx) => tx.id == transactionId);
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPollingTimer();
    _friendSub?.cancel();
    _groupsSub?.cancel();
    super.dispose();
  }
}
