import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Drawer(
      elevation: isDesktop ? 0 : 20,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Container(
        width: AppConstants.sidebarWidth,
        decoration: BoxDecoration(
          gradient: AppColors.getSubtleGradient(isDark),
        ),
        child: Column(
          children: [
            // Glassmorphism Logo Header
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Image.asset(
                'images/logo.png',
                height: 70,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.spa_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'KOSMICO',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.primary,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                children: [
                  _buildSectionTitle('MAIN MENU', isDark),
                  _buildNavItem(context, 0, Icons.grid_view_rounded, 'Overview', isDark),
                  _buildNavItem(context, 1, Icons.inventory_2_outlined, 'Products', isDark),
                  _buildNavItem(context, 2, Icons.category_outlined, 'Categories', isDark),
                  _buildNavItem(context, 3, Icons.confirmation_number_outlined, 'Coupons', isDark),
                  _buildNavItem(context, 4, Icons.shopping_bag_outlined, 'Orders', isDark),
                  _buildNavItem(context, 5, Icons.people_outline_rounded, 'Users', isDark),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Divider(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  ),
                  
                  _buildSectionTitle('COMMUNICATION', isDark),
                  _buildNavItem(context, 6, Icons.notifications_none_rounded, 'Notifications', isDark),
                  
                  _buildSectionTitle('SYSTEM', isDark),
                  _buildNavItem(context, 7, Icons.account_balance_wallet_outlined, 'Payments', isDark),
                  _buildNavItem(context, 8, Icons.system_update_outlined, 'App Updates', isDark),
                  _buildNavItem(context, 9, Icons.settings_outlined, 'Maintenance', isDark),
                ],
              ),
            ),
            
            _buildProfileCard(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 16, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white.withOpacity(0.4) : AppColors.textDark.withOpacity(0.5),
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, bool isDark) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuint,
            decoration: BoxDecoration(
              gradient: isSelected 
                ? LinearGradient(
                    colors: isDark
                      ? [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.02)]
                      : [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.01)],
                  )
                : null,
              borderRadius: BorderRadius.circular(20),
              border: isSelected 
                ? Border.all(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.primary.withOpacity(0.05))
                : null,
            ),
            child: ListTile(
              onTap: () => onItemSelected(index),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? (isDark ? AppColors.accent.withOpacity(0.2) : AppColors.primary.withOpacity(0.1))
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected 
                    ? (isDark ? AppColors.accent : AppColors.primary) 
                    : (isDark ? Colors.white.withOpacity(0.4) : AppColors.textDark.withOpacity(0.7)),
                  size: 20,
                ),
              ),
              title: Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected 
                    ? (isDark ? Colors.white : AppColors.primary) 
                    : (isDark ? Colors.white.withOpacity(0.7) : AppColors.textDark.withOpacity(0.9)),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          
          if (isSelected)
            Positioned(
              left: 0,
              top: 15,
              bottom: 15,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, bool isDark) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: (isDark ? AppColors.accent : AppColors.primary).withOpacity(0.5), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? const Color(0xFF1B5E20) : AppColors.primary.withOpacity(0.1),
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'A',
                style: TextStyle(color: isDark ? Colors.white : AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.name ?? 'Admin',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, 
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Super Admin',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutDialog(context, isDark),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded, 
                  size: 18, 
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0D3310) : Colors.white,
        title: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
        content: Text('Are you sure you want to log out?', style: TextStyle(color: (isDark ? Colors.white : AppColors.textDark).withOpacity(0.7))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: (isDark ? Colors.white : AppColors.textDark).withOpacity(0.5)))),
          ElevatedButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
