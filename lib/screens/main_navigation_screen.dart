import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'loans_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const LoansScreen(),
    const SettingsScreen(),
  ];


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(l10n),
    );
  }

  Widget _buildCustomBottomNavBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Stack(
        children: [
          // Background with blur effect
          Container(
            height: 85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: -5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
          ),
          // Content
          Container(
            height: 85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                _buildFinanceNavItem(
                  icon: Icons.home_filled,
                  label: l10n.dashboard,
                  index: 0,
                  color: const Color(0xFF6366F1), // Indigo
                ),
                _buildFinanceNavItem(
                  icon: Icons.swap_horiz_rounded,
                  label: l10n.transactions,
                  index: 1,
                  color: const Color(0xFF10B981), // Emerald
                ),
                _buildFinanceNavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: l10n.loans,
                  index: 2,
                  color: const Color(0xFFF59E0B), // Amber
                ),
                _buildFinanceNavItem(
                  icon: Icons.tune_rounded,
                  label: l10n.settings,
                  index: 3,
                  color: const Color(0xFF8B5CF6), // Violet
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceNavItem({
    required IconData icon,
    required String label,
    required int index,
    required Color color,
  }) {
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Selection background
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                top: isSelected ? 12 : 20,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  width: isSelected ? 50 : 0,
                  height: isSelected ? 50 : 0,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ] : [],
                  ),
                ),
              ),
              // Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  // Icon with animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.elasticOut,
                    transform: Matrix4.identity()
                      ..scale(isSelected ? 1.2 : 1.0)
                      ..translate(0.0, isSelected ? -2.0 : 0.0),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ] : [],
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: isSelected ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Label with animation
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      fontSize: isSelected ? 11 : 9,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? color : Colors.grey.shade600,
                      letterSpacing: 0.3,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.identity()
                        ..translate(0.0, isSelected ? -1.0 : 0.0),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Active indicator dot
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    width: isSelected ? 6 : 0,
                    height: isSelected ? 6 : 0,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}