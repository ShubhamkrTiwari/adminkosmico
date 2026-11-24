import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';
import '../../widgets/water_drop_transition.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form State
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _imageController = TextEditingController();

  String _selectedCategory = 'General';
  String _selectedAudience = 'all'; // 'all', 'subscribed', 'specific'
  String _specificUserId = '';

  // Auto AI Preferences State
  bool _enableAutoNotifications = true;
  bool _quietHoursEnabled = true;
  String _quietStart = '22:00';
  String _quietEnd = '08:00';
  bool _isLoadingPreferences = false;

  Map<String, Map<String, dynamic>> _categoryConfigs = {
    'waterIntake': {'enabled': true, 'frequency': '2h'},
    'stepCount': {'enabled': true, 'frequency': '1h'},
    'bloodPressure': {'enabled': true, 'frequency': 'weekly'},
    'plateScan': {'enabled': true, 'frequency': 'instant'},
    'promos': {'enabled': true, 'frequency': 'daily'},
    'orderUpdates': {'enabled': true, 'frequency': 'instant'},
    'healthTips': {'enabled': true, 'frequency': 'daily'},
  };

  // Self Test Push State
  final _fcmTokenController = TextEditingController();
  final _testTitleController = TextEditingController(text: '🔔 Test Push Notification');
  final _testMessageController = TextEditingController(text: 'This is a test notification from the Kosmico Admin Panel!');

  final List<Map<String, String>> _quickTemplates = [
    {
      'label': '🔥 Special Offer',
      'title': '🔥 Special Flash Sale - 20% OFF!',
      'message': 'Don\'t miss out on today\'s exclusive discounts. Shop your favorites now!',
      'category': 'Promo',
      'audience': 'all',
    },
    {
      'label': '📢 Announcement',
      'title': '📢 Important Platform Update',
      'message': 'We have upgraded our platform with new features and improved speed.',
      'category': 'Platform News',
      'audience': 'all',
    },
    {
      'label': '❤️ Daily Wellness',
      'title': '❤️ Daily Health & Wellness Tip',
      'message': 'Stay hydrated and active today! Explore our latest health recommendations.',
      'category': 'Health Tip',
      'audience': 'subscribed',
    },
    {
      'label': '📦 Order Update',
      'title': '📦 Express Order Status Alert',
      'message': 'Your recent order has been processed and is on its way to you.',
      'category': 'Order Update',
      'audience': 'all',
    },
  ];

  final List<String> _categories = [
    'General',
    'Promo',
    'Platform News',
    'Health Tip',
    'Order Update',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _titleController.addListener(_updateState);
    _messageController.addListener(_updateState);
    _imageController.addListener(_updateState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().getAdminSentNotifications();
      context.read<UserProvider>().fetchUsers();
      _loadPreferences();
    });
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _imageController.dispose();
    _fcmTokenController.dispose();
    _testTitleController.dispose();
    _testMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoadingPreferences = true);
    final prefs = await context.read<NotificationProvider>().getNotificationPreferences();
    if (prefs != null && mounted) {
      setState(() {
        _enableAutoNotifications = prefs['enableAutoNotifications'] ?? true;
        final cats = prefs['categories'] as Map<String, dynamic>?;
        if (cats != null) {
          cats.forEach((key, val) {
            String normalKey = key;
            if (key == 'water_intake') normalKey = 'waterIntake';
            if (key == 'step_count') normalKey = 'stepCount';
            if (key == 'blood_pressure') normalKey = 'bloodPressure';
            if (key == 'plate_scan') normalKey = 'plateScan';
            if (key == 'order_update') normalKey = 'orderUpdates';
            if (key == 'wellness_tip') normalKey = 'healthTips';
            if (key == 'promo') normalKey = 'promos';
            if (key == 'hydration') normalKey = 'waterIntake';

            if (val is Map) {
              _categoryConfigs[normalKey] = {
                'enabled': val['enabled'] ?? true,
                'frequency': val['frequency'] ?? val['freq'] ?? 'daily',
              };
            } else if (val is bool) {
              _categoryConfigs[normalKey] = {
                'enabled': val,
                'frequency': 'daily',
              };
            }
          });
        }
        final quiet = prefs['quietHours'] as Map<String, dynamic>?;
        if (quiet != null) {
          _quietHoursEnabled = quiet['enabled'] ?? true;
          _quietStart = quiet['start'] ?? '22:00';
          _quietEnd = quiet['end'] ?? '08:00';
        }
      });
    }
    if (mounted) setState(() => _isLoadingPreferences = false);
  }

  Future<void> _savePreferences() async {
    final prefsMap = {
      'enableAutoNotifications': _enableAutoNotifications,
      'categories': _categoryConfigs,
      'quietHours': {
        'enabled': _quietHoursEnabled,
        'start': _quietStart,
        'end': _quietEnd,
      }
    };
    final success = await context.read<NotificationProvider>().saveNotificationPreferences(prefsMap);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Notification preferences saved successfully!' : 'Failed to save preferences'),
          backgroundColor: success ? Colors.green : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _triggerAiAnalysis() async {
    final provider = context.read<NotificationProvider>();
    final result = await provider.triggerAnalysis();
    if (result != null && mounted) {
      final analyzed = result['data']?['analyzedUsers'] ?? 'all';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Analysis complete! Auto push dispatched to $analyzed users.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _tabController.animateTo(1); // Sent History tab
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to trigger AI analysis.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendTestPush() async {
    final provider = context.read<NotificationProvider>();
    final success = await provider.sendSelfTestNotification(
      fcmToken: _fcmTokenController.text.trim().isEmpty ? 'admin_fcm_token_sample' : _fcmTokenController.text.trim(),
      title: _testTitleController.text.trim(),
      message: _testMessageController.text.trim(),
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test push notification sent successfully to admin device!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _tabController.animateTo(1); // Sent History tab
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send test push notification.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyTemplate(Map<String, String> template) {
    setState(() {
      _titleController.text = template['title'] ?? '';
      _messageController.text = template['message'] ?? '';
      _selectedCategory = template['category'] ?? 'General';
      _selectedAudience = template['audience'] ?? 'all';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied "${template['label']}" template'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _triggerLocalTestPush() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();

    final title = _titleController.text.trim().isEmpty
        ? '🔥 Special Offer - Test Push'
        : _titleController.text.trim();
    final message = _messageController.text.trim().isEmpty
        ? 'This is a sample local test push notification banner.'
        : _messageController.text.trim();

    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        elevation: 8,
        backgroundColor: Colors.grey.shade900,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 24),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('DISMISS', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

  void _confirmAndSend() {
    if (!_formKey.currentState!.validate()) return;

    final targetAudienceLabel = _selectedAudience == 'all'
        ? '🌐 All Users'
        : _selectedAudience == 'subscribed'
            ? '👑 Subscribed Members'
            : '🎯 Specific User';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.send_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(child: Text('Confirm Broadcast', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to broadcast this push notification immediately?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Title: ${_titleController.text}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target: $targetAudienceLabel',
                    style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('Category: $_selectedCategory', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendNotification();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Send Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotification() async {
    final provider = context.read<NotificationProvider>();
    final target = _selectedAudience;
    
    String type = 'general';
    if (_selectedCategory == 'Promo') type = 'promo';
    else if (_selectedCategory == 'Platform News') type = 'announcement';
    else if (_selectedCategory == 'Health Tip') type = 'wellness_tip';
    else if (_selectedCategory == 'Order Update') type = 'order_update';

    final success = await provider.sendAdminNotification(
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      target: target,
      targetUserId: target == 'specific' ? _specificUserId : '',
      type: type,
      icon: '🎁',
      imageUrl: _imageController.text.trim(),
    );

    if (success && mounted) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();

      _titleController.clear();
      _messageController.clear();
      _imageController.clear();
      _tabController.animateTo(1); // Switch to Sent History tab

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Push notification broadcasted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send notification. Please check server logs.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getSubtleGradient(isDark),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 16),
              _buildTabBar(isDark),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildComposeTab(isDark),
                    _buildHistoryTab(isDark),
                    _buildAutoAiTab(isDark),
                    _buildTestPushTab(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Push Notification Manager',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Create custom push campaigns, manage auto AI alerts, view sent history & run device tests',
          style: TextStyle(color: AppColors.getSecondaryTextColor(isDark), fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
        tabs: const [
          Tab(
            iconMargin: EdgeInsets.only(bottom: 2),
            icon: Icon(Icons.campaign_outlined, size: 16),
            text: 'Compose',
          ),
          Tab(
            iconMargin: EdgeInsets.only(bottom: 2),
            icon: Icon(Icons.history_rounded, size: 16),
            text: 'History',
          ),
          Tab(
            iconMargin: EdgeInsets.only(bottom: 2),
            icon: Icon(Icons.psychology_rounded, size: 16),
            text: 'Auto AI',
          ),
          Tab(
            iconMargin: EdgeInsets.only(bottom: 2),
            icon: Icon(Icons.phone_android_rounded, size: 16),
            text: 'Test Push',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: COMPOSE CAMPAIGN
  // ==========================================
  Widget _buildComposeTab(bool isDark) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return SingleChildScrollView(
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildComposeFormCard(isDark)),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildPreviewSidePanel(isDark)),
              ],
            )
          : Column(
              children: [
                _buildComposeFormCard(isDark),
                const SizedBox(height: 20),
                _buildPreviewSidePanel(isDark),
              ],
            ),
    );
  }

  Widget _buildComposeFormCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text('Quick Templates', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickTemplates.map((tmpl) {
                return ActionChip(
                  avatar: Text(tmpl['label']!.split(' ').first),
                  label: Text(
                    tmpl['label']!.replaceFirst(RegExp(r'^\S+\s*'), ''),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                  onPressed: () => _applyTemplate(tmpl),
                );
              }).toList(),
            ),

            const Divider(height: 28),

            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;

                final categoryWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v ?? 'General'),
                    ),
                  ],
                );

                final audienceWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Target Audience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedAudience,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('🌐 All Users', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'subscribed',
                          child: Text('👑 Subscribed', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'specific',
                          child: Text('🎯 Specific User', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedAudience = v ?? 'all'),
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      categoryWidget,
                      const SizedBox(height: 14),
                      audienceWidget,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: categoryWidget),
                    const SizedBox(width: 14),
                    Expanded(child: audienceWidget),
                  ],
                );
              },
            ),

            if (_selectedAudience == 'specific') ...[
              const SizedBox(height: 14),
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  return DropdownButtonFormField<String>(
                    value: userProvider.users.any((u) => u.id == _specificUserId) ? _specificUserId : null,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select Specific Recipient',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: userProvider.users.map((u) {
                      return DropdownMenuItem(
                        value: u.id,
                        child: Text('${u.name} (${u.email})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _specificUserId = v ?? ''),
                    validator: (v) => _selectedAudience == 'specific' && (v == null || v.isEmpty) ? 'Please select a target user' : null,
                  );
                },
              ),
            ],

            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Notification Title *',
                hintText: 'e.g. 🔥 Flash Sale - 50% Off!',
                prefixIcon: const Icon(Icons.title_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message Body *',
                hintText: 'Enter your custom broadcast message details here...',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.message_rounded, size: 20),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Message body is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _imageController,
              decoration: InputDecoration(
                labelText: 'Image Banner URL (Optional)',
                hintText: 'https://example.com/banner.jpg',
                prefixIcon: const Icon(Icons.image_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;

                final testBtn = OutlinedButton.icon(
                  onPressed: _triggerLocalTestPush,
                  icon: const Icon(Icons.vibration_rounded, color: AppColors.primary, size: 18),
                  label: const Text('Test Local Push', overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );

                final broadcastBtn = Consumer<NotificationProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _confirmAndSend,
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.campaign_rounded, size: 18),
                      label: Text(
                        provider.isLoading ? 'Sending...' : 'Broadcast Push',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      testBtn,
                      const SizedBox(height: 10),
                      broadcastBtn,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: testBtn),
                    const SizedBox(width: 12),
                    Expanded(child: broadcastBtn),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSidePanel(bool isDark) {
    final title = _titleController.text.trim().isEmpty
        ? '🔥 Special Flash Sale Today!'
        : _titleController.text.trim();
    final message = _messageController.text.trim().isEmpty
        ? 'Your custom push notification text will appear right here on the lock screen of targeted devices.'
        : _messageController.text.trim();
    final imageUrl = _imageController.text.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_iphone_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Live Lock Screen Preview', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.black87, Colors.grey.shade900]
                    : [Colors.blueGrey.shade800, Colors.blueGrey.shade900],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('09:41', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Icon(Icons.wifi_rounded, color: Colors.white.withValues(alpha: 0.8), size: 12),
                        const SizedBox(width: 4),
                        Icon(Icons.battery_full_rounded, color: Colors.white.withValues(alpha: 0.8), size: 12),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.notifications_active, color: Colors.white, size: 12),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ADMINKOSMICO',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const Spacer(),
                          Text(
                            'now',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  message,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.hasAbsolutePath == true) ...[
                            const SizedBox(width: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white54, size: 20),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedCategory.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: SENT HISTORY
  // ==========================================
  Widget _buildHistoryTab(bool isDark) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No notifications sent yet',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Switch to "Compose" tab to broadcast your first message.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
          ),
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: provider.notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 64),
            itemBuilder: (context, index) {
              final n = provider.notifications[index];
              final notificationId = n['_id']?.toString() ?? '';
              final title = n['title'] ?? 'No Title';
              final message = n['message'] ?? '';
              final category = n['category'] ?? n['type'] ?? 'General';
              final createdAt = n['createdAt'] != null ? DateTime.tryParse(n['createdAt']) : null;

              return Dismissible(
                key: Key(notificationId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await _showDeleteConfirm(n);
                },
                onDismissed: (direction) {
                  provider.deleteNotification(notificationId);
                },
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category.toString().toUpperCase(),
                            style: TextStyle(color: Colors.grey.shade800, fontSize: 9, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        final targetId = (n['audience'] ?? n['user'] ?? '').toString();
                        String displayName = targetId.toUpperCase();

                        if (targetId == 'all') {
                          displayName = '🌐 ALL USERS';
                        } else if (targetId == 'subscribed') {
                          displayName = '👑 SUBSCRIBED';
                        } else if (targetId == 'active') {
                          displayName = '⚡ ACTIVE ONLY';
                        } else {
                          final user = userProvider.users.firstWhere(
                            (u) => u.id == targetId,
                            orElse: () => User(id: '', name: '', email: '', accountStatus: '', isAdmin: false),
                          );
                          if (user.name.isNotEmpty) {
                            displayName = '🎯 ${user.name.toUpperCase()}';
                          } else if (targetId.length > 8) {
                            displayName = '🎯 USER: ${targetId.substring(targetId.length - 6).toUpperCase()}';
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 3),
                            Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 6),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      createdAt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt) : 'Just now',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    displayName,
                                    style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: AUTO AI SETTINGS & TRIGGER
  // ==========================================
  Widget _buildCategoryConfigTile(String key, String title, IconData icon, Color color) {
    final config = _categoryConfigs[key] ?? {'enabled': true, 'frequency': 'daily'};
    final isEnabled = config['enabled'] == true;
    final frequency = config['frequency']?.toString() ?? 'daily';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon == Icons.water_drop_rounded
                  ? WaterDropTransition(child: Icon(icon, color: color, size: 20))
                  : Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Switch(
                value: isEnabled,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  setState(() {
                    _categoryConfigs[key] = {'enabled': v, 'frequency': frequency};
                  });
                },
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Schedule Frequency:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: frequency,
                    isDense: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'instant', child: Text('⚡ Instant (Real-time)', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: '30m', child: Text('⏱ Every 30 Mins', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: '1h', child: Text('⏱ Every 1 Hour', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: '2h', child: Text('⏱ Every 2 Hours', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'daily', child: Text('📅 Daily (24h)', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'weekly', child: Text('🗓 Weekly (7 Days)', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _categoryConfigs[key] = {'enabled': isEnabled, 'frequency': v ?? 'daily'};
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoAiTab(bool isDark) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text('Platform Auto Notifications & AI Engine', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Configure automated smart alerts, quiet hours, category triggers, and run instant AI activity analysis.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 30),

            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                title: const Text('Enable Platform Auto Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Allow backend AI engine to automatically send scheduled engagement alerts.', style: TextStyle(fontSize: 12)),
                value: _enableAutoNotifications,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _enableAutoNotifications = v),
              ),
            ),
            const Divider(height: 20),

            Text('Per-Feature Auto Push Schedules & Frequencies', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Configure individual push notification schedules and frequencies for each health and business feature.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            _buildCategoryConfigTile('waterIntake', 'Water Intake Reminders', Icons.water_drop_rounded, Colors.blue),
            _buildCategoryConfigTile('stepCount', 'Step Count Activity Boosts', Icons.directions_walk_rounded, Colors.green),
            _buildCategoryConfigTile('bloodPressure', 'Blood Pressure Check-ins', Icons.favorite_rounded, Colors.red),
            _buildCategoryConfigTile('plateScan', 'Plate Scan Nutrition Insights', Icons.restaurant_rounded, Colors.orange),
            _buildCategoryConfigTile('promos', 'Promo & Special Offers', Icons.local_offer_rounded, Colors.amber),
            _buildCategoryConfigTile('orderUpdates', 'Order & Delivery Updates', Icons.local_shipping_rounded, Colors.purple),
            _buildCategoryConfigTile('healthTips', 'Health & Wellness Tips', Icons.spa_rounded, Colors.teal),

            const Divider(height: 20),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                title: const Text('Quiet Hours Enabled', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Suppress non-urgent notifications between $_quietStart and $_quietEnd.', style: const TextStyle(fontSize: 12)),
                value: _quietHoursEnabled,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _quietHoursEnabled = v),
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _savePreferences,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Save Preferences'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Consumer<NotificationProvider>(
                    builder: (context, provider, _) {
                      return ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : _triggerAiAnalysis,
                        icon: provider.isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.bolt_rounded, size: 18),
                        label: Text(provider.isLoading ? 'Running AI...' : 'Trigger AI Analysis & Push'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 4: SELF TEST PUSH
  // ==========================================
  Widget _buildTestPushTab(bool isDark) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text('Send Self Test Notification (Admin Device)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Test push delivery instantly to your registered admin device using your FCM device token.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 30),

            TextFormField(
              controller: _fcmTokenController,
              decoration: InputDecoration(
                labelText: 'Admin FCM Device Token *',
                hintText: 'Enter your device FCM token here...',
                prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _testTitleController,
              decoration: InputDecoration(
                labelText: 'Test Notification Title *',
                prefixIcon: const Icon(Icons.title_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _testMessageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Test Message Body *',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.message_rounded, size: 20),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _sendTestPush,
                    icon: provider.isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(provider.isLoading ? 'Sending Test...' : 'Send Self Test Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(dynamic notification) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Notification'),
        content: Text('Are you sure you want to delete "${notification['title']}" from history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
