import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
// Add security imports
import 'security/route_guard.dart';
import 'security/secure_storage.dart';
import 'security/error_handler.dart';
import 'security/input_validator.dart';

import 'Categories_Page.dart';
import 'Chats_Page.dart';
import 'Orders.dart';
import 'Setting.dart';
import 'owner_listings.dart';
import 'fake_uid.dart';

class SharedBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTabChanged;

  const SharedBottomNav({
    super.key,
    required this.currentIndex,
    this.onTabChanged,
  });

  @override
  State<SharedBottomNav> createState() => _SharedBottomNavState();
}

class _SharedBottomNavState extends State<SharedBottomNav> {
  bool showMyItemsDot = false;
  StreamSubscription<QuerySnapshot>? _myItemsSub;
  StreamSubscription<DatabaseEvent>? _chatsSub;
  bool _isFirstMyItemsLoad = true;
  
  // Security variables
  bool _isInitialized = false;
  bool _isListening = false;
  int _maxUnreadCount = 99; // Security: Limit unread count display
  Timer? _securityTimer;

  @override
  void initState() {
    super.initState();
    _initializeSecurity();
  }

  // Secure initialization
  Future<void> _initializeSecurity() async {
    try {
      // Security: Check authentication
      if (!RouteGuard.isAuthenticated()) {
        _logSecurityEvent('User not authenticated - stopping nav init');
        return;
      }

      // Security: Validate UID
      if (!_isValidUid(LoginUID.uid)) {
        _logSecurityEvent('Invalid UID detected');
        return;
      }

      // Security: Start listening with delay to prevent spam
      await Future.delayed(const Duration(milliseconds: 500));
      
      _listenToMyItemsChanges();
      _listenToChatsChanges();
      
      // Security: Start periodic security check
      _startSecurityTimer();

      setState(() {
        _isInitialized = true;
      });

      _logSecurityEvent('BottomNav initialized successfully');

    } catch (error) {
      ErrorHandler.logError('BottomNav Initialization', error);
    }
  }

  bool _isValidUid(String uid) {
    if (uid.isEmpty || uid.length > 128) return false;
    // Basic UID validation
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(uid);
  }

  @override
  void didUpdateWidget(SharedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Security: Re-validate on tab change
    if (oldWidget.currentIndex != widget.currentIndex) {
      _logSecurityEvent('Tab changed from ${oldWidget.currentIndex} to ${widget.currentIndex}');
      
      // Security: Reset dot when entering My Items
      if (widget.currentIndex == 4) {
        setState(() {
          showMyItemsDot = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Security: Clean up all subscriptions and timers
    _cleanupResources();
    super.dispose();
  }

  void _cleanupResources() {
    _myItemsSub?.cancel();
    _chatsSub?.cancel();
    _securityTimer?.cancel();
    
    _logSecurityEvent('BottomNav resources cleaned up');
  }

  void _startSecurityTimer() {
    // Security: Periodic check for security issues
    _securityTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performSecurityCheck();
    });
  }

  void _performSecurityCheck() {
    try {
      // Security: Re-validate authentication
      if (!RouteGuard.isAuthenticated()) {
        _logSecurityEvent('Security check failed: User not authenticated');
        return;
      }

      // Security: Validate UID still valid
      if (!_isValidUid(LoginUID.uid)) {
        _logSecurityEvent('Security check failed: Invalid UID');
        return;
      }

      _logSecurityEvent('Security check passed');

    } catch (error) {
      ErrorHandler.logError('Security Check', error);
    }
  }

  void _listenToMyItemsChanges() {
    try {
      if (_isListening) return;
      
      final String uid = LoginUID.uid;
      
      // Security: Validate UID before query
      if (!_isValidUid(uid)) {
        throw Exception('Invalid UID for My Items query');
      }

      _myItemsSub = FirebaseFirestore.instance
          .collection("items")
          .where("ownerId", isEqualTo: uid)
          .where("isActive", isEqualTo: true) // Security: Only active items
          .limit(100) // Security: Limit results
          .snapshots()
          .listen((snapshot) {
        _handleMyItemsUpdate(snapshot);
      }, onError: (error) {
        ErrorHandler.logError('My Items Stream', error);
      });

      _isListening = true;
      _logSecurityEvent('Started listening to My Items changes');

    } catch (error) {
      ErrorHandler.logError('Listen to My Items', error);
    }
  }

  void _handleMyItemsUpdate(QuerySnapshot snapshot) {
    try {
      // Security: Validate snapshot
      if (!mounted) return;
      
      // If user is on My Items page → don't show dot
      if (widget.currentIndex == 4) {
        if (showMyItemsDot) {
          setState(() {
            showMyItemsDot = false;
          });
        }
        return;
      }

      if (_isFirstMyItemsLoad) {
        _isFirstMyItemsLoad = false;
        return;
      }

      // Security: Check for actual changes (not just metadata)
      bool hasRealChanges = false;
      for (var change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;
if (change.type != DocumentChangeType.modified || 
    (data != null && data['updatedAt'] != null)) {
          hasRealChanges = true;
          break;
        }
      }

      if (hasRealChanges && widget.currentIndex != 4) {
        setState(() {
          showMyItemsDot = true;
        });
        _logSecurityEvent('My Items updated - showing dot');
      }

    } catch (error) {
      ErrorHandler.logError('Handle My Items Update', error);
    }
  }

  void _listenToChatsChanges() {
    try {
      final String uid = LoginUID.uid;
      
      // Security: Validate UID before listening
      if (!_isValidUid(uid)) {
        throw Exception('Invalid UID for Chats query');
      }

      _chatsSub = FirebaseDatabase.instance.ref("chats").onValue.listen(
        (event) {
          // Security: Handle chat updates (processed in builder)
        },
        onError: (error) {
          ErrorHandler.logError('Chats Stream', error);
        },
        cancelOnError: true,
      );

      _logSecurityEvent('Started listening to Chats changes');

    } catch (error) {
      ErrorHandler.logError('Listen to Chats', error);
    }
  }

  // Secure navigation
  void _navigate(BuildContext context, int index) {
    try {
      // Security: Validate index
      if (index < 0 || index > 4) {
        _logSecurityEvent('Invalid navigation index: $index');
        return;
      }

      if (index == widget.currentIndex) {
        _logSecurityEvent('Navigation to same index: $index');
        return;
      }

      // Security: Check authentication before navigation
      if (!RouteGuard.isAuthenticated()) {
        _logSecurityEvent('Navigation blocked - user not authenticated');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
        return;
      }

      // Security: Log navigation event
      _logSecurityEvent('Navigating to index: $index');

      // When entering My Items, remove dot
      if (index == 4) {
        setState(() {
          showMyItemsDot = false;
        });
      }

      // Use callback if provided
      if (widget.onTabChanged != null) {
        widget.onTabChanged!(index);
        return;
      }

      // Secure navigation with validation
      _performSecureNavigation(context, index);

    } catch (error) {
      ErrorHandler.logError('Navigation', error);
      // Fallback: Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getSafeError(error)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _performSecureNavigation(BuildContext context, int index) {
    final Map<int, Widget> routes = {
      0: const SettingPage(),
      1: const OrdersPage(),
      2: const CategoryPage(),
      3: const ChatsPage(),
      4: const OwnerItemsPage(),
    };

    final destination = routes[index];
    if (destination == null) {
      _logSecurityEvent('Invalid route for index: $index');
      return;
    }

    // Security: Clear navigation stack and push new route
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );

    // Security: Store last navigation in secure storage
    _storeNavigationHistory(index);
  }

  Future<void> _storeNavigationHistory(int index) async {
    try {
      await SecureStorage.saveData(
        'last_navigation',
        '${DateTime.now().toIso8601String()}: tab_$index',
      );
    } catch (error) {
      ErrorHandler.logError('Store Navigation History', error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Security: Show minimal version if not initialized
    if (!_isInitialized) {
      return _buildMinimalNavBar(context);
    }

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF1B2230),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildIcon(Icons.settings, 0, context),
          _buildIcon(Icons.shopping_bag_outlined, 1, context),
          _buildIcon(Icons.home_outlined, 2, context),
          _buildChatIcon(context),
          _buildMyItemsIcon(context),
        ],
      ),
    );
  }

