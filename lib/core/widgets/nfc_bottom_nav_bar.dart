import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

/// Barra de navegação inferior customizada fiel às pranchas de design do NFC Ops.
/// Fundo #10110F, abas: Início, Empresas, botão central '+', Estoque, Mais.
/// Aba ativa tem fundo circular amarelo (#FACC15) com ícone escuro e texto amarelo.
class NfcBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const NfcBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: (height ?? 83) + bottomInset,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: Color(0xFF242523),
            width: 1.0,
          ),
        ),
      ),
      padding: padding ?? EdgeInsets.fromLTRB(0, 0, 0, 10 + bottomInset),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              label: 'Início',
              icon: Icons.home_outlined,
            ),
            _buildNavItem(
              index: 1,
              label: 'Empresas',
              icon: LucideIcons.building2,
            ),
            _buildCenterPlusButton(context),
            _buildNavItem(
              index: 3,
              label: 'Estoque',
              icon: LucideIcons.box,
            ),
            _buildNavItem(
              index: 4,
              label: 'Mais',
              icon: LucideIcons.moreHorizontal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = currentIndex == index;
    const yellowActive = Color(0xFFFACC15);

    return InkWell(
      onTap: () => onDestinationSelected(index),
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? yellowActive : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? const Color(0xFF10110F) : const Color(0xFF8E918F),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? yellowActive : const Color(0xFF8E918F),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPlusButton(BuildContext context) {
    return InkWell(
      onTap: () => onDestinationSelected(2),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: AppColors.orangeAction,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x66FF4F0A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
