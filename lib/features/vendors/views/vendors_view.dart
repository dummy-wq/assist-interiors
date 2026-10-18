import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import '../../dashboard/widgets/mobile_action_sheets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/backend_manager.dart';
import '../../../core/services/phone_call_service.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/models/vendor_model.dart';
import '../../auth/state/auth_provider.dart';

class VendorsView extends StatefulWidget {
  const VendorsView({super.key});

  @override
  State<VendorsView> createState() => _VendorsViewState();
}

class _VendorsViewState extends State<VendorsView> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _vendors = [];

  @override
  void initState() {
    super.initState();
    _vendors.addAll(StorageService.getVendors());
    MobileActionSheets.vendorCreatedNotifier.addListener(_onVendorCreated);
  }

  @override
  void dispose() {
    MobileActionSheets.vendorCreatedNotifier.removeListener(_onVendorCreated);
    _searchController.dispose();
    super.dispose();
  }

  void _onVendorCreated() {
    final vendor = MobileActionSheets.vendorCreatedNotifier.value;
    if (vendor != null && mounted) {
      setState(() {
        _vendors.insert(0, Map<String, dynamic>.from(vendor));
      });
      StorageService.saveVendors(_vendors);
      BackendManager.instance.createVendor(VendorModel.fromMap(vendor));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final canManageVendors = AppPermissions.canManageVendors(auth.currentRole);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalOpenPOs = 0;
    int totalOutstanding = 0;
    for (final v in _vendors) {
      totalOpenPOs += (v['openPOs'] as num?)?.toInt() ?? 0;
      final raw =
          (v['amountDue'] as String? ?? v['outstanding'] as String? ?? '')
              .replaceAll(RegExp(r'[^0-9]'), '');
      totalOutstanding += int.tryParse(raw) ?? 0;
    }
    final outstandingStr = totalOutstanding > 0
        ? NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹ ',
            decimalDigits: 0,
          ).format(totalOutstanding)
        : '₹ 0';

    final filteredVendors = _vendors.where((v) {
      if (_selectedCategory != 'All' && v['category'] != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final name = (v['name'] ?? '').toString().toLowerCase();
        final cat = (v['category'] ?? '').toString().toLowerCase();
        final contact = (v['contact'] ?? v['phone'] ?? '')
            .toString()
            .toLowerCase();
        final email = (v['email'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery) &&
            !cat.contains(_searchQuery) &&
            !contact.contains(_searchQuery) &&
            !email.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();

    final categories = <String>{
      'All',
      'Plywood & Veneer',
      'Glass & Mirrors',
      'Hardware & Channels',
      'Stones & Marble',
      'HVAC & Electrical',
      ..._vendors
          .map((v) => v['category']?.toString() ?? '')
          .where((c) => c.isNotEmpty),
    }.toList();

    return ScreenScrollView(
      children: [
        const ScreenHeader('Vendors & Suppliers'),
        const SizedBox(height: ScreenLayout.headerGap),

        // Stats Strip (Compact StatStrip)
        StatStrip(
          cards: [
            StatCard(
              title: 'Vendors',
              value: '${_vendors.length} Partners',
              icon: Icons.storefront_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Active POs',
              value: '$totalOpenPOs Indents',
              icon: Icons.receipt_long_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Payables',
              value: outstandingStr,
              icon: Icons.account_balance_wallet_rounded,
              accentColor: AppColors.warning,
            ),
            StatCard(
              title: 'Fulfillment',
              value: _vendors.isEmpty ? '--' : '96.2%',
              trend: _vendors.isNotEmpty ? '96.2%' : null,
              icon: Icons.verified_rounded,
              accentColor: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: ScreenLayout.sectionGap),

        ScreenSearchField(
          controller: _searchController,
          hintText: 'Search vendors by name, category, or contact...',
          onChanged: (q) => setState(() => _searchQuery = q),
        ),
        const SizedBox(height: ScreenLayout.controlGap),

        // Category Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PillBox(
                  label: cat,
                  isSelected: isSelected,
                  activeColor: AppColors.brandPeach,
                  onSelected: () => setState(() => _selectedCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: ScreenLayout.listGap),

        // Vendors List — animated on filter change
        FilterSwitcher(
          child: filteredVendors.isEmpty
              ? EmptyStateCard(
                  key: ValueKey('empty_vendors_$_selectedCategory'),
                  icon: Icons.storefront_outlined,
                  title: _selectedCategory == 'All'
                      ? 'No Vendors Registered'
                      : 'No $_selectedCategory Vendors',
                  message: _selectedCategory == 'All'
                      ? (canManageVendors
                            ? 'All vendor records have been cleared. Tap "Add Vendor" to onboard trade partners.'
                            : 'All vendor records have been cleared.')
                      : 'No vendors found in "$_selectedCategory" category.',
                  action: (_selectedCategory != 'All' ||
                          _searchQuery.isNotEmpty)
                      ? OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedCategory = 'All';
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Show All Vendors'),
                        )
                      : null,
                )
              : ListView.separated(
                  key: ValueKey(_selectedCategory),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredVendors.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: ScreenLayout.itemGap),
                  itemBuilder: (context, index) {
                    final v = filteredVendors[index];
                    final name = (v['name'] as String?) ?? 'Trade Partner';
                    final category =
                        (v['category'] as String?) ?? 'General Works';
                    final contactPerson =
                        (v['contactPerson'] as String?) ?? 'Site Rep';
                    final phone = (v['phone'] as String?) ?? '';
                    final email = (v['email'] as String?) ?? '';
                    final city = (v['city'] as String?) ?? '';
                    final paymentStatus =
                        (v['paymentStatus'] as String?) ??
                        (v['status'] as String?) ??
                        'Pending';
                    final amountDue =
                        (v['amountDue'] as String?) ??
                        (v['outstanding'] as String?) ??
                        '₹ 0';
                    final notes = (v['notes'] as String?) ?? '';

                    Color statusColor;
                    IconData statusIcon;
                    if (paymentStatus.toLowerCase() == 'complete' ||
                        paymentStatus.toLowerCase() == 'settled') {
                      statusColor = AppColors.success;
                      statusIcon = Icons.check_circle_outline_rounded;
                    } else if (paymentStatus.toLowerCase() == 'partial') {
                      statusColor = AppColors.brandPeach;
                      statusIcon = Icons.timelapse_rounded;
                    } else {
                      statusColor = AppColors.warning;
                      statusIcon = Icons.hourglass_top_rounded;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder.withValues(alpha: 0.7)
                              : AppColors.lightBorder.withValues(alpha: 0.8),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.03,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Header Row — icon, name, category/city tags, payment status badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Icon(
                                  Icons.storefront_rounded,
                                  color: statusColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTypography.titleMedium(isDark),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkBackground
                                                : AppColors.lightBackground,
                                            borderRadius: BorderRadius.circular(
                                              4.0,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? AppColors.darkBorder
                                                  : AppColors.lightBorder,
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            category,
                                            style:
                                                AppTypography.bodySmall(
                                                  isDark,
                                                ).copyWith(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        if (city.isNotEmpty)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.place_outlined,
                                                size: 11,
                                                color: isDark
                                                    ? AppColors.textLightMuted
                                                    : AppColors.textDarkMuted,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                city,
                                                style: AppTypography.bodySmall(
                                                  isDark,
                                                ).copyWith(fontSize: 10.5),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(
                                    alpha: isDark ? 0.2 : 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(4.0),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 12,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      paymentStatus,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 2. Contact & Details Container (Contact Person, Phone, Email)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground.withValues(
                                      alpha: 0.7,
                                    )
                                  : AppColors.lightBackground.withValues(
                                      alpha: 0.8,
                                    ),
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder.withValues(
                                        alpha: 0.5,
                                      )
                                    : AppColors.lightBorder.withValues(
                                        alpha: 0.6,
                                      ),
                                width: 0.6,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline_rounded,
                                      size: 14,
                                      color: AppColors.brandPeach,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        contactPerson,
                                        style: AppTypography.bodySmall(
                                          isDark,
                                        ).copyWith(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(4.0),
                                      onTap: phone.isNotEmpty
                                          ? () => PhoneCallService.dialNumber(
                                              context,
                                              phoneNumber: phone,
                                              contactName:
                                                  '$name ($contactPerson)',
                                            )
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.phone_outlined,
                                              size: 13,
                                              color: phone.isNotEmpty
                                                  ? AppColors.brandPeach
                                                  : (isDark
                                                        ? AppColors
                                                              .textLightMuted
                                                        : AppColors
                                                              .textDarkMuted),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              phone,
                                              style:
                                                  AppTypography.bodySmall(
                                                    isDark,
                                                  ).copyWith(
                                                    decoration: phone.isNotEmpty
                                                        ? TextDecoration
                                                              .underline
                                                        : null,
                                                    decorationColor: AppColors
                                                        .brandPeach
                                                        .withValues(alpha: 0.5),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 13,
                                        color: isDark
                                            ? AppColors.textLightMuted
                                            : AppColors.textDarkMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          email,
                                          style: AppTypography.bodySmall(isDark)
                                              .copyWith(fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 3. Financials & Actions Row (Amount Due + Indent Action)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      child: Icon(
                                        Icons.currency_rupee_rounded,
                                        size: 14,
                                        color: statusColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AMOUNT DUE',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.6,
                                              color: isDark
                                                  ? AppColors.textLightMuted
                                                  : AppColors.textDarkMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            amountDue,
                                            style: AppTypography.titleMedium(isDark)
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      paymentStatus.toLowerCase() ==
                                                          'complete'
                                                      ? AppColors.success
                                                      : (isDark
                                                            ? AppColors
                                                                  .textLightPrimary
                                                            : AppColors
                                                                  .textDarkPrimary),
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.brandPeach,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'PO indent dispatched to $name',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Place Indent',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // 4. Notes Callout (if notes provided)
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandPeach.withValues(
                                  alpha: isDark ? 0.08 : 0.05,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: AppColors.brandPeach.withValues(
                                    alpha: 0.25,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.sticky_note_2_outlined,
                                    size: 13,
                                    color: AppColors.brandPeach,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      notes,
                                      style: AppTypography.bodySmall(isDark)
                                          .copyWith(
                                            fontSize: 11.5,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