  Widget _buildMinimalNavBar(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF1B2230),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          return GestureDetector(
            onTap: () => _navigate(context, index),
            child: Icon(
              _getIconForIndex(index),
              size: 26,
              color: Colors.white70,
            ),
          );
        }),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return Icons.settings;
      case 1: return Icons.shopping_bag_outlined;
      case 2: return Icons.home_outlined;
      case 3: return Icons.chat_bubble_outline;
      case 4: return Icons.storage_rounded;
      default: return Icons.error;
    }
  }

  Widget _buildIcon(IconData icon, int index, BuildContext context) {
    bool active = index == widget.currentIndex;

    return GestureDetector(
      onTap: () => _navigate(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.only(bottom: active ? 8 : 0),
        padding: const EdgeInsets.all(12),
        decoration: active
            ? BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              )
            : null,
        child: Icon(
          icon,
          size: active ? 32 : 26,
          color: active ? Colors.black : Colors.white70,
        ),
      ),
    );
  }

  /// CHAT ICON WITH SECURE BADGE
  Widget _buildChatIcon(BuildContext context) {
    bool active = widget.currentIndex == 3;

    return GestureDetector(
      onTap: () => _navigate(context, 3),
      child: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref("chats").limitToFirst(100).onValue,
        builder: (context, snapshot) {
          int unreadCount = 0;

          try {
            if (snapshot.hasData &&
                snapshot.data!.snapshot.value != null &&
                snapshot.connectionState == ConnectionState.active) {
              
              final raw = snapshot.data!.snapshot.value;
              if (raw is Map) {
                final chats = Map<String, dynamic>.from(raw);
                final String uid = LoginUID.uid;

                // Security: Validate UID
                if (_isValidUid(uid)) {
                  for (var chat in chats.values) {
                    if (chat is Map && 
                        chat["unread"] is Map && 
                        chat["unread"][uid] == true) {
                      unreadCount++;
                      
                      // Security: Limit counting
                      if (unreadCount >= _maxUnreadCount) {
                        unreadCount = _maxUnreadCount;
                        break;
                      }
                    }
                  }
                }
              }
            }
          } catch (error) {
            ErrorHandler.logError('Build Chat Icon', error);
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(bottom: active ? 8 : 0),
                padding: const EdgeInsets.all(12),
                decoration: active
                    ? BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      )
                    : null,
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: active ? 32 : 26,
                  color: active ? Colors.black : Colors.white70,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      unreadCount > _maxUnreadCount ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// MY ITEMS ICON WITH GREEN DOT
  Widget _buildMyItemsIcon(BuildContext context) {
    bool active = widget.currentIndex == 4;

    return GestureDetector(
      onTap: () => _navigate(context, 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(bottom: active ? 8 : 0),
            padding: const EdgeInsets.all(12),
            decoration: active
                ? BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  )
                : null,
            child: Icon(
              Icons.storage_rounded,
              size: active ? 32 : 26,
              color: active ? Colors.black : Colors.white70,
            ),
          ),

          if (showMyItemsDot && !active)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _logSecurityEvent(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = 'BottomNav[$timestamp]: $message';
    
    // In production, send to secure logging service
    print('🔒 NAV SECURITY: $logMessage');
    
    // Store in audit log
    _storeAuditLog(logMessage);
  }

  Future<void> _storeAuditLog(String message) async {
    try {
      final existingLogs = await SecureStorage.getData('nav_audit_logs') ?? '[]';
      final List<dynamic> logs = List<dynamic>.from(json.decode(existingLogs));
      
      logs.add({
        'timestamp': DateTime.now().toIso8601String(),
        'event': message,
        'currentTab': widget.currentIndex,
      });
      
      // Keep only last 50 entries
      if (logs.length > 50) {
        logs.removeAt(0);
      }
      
      await SecureStorage.saveData('nav_audit_logs', json.encode(logs));
      
    } catch (error) {
      ErrorHandler.logError('Store Nav Audit Log', error);
    }
  }
}
