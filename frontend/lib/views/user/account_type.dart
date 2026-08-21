import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/paw_widget.dart';
import '../../widgets/back_button.dart';
import 'admin/admin_login.dart';
import 'user_login.dart'; // 🔵 badalt mel 'user_login.dart': el file/class
// tbeddel esmou l user_signin.dart / UserSignInScreen (nafs conteúdo el
// "Sign up" el 9dim, ghir esmou tbeddel)

class _AccountType {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;

  const _AccountType({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });
}

class AccountTypeView extends StatelessWidget {
  const AccountTypeView({super.key});

  static const List<_AccountType> _accountTypes = [
    _AccountType(
      icon: Icons.person,
      titleKey: 'account_type_admin_title',
      descriptionKey: 'account_type_admin_description',
    ),
    _AccountType(
      icon: Icons.pets,
      titleKey: 'account_type_sitter_title',
      descriptionKey: 'account_type_sitter_description',
    ),
    _AccountType(
      icon: Icons.admin_panel_settings,
      titleKey: 'account_type_courier_title',
      descriptionKey: 'account_type_courier_description',
    ),
    _AccountType(
      icon: Icons.local_shipping,
      titleKey: 'account_type_owner_title',
      descriptionKey: 'account_type_owner_description',
    ),
  ];

  // --------------------------------------------------------------------
  // 🔵 Admin -> AdminLoginView
  // 🔵 Owner / Sitter / Courier -> UserSignInScreen (m3a passation mte3 role)
  // --------------------------------------------------------------------
  void _onAccountTypeSelected(BuildContext context, _AccountType type) {
    if (type.titleKey == 'account_type_admin_title') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminLoginView()),
      );
    } else {
      String selectedRole = 'owner';
      if (type.titleKey == 'account_type_sitter_title') {
        selectedRole = 'sitter';
      } else if (type.titleKey == 'account_type_courier_title') {
        selectedRole = 'courier';
      } else if (type.titleKey == 'account_type_owner_title') {
        selectedRole = 'owner';
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserLoginScreen(role: selectedRole),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            buildPetPaw(context: context, size: sizes.accountTypePawSize1, topPercent: 0.04, leftPercent: 0.14, color: AppColors.pinkpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.accountTypePawSize2, topPercent: 0.03, leftPercent: 0.75, color: AppColors.pinkpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.accountTypePawSize3, topPercent: 0.02, leftPercent: 0.45, color: AppColors.vertpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.accountTypePawSize4, topPercent: 0.42, leftPercent: 0.005, color: AppColors.vertpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.accountTypePawSize5, topPercent: 0.45, leftPercent: 0.000005, color: AppColors.vertpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.accountTypePawSize6, topPercent: 0.63, leftPercent: 0.95, color: AppColors.vertpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.accountTypePawSize7, topPercent: 0.65, leftPercent: 0.85, color: AppColors.vertpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.accountTypePawSize8, topPercent: 0.77, leftPercent: 0.02, color: AppColors.vertpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.accountTypePawSize9, topPercent: 0.8, leftPercent: 0.07, color: AppColors.vertpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.accountTypePawSize10, topPercent: 0.95, leftPercent: 0.07, color: AppColors.vertpetsy.withOpacity(0.6)),
            buildPetPaw(context: context, size: sizes.accountTypePawSize11, topPercent: 0.9, leftPercent: 0.005, color: AppColors.vertpetsy.withOpacity(0.6)),

            // 🔙 Back button -> yerja3 lel écran Welcome
            const CustomBackButton(),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: sizes.accountTypeHorizontalPadding),
              child: Column(
                children: [
                  SizedBox(height: sizes.accountTypeTopGap),

                  Image.asset(
                    'assets/images/ppetsy.png',
                    width: sizes.accountTypeLogoWidth,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: sizes.accountTypeLogoTitleGap),
                  Text(
                    'choose_account_type_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: sizes.accountTypeTitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pinkpetsy,
                    ),
                  ),

                  SizedBox(height: sizes.accountTypeTitleButtonsGap),

                  Column(
                    children: _accountTypes.map((type) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: sizes.accountTypeButtonSpacing),
                        child: _AccountTypeButton(
                          type: type,
                          mutedTextColor: mutedTextColor,
                          onTap: () => _onAccountTypeSelected(context, type),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: sizes.accountTypeBottomGap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _AccountTypeButton
// ============================================================================
class _AccountTypeButton extends StatelessWidget {
  final _AccountType type;
  final Color mutedTextColor;
  final VoidCallback onTap;

  const _AccountTypeButton({
    required this.type,
    required this.mutedTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return Center(
      child: SizedBox(
        width: sizes.accountButtonWidth,
        height: sizes.accountButtonHeight,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pinkpetsy,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: sizes.accountButtonPaddingH,
              vertical: sizes.accountButtonPaddingV,
            ),
          ),
          child: Row(
            children: [
              Icon(
                type.icon,
                color: Colors.white,
                size: sizes.accountButtonIconSize,
              ),
              SizedBox(width: sizes.accountButtonGap),

              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.titleKey.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: sizes.accountButtonTitleFontSize,
                        ),
                      ),
                      SizedBox(height: sizes.accountButtonTitleGap),
                      Text(
                        type.descriptionKey.tr(),
                        style: TextStyle(
                          fontSize: sizes.accountButtonDescFontSize,
                          color: Colors.white70,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: sizes.accountButtonEndGap),

              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: sizes.accountButtonArrowIconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}