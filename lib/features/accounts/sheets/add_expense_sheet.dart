import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../auth/state/auth_provider.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

import '../../../core/utils/app_notification.dart';
class AddExpenseSheet {
  AddExpenseSheet._();

  static void show(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canManageAccounts(
      auth.currentRole,
      user: auth.currentUser,
    )) {
      AppNotification.show(
        context,
        message:
            'Action restricted: Only Accounts & Proprietor can create outgoing payments.',
      );
      return;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final vendorController = TextEditingController();

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: AppSizes.sheetShape,
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: AppSizes.sheetBottomPadding(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandPeach.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.brandPeach,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Log Outgoing Payment / Expense',
                              style: AppTypography.titleLarge(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Expense Description (e.g. Hardware fittings, Petty cash)',
                    ),
                  ),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('Amount (₹)'),
                  ),
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: vendorController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('Paid To / Vendor'),
                  ),
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPeach,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  final title = titleController.text.trim();
                  final amount = amountController.text.trim();
                  final vendor = vendorController.text.trim();
                  if (title.isEmpty) return;
                  final newExpense = {
                    'id': 'EXP-${DateTime.now().millisecondsSinceEpoch}',
                    'title': title,
                    'amount': amount.isNotEmpty ? '₹ $amount' : '₹ 0',
                    'direction': 'outgoing',
                    'source': 'accounts',
                    'vendor': vendor.isNotEmpty
                        ? vendor
                        : 'Direct Site Purchase',
                    'date': DateFormat('dd MMM yyyy').format(DateTime.now()),
                    'status': 'Approved',
                    'color': AppColors.warning,
                  };
                  final allExpenses = StorageService.getExpenses();
                  allExpenses.insert(0, newExpense);
                  StorageService.saveExpenses(allExpenses);
                  MobileActionSheets.expenseCreatedNotifier.value = newExpense;

                  Navigator.pop(context);
                  AppNotification.show(context, message: 'Expense "$title" recorded in ledger!', backgroundColor: AppColors.success);
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  'Record Expense',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
