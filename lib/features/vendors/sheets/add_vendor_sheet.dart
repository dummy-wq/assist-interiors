import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/custom_entry_dropdown.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

import '../../../core/utils/app_notification.dart';
class AddVendorSheet {
  AddVendorSheet._();

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final categoryController = TextEditingController(text: 'Plywood & Veneer');
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final cityController = TextEditingController();
    String selectedPaymentStatus =
        'Pending'; // 'Pending', 'Complete', 'Partial'
    final amountDueController = TextEditingController();
    final notesController = TextEditingController();

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: AppSizes.sheetBottomPadding(context),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.brandPeach.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: AppColors.brandPeach,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Onboard Trade Vendor',
                                  style: AppTypography.titleLarge(isDark),
                                  overflow: TextOverflow.ellipsis,
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

                    // 1. Vendor Name
                    TextField(
                      controller: nameController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Vendor Name'),
                        ),
                        hintText: 'Company / Firm Name',
                        prefixIcon: Icon(Icons.store_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Category
                    TextField(
                      controller: categoryController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Trade Category (e.g. Italian Marble, Hardware, Glass)',
                          ),
                        ),
                        hintText:
                            'Trade Category (e.g. Italian Marble, Hardware, Glass)',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Contact Person
                    TextField(
                      controller: contactController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Contact Person'),
                        ),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. Phone Number
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+\- ]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Phone Number'),
                        ),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 5. Email
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Email Address'),
                        ),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 6. City
                    TextField(
                      controller: cityController,
                      keyboardType: TextInputType.streetAddress,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('City / Base Location'),
                        ),
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 7. Payment Status
                    CustomEntryDropdown(
                      value: selectedPaymentStatus,
                      options: const ['Pending', 'Partial', 'Complete'],
                      customFieldLabel: 'Custom Payment Status',
                      customFieldHint: 'Enter payment status...',
                      decoration: const InputDecoration(
                        labelText: 'Payment Status',
                        prefixIcon: Icon(Icons.payment_rounded),
                      ),
                      onChanged: (val) {
                        setModalState(
                          () => selectedPaymentStatus = val,
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // 8. Amount Due
                    TextField(
                      controller: amountDueController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9,]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Amount Due (₹)'),
                        ),
                        hintText: 'e.g. 45,000',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 9. Notes
                    TextField(
                      controller: notesController,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Notes / Scope / Terms'),
                        ),
                        hintText:
                            'e.g. Delivery terms, GST info, quality specs',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPeach,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      onPressed: () {
                        final vendorName = nameController.text.trim().isEmpty
                            ? 'New Trade Partner'
                            : nameController.text.trim();
                        final category = categoryController.text.trim().isEmpty
                            ? 'General Works'
                            : categoryController.text.trim();
                        final contactPerson =
                            contactController.text.trim().isEmpty
                            ? 'Site Rep'
                            : contactController.text.trim();
                        final phone = phoneController.text.trim().isEmpty
                            ? '+91 98000 00000'
                            : phoneController.text.trim();
                        final email = emailController.text.trim();
                        final city = cityController.text.trim().isEmpty
                            ? 'Delhi NCR'
                            : cityController.text.trim();
                        final paymentStatus = selectedPaymentStatus;

                        final dueNum =
                            CurrencyUtils.parseAmount(amountDueController.text);
                        final amountDueStr = dueNum > 0
                            ? CurrencyUtils.formatInr(dueNum)
                            : (paymentStatus == 'Complete'
                                  ? '₹ 0'
                                  : (amountDueController.text.trim().isNotEmpty
                                        ? '₹ ${amountDueController.text.trim()}'
                                        : '₹ 0'));

                        final notes = notesController.text.trim();

                        Color statusColor = AppColors.warning;
                        if (paymentStatus == 'Complete') {
                          statusColor = AppColors.success;
                        } else if (paymentStatus == 'Partial') {
                          statusColor = AppColors.brandPeach;
                        } else {
                          statusColor = AppColors.error;
                        }

                        final newVendor = {
                          'id': 'vnd_${DateTime.now().millisecondsSinceEpoch}',
                          'name': vendorName,
                          'category': category,
                          'contactPerson': contactPerson,
                          'phone': phone,
                          'email': email,
                          'city': city,
                          'paymentStatus': paymentStatus,
                          'amountDue': amountDueStr,
                          'notes': notes,
                          'rating': '5.0',
                          'onTime': '100%',
                          'activeOrders': '0 Active Purchase Orders',
                          'status': paymentStatus == 'Complete'
                              ? 'Settled'
                              : paymentStatus,
                          'openPOs': 0,
                          'outstanding': amountDueStr,
                          'color': statusColor,
                        };

                        MobileActionSheets.vendorCreatedNotifier.value =
                            newVendor;
                        Navigator.pop(context);
                        AppNotification.show(context, message: 'Vendor registered in Assist Interiors procurement ledger!', backgroundColor: AppColors.success);
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text(
                        'Save Vendor Profile',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
