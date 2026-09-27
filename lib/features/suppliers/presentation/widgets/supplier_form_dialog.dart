import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/supplier_cubit.dart';
import '../../data/models/supplier_model.dart';

class SupplierFormDialog extends StatefulWidget {
  final SupplierModel? supplier;

  const SupplierFormDialog({super.key, this.supplier});

  static void show(BuildContext context, {SupplierModel? supplier}) {
    final cubit = context.read<SupplierCubit>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => BlocProvider.value(
        value: cubit,
        child: SupplierFormDialog(supplier: supplier),
      ),
    );
  }

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _taxNumberController;
  late TextEditingController _paymentTermsController;
  late TextEditingController _categoriesController;
  late TextEditingController _notesController;

  double _rating = 5.0;
  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _nameController = TextEditingController(text: s?.name ?? '');
    _contactPersonController = TextEditingController(text: s?.contactPerson ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _taxNumberController = TextEditingController(text: s?.taxNumber ?? '');
    _paymentTermsController = TextEditingController(text: s?.paymentTerms ?? 'Cash');
    _categoriesController =
        TextEditingController(text: s?.suppliedCategories.join(', ') ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
    _rating = s?.rating ?? 5.0;
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taxNumberController.dispose();
    _paymentTermsController.dispose();
    _categoriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final cubit = context.read<SupplierCubit>();
      final categories = _categoriesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (widget.supplier == null) {
        final newSupplier = SupplierModel(
          id: '',
          name: _nameController.text.trim(),
          contactPerson: _contactPersonController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          taxNumber: _taxNumberController.text.trim(),
          paymentTerms: _paymentTermsController.text.trim().isNotEmpty
              ? _paymentTermsController.text.trim()
              : 'Cash',
          suppliedCategories: categories,
          notes: _notesController.text.trim(),
          rating: _rating,
          isActive: _isActive,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await cubit.addSupplier(newSupplier);
      } else {
        final updatedSupplier = widget.supplier!.copyWith(
          name: _nameController.text.trim(),
          contactPerson: _contactPersonController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          taxNumber: _taxNumberController.text.trim(),
          paymentTerms: _paymentTermsController.text.trim().isNotEmpty
              ? _paymentTermsController.text.trim()
              : 'Cash',
          suppliedCategories: categories,
          notes: _notesController.text.trim(),
          rating: _rating,
          isActive: _isActive,
          updatedAt: DateTime.now(),
        );
        await cubit.updateSupplier(updatedSupplier);
      }

      if (mounted) {
        Navigator.pop(context);
        HelperFun.successSnackbar(
          'success'.tr,
          'supplier_saved_success_msg'.tr,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        HelperFun.errorSnackbar(
          title: 'error'.tr,
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isEditing = widget.supplier != null;
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 700 ? 640.0 : width - 32;

    return Dialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        side: BorderSide(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.md - 2,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.cardRadiusLg),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: AppColor.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'edit_supplier'.tr
                              : 'add_new_supplier'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'supplier_form_desc'.tr,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AppColor.textSecondaryDark
                                : AppColor.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Contact Person
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'supplier_name_label'.tr,
                                hintText: 'e.g. Vaporesso Middle East',
                                prefixIcon: const Icon(Icons.storefront_rounded, size: 18),
                                isDense: true,
                              ),
                              validator: (val) => val == null || val.trim().isEmpty
                                  ? 'supplier_name_required'.tr
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _contactPersonController,
                              decoration: InputDecoration(
                                labelText: 'contact_person_label'.tr,
                                hintText: 'e.g. Eng. Amr',
                                prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Phone & Email
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'phone_whatsapp_label'.tr,
                                hintText: 'e.g. 01012345678',
                                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'email_address_label'.tr,
                                hintText: 'vendor@domain.com',
                                prefixIcon: const Icon(Icons.email_outlined, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Address & Tax Number
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'address_warehouse_label'.tr,
                                hintText: 'e.g. Nasr City, Cairo',
                                prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _taxNumberController,
                              decoration: InputDecoration(
                                labelText: 'tax_reg_num_label'.tr,
                                hintText: 'e.g. 583-920-114',
                                prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Payment Terms & Supplied Categories
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _paymentTermsController,
                              decoration: InputDecoration(
                                labelText: 'default_payment_terms_label'.tr,
                                hintText: 'Cash / Net 30 / 50% Advance',
                                prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _categoriesController,
                              decoration: InputDecoration(
                                labelText: 'supplied_categories_label'.tr,
                                hintText: 'Devices, Liquids, Pods',
                                prefixIcon: const Icon(Icons.category_outlined, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Rating & Active Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                          border: Border.all(
                            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'rating_label'.tr,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: List.generate(5, (index) {
                                    final starValue = index + 1.0;
                                    return IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        _rating >= starValue
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: const Color(0xFFF59E0B),
                                        size: 22,
                                      ),
                                      onPressed: () => setState(() => _rating = starValue),
                                    );
                                  }),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  'supplier_status_label'.tr,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: _isActive,
                                  activeThumbColor: AppColor.success,
                                  onChanged: (val) => setState(() => _isActive = val),
                                ),
                                Text(
                                  _isActive
                                      ? 'status_active'.tr
                                      : 'status_inactive'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _isActive ? AppColor.success : AppColor.textSecondaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'notes_remarks_label'.tr,
                          hintText: 'notes_remarks_hint'.tr,
                          prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm + 4,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppSizes.cardRadiusLg),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('cancel'.tr),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 16),
                    label: Text(
                      isEditing
                          ? 'update_supplier_btn'.tr
                          : 'add_supplier_btn'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

