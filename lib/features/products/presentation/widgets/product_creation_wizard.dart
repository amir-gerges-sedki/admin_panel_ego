import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../badges/data/models/badge_model.dart';
import '../../../badges/data/repositories/badge_repository.dart';
import '../../../badges/presentation/cubit/badge_cubit.dart';
import '../../../badges/presentation/cubit/badge_state.dart';
import '../../../badges/presentation/widgets/badge_form_dialog.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/presentation/cubit/category_cubit.dart';
import '../../../categories/presentation/widgets/brand_form_dialog.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_form_cubit.dart';
import 'dynamic_type_forms.dart';
import 'dynamic_variation_matrix_view.dart';
import 'product_type_card.dart';

class ProductCreationWizard extends StatelessWidget {
  final ProductModel? initialProduct;
  final ValueChanged<ProductModel>? onSave;

  const ProductCreationWizard({super.key, this.initialProduct, this.onSave});

  static void show(
    BuildContext context, {
    ProductModel? initialProduct,
    ValueChanged<ProductModel>? onSave,
  }) {
    UnifiedModalSheet.show(
      context: context,
      title: initialProduct == null
          ? 'إضافة صنف جديد (Add Vape Product)'
          : 'تعديل الصنف (Edit Product)',
      subtitle:
          'فلو متكامل واحترافي لاختيار نوع المنتج، المواصفات الديناميكية، ومصفوفة المتغيرات',
      icon: Icons.inventory_2_outlined,
      maxWidth: 900,
      content: MultiBlocProvider(
        providers: [
          BlocProvider<ProductFormCubit>(
            create: (ctx) {
              final ProductRepository repo =
                  sl.isRegistered<ProductRepository>()
                  ? sl<ProductRepository>()
                  : ProductRepositoryImpl();

              final cubit = ProductFormCubit(repo);

              if (initialProduct != null) {
                cubit.initForEditProduct(initialProduct);
              } else {
                cubit.initForNewProduct();
              }
              return cubit;
            },
          ),
          BlocProvider<CategoryCubit>(
            create: (ctx) {
              final cubit = sl.isRegistered<CategoryCubit>()
                  ? sl<CategoryCubit>()
                  : CategoryCubit(
                      sl.isRegistered<CategoryRepository>()
                          ? sl<CategoryRepository>()
                          : CategoryRepositoryImpl(),
                    );
              return cubit..loadData();
            },
          ),
          BlocProvider<BadgeCubit>(
            create: (ctx) {
              final cubit = sl.isRegistered<BadgeCubit>()
                  ? sl<BadgeCubit>()
                  : BadgeCubit(
                      sl.isRegistered<BadgeRepository>()
                          ? sl<BadgeRepository>()
                          : BadgeRepositoryImpl(),
                    );
              return cubit..loadBadges();
            },
          ),
        ],
        child: ProductCreationWizard(
          initialProduct: initialProduct,
          onSave: onSave,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductFormCubit, ProductFormState>(
      listener: (context, state) {
        if (state.isSuccess) {
          final product = context.read<ProductFormCubit>().buildProductModel();
          if (onSave != null) {
            onSave!(product);
          } else {
            // Also notify ProductCubit & CategoryCubit
            context.read<ProductCubit>().loadProducts();
            if (sl.isRegistered<CategoryCubit>()) {
              sl<CategoryCubit>().loadData();
            }
          }
          Navigator.of(context).pop();
          HelperFun.successSnackbar(
            'تم حفظ الصنف بنجاح',
            'تم حفظ "${product.title}" في كتالوج المتجر وقاعدة البيانات.',
          );
        }
        if (state.errorMessage != null) {
          HelperFun.errorSnackbar(
            title: 'خطأ أثناء الحفظ',
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ProductFormCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Folder-like Breadcrumbs Stepper Bar
            _buildStepperHeader(context, state.currentStep, cubit),
            const SizedBox(height: AppSizes.md),

            // 2. Active Step Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildCurrentStepView(context, state, cubit),
            ),
            const SizedBox(height: AppSizes.lg),

            // 3. Navigation Controls Bar
            _buildActionButtons(context, state, cubit),
          ],
        );
      },
    );
  }

  Widget _buildStepperHeader(
    BuildContext context,
    int currentStep,
    ProductFormCubit cubit,
  ) {
    final isDark = HelperFun.isDarkMode(context);

    final steps = [
      {
        'index': 0,
        'title': '١. نوع المنتج',
        'subtitle': 'Category Type',
        'icon': Icons.category_rounded,
      },
      {
        'index': 1,
        'title': '٢. المواصفات الديناميكية',
        'subtitle': 'Dynamic Specs',
        'icon': Icons.tune_rounded,
      },
      {
        'index': 2,
        'title': '٣. مصفوفة المتغيرات',
        'subtitle': 'Variations Matrix',
        'icon': Icons.hub_rounded,
      },
      {
        'index': 3,
        'title': '٤. المراجعة والحفظ',
        'subtitle': 'Review & Save',
        'icon': Icons.check_circle_outline_rounded,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Row(
        children: steps.map((step) {
          final idx = step['index'] as int;
          final isCurrent = idx == currentStep;
          final isPassed = idx < currentStep;

          Color stepColor = isCurrent
              ? AppColor.primary
              : (isPassed
                    ? AppColor.success
                    : (isDark
                          ? AppColor.textMutedDark
                          : AppColor.textMutedLight));

          return Expanded(
            child: InkWell(
              onTap: () {
                // Allow clicking passed steps or current
                if (idx <= currentStep || idx == currentStep + 1) {
                  cubit.setStep(idx);
                }
              },
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColor.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: stepColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPassed
                            ? Icons.check_rounded
                            : (step['icon'] as IconData),
                        size: 14,
                        color: stepColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            step['title'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isCurrent
                                  ? AppColor.primary
                                  : (isDark
                                        ? AppColor.textPrimaryDark
                                        : AppColor.textPrimaryLight),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            step['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColor.textMutedDark
                                  : AppColor.textMutedLight,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStepView(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    switch (state.currentStep) {
      case 0:
        return _buildStep1TypeSelection(context, state, cubit);
      case 1:
        return _buildStep2DynamicForm(context, state, cubit);
      case 2:
        return _buildStep3VariationsMatrix(context, state, cubit);
      case 3:
        return _buildStep4Review(context, state, cubit);
      default:
        return const SizedBox.shrink();
    }
  }

  // ----------------------------------------------------------------------
  // STEP 1: BIG TYPE CARDS SELECTION
  // ----------------------------------------------------------------------
  Widget _buildStep1TypeSelection(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    final isDark = HelperFun.isDarkMode(context);

    return Column(
      key: const ValueKey('step_1_types'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(
              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.touch_app_rounded,
                color: AppColor.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختر نوع المنتج للبدء (Select Vape Product Category)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColor.textPrimaryDark
                            : AppColor.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'سيتم تخصيص شاشة المواصفات ومصفوفة المتغيرات بدقة وفقاً لنوع المنتج لتجنب أي حقول غير ضرورية',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),

        // Grid of 4 Core Product Types (2x2 Balanced Layout)
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSizes.md,
              mainAxisSpacing: AppSizes.md,
              childAspectRatio: constraints.maxWidth > 600 ? 1.6 : 1.35,
              children: ProductCategoryType.visibleTypes.map((type) {
                return ProductTypeCard(
                  type: type,
                  isSelected: state.categoryType == type,
                  onSelect: () => cubit.selectCategoryType(type),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // STEP 2: DYNAMIC FORM FIELDS & CORE DETAILS
  // ----------------------------------------------------------------------
  Widget _buildStep2DynamicForm(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<CategoryCubit, CategoryState>(
      key: const ValueKey('step_2_specs'),
      builder: (context, catState) {
        final List<String> brandsList = [];

        if (catState is CategoryLoaded) {
          for (final b in catState.brands) {
            final name = b.name.trim();
            if (name.isNotEmpty && !brandsList.contains(name)) {
              brandsList.add(name);
            }
          }
        }
        if (catState is CategoryInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<CategoryCubit>().loadData();
          });
        }

        if (state.brandName.isEmpty && brandsList.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cubit.updateBasicInfo(brandName: brandsList.first);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Type indicator & change button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: state.categoryType.accentColor.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        state.categoryType.icon,
                        color: state.categoryType.accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المواصفات الأساسية للصنف: ${state.categoryType.arabicName}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColor.textPrimaryDark
                                : AppColor.textPrimaryLight,
                          ),
                        ),
                        Text(
                          state.categoryType.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColor.textMutedDark
                                : AppColor.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => cubit.setStep(0),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text(
                    'تغيير نوع المنتج',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Product Classification / Title & Brand Row
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: state.categoryType == ProductCategoryType.liquid
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColor.darkSubCard
                                : AppColor.lightSubCard,
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadiusSm,
                            ),
                            border: Border.all(
                              color: const Color(
                                0xFF0EA5E9,
                              ).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.water_drop_rounded,
                                size: 18,
                                color: Color(0xFF0EA5E9),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'نوع الليكويد:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              ChoiceChip(
                                avatar: const Text(
                                  '🇪🇬',
                                  style: TextStyle(fontSize: 12),
                                ),
                                label: const Text(
                                  'Local Liquid',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                                selected: state.liquidOrigin == 'Local',
                                selectedColor: const Color(
                                  0xFF0EA5E9,
                                ).withValues(alpha: 0.25),
                                onSelected: (selected) {
                                  if (selected) cubit.setLiquidOrigin('Local');
                                },
                              ),
                              const SizedBox(width: 6),
                              ChoiceChip(
                                avatar: const Text(
                                  '🌍',
                                  style: TextStyle(fontSize: 12),
                                ),
                                label: const Text(
                                  'Premium Liquid',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                                selected: state.liquidOrigin == 'Premium',
                                selectedColor: const Color(
                                  0xFF0EA5E9,
                                ).withValues(alpha: 0.25),
                                onSelected: (selected) {
                                  if (selected) cubit.setLiquidOrigin('Premium');
                                },
                              ),
                            ],
                          ),
                        )
                      : TextFormField(
                          initialValue: state.title,
                          decoration: const InputDecoration(
                            labelText: 'اسم الصنف / العنوان *',
                            hintText: 'e.g. Pod Kit / Box Mod / Coil',
                            prefixIcon: Icon(
                              Icons.label_outline_rounded,
                              size: 18,
                            ),
                          ),
                          onChanged: (v) => cubit.updateBasicInfo(title: v),
                        ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      Expanded(
                        child: catState is CategoryLoading
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.borderRadiusSm,
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColor.darkBorder
                                        : AppColor.lightBorder,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'جاري جلب قائمة الماركات...',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              )
                            : (brandsList.isEmpty
                                  ? TextFormField(
                                      initialValue: state.brandName,
                                      decoration: const InputDecoration(
                                        labelText: 'الماركة المصنعة (Brand) *',
                                        hintText: 'اكتب اسم الماركة...',
                                        prefixIcon: Icon(
                                          Icons.business_rounded,
                                          size: 18,
                                        ),
                                      ),
                                      onChanged: (val) =>
                                          cubit.updateBasicInfo(brandName: val),
                                    )
                                  : DropdownButtonFormField<String>(
                                      initialValue:
                                          brandsList.contains(state.brandName)
                                          ? state.brandName
                                          : brandsList.first,
                                      decoration: const InputDecoration(
                                        labelText: 'الماركة المصنعة (Brand) *',
                                        prefixIcon: Icon(
                                          Icons.business_rounded,
                                          size: 18,
                                        ),
                                      ),
                                      items: brandsList
                                          .map(
                                            (b) => DropdownMenuItem(
                                              value: b,
                                              child: Text(
                                                b,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          cubit.updateBasicInfo(brandName: val);
                                        }
                                      },
                                    )),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.add_business_rounded,
                          size: 22,
                          color: AppColor.primary,
                        ),
                        tooltip: 'إضافة ماركة جديدة إلى فايربيس (Add Brand)',
                        onPressed: () {
                          BrandFormDialog.show(
                            context,
                            onSave: (brand) {
                              context.read<CategoryCubit>().addBrand(brand);
                              cubit.updateBasicInfo(brandName: brand.name);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Description
            TextFormField(
              initialValue: state.description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'وصف المنتج ومميزاته (Description)',
                hintText: 'اكتب مواصفات وتفاصيل الفيب ومحتويات العلبة...',
                prefixIcon: Icon(Icons.notes_rounded, size: 18),
              ),
              onChanged: (v) => cubit.updateBasicInfo(description: v),
            ),
            const SizedBox(height: AppSizes.md),

            // Base Price & Sale Price & Base Stock & SKU Prefix
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: state.basePrice.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر الأساسي (ج.م) *',
                      prefixIcon: Icon(
                        Icons.monetization_on_outlined,
                        size: 18,
                      ),
                    ),
                    onChanged: (v) {
                      final p = double.tryParse(v) ?? 0.0;
                      cubit.updateBasicInfo(basePrice: p);
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: TextFormField(
                    initialValue: state.salePrice.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'سعر العرض (ج.م)',
                      prefixIcon: Icon(Icons.discount_outlined, size: 18),
                    ),
                    onChanged: (v) {
                      final p = double.tryParse(v) ?? 0.0;
                      cubit.updateBasicInfo(salePrice: p);
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: TextFormField(
                    initialValue: state.baseStock.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المخزون الافتراضي *',
                      prefixIcon: Icon(Icons.inventory_rounded, size: 18),
                    ),
                    onChanged: (v) {
                      final s = int.tryParse(v) ?? 0;
                      cubit.updateBasicInfo(baseStock: s);
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: TextFormField(
                    initialValue: state.baseSku,
                    decoration: const InputDecoration(
                      labelText: 'بادئة الـ SKU *',
                      prefixIcon: Icon(Icons.qr_code_rounded, size: 18),
                    ),
                    onChanged: (v) => cubit.updateBasicInfo(baseSku: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Visual Thumbnail & Main Image Card
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Live Image Preview box
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark ? AppColor.darkCard : AppColor.lightCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: state.thumbnail.isNotEmpty
                        ? Image.network(
                            state.thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image_rounded, size: 24, color: AppColor.error),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_outlined, size: 28, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          key: ValueKey('thumb_${state.thumbnail}'),
                          initialValue: state.thumbnail,
                          decoration: const InputDecoration(
                            labelText: 'رابط صورة المنتج الرئيسية (Thumbnail Image URL)',
                            hintText: 'https://example.com/image.jpg',
                            prefixIcon: Icon(Icons.link_rounded, size: 18),
                            isDense: true,
                          ),
                          onChanged: (v) => cubit.updateBasicInfo(thumbnail: v.trim()),
                        ),
                        if (state.variations.any((v) => v.image.isNotEmpty)) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'اختر من صور المتغيرات:',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              ...state.variations
                                  .where((v) => v.image.isNotEmpty)
                                  .map((v) => InkWell(
                                        onTap: () => cubit.setThumbnail(v.image),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColor.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: AppColor.primary.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            v.sku,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColor.primary,
                                            ),
                                          ),
                                        ),
                                      )),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Featured Switch
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: SwitchListTile(
                title: const Text(
                  'منتج مميز بالرئيسية (Featured on Homepage)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'إبراز المنتج في قسم العروض والمنتجات المميزة بالصفحة الرئيسية',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                value: state.isFeatured,
                activeThumbColor: AppColor.primary,
                onChanged: (v) => cubit.updateBasicInfo(isFeatured: v),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // HOMEPAGE BADGE SECTION (هوم بيج باتش)
            _buildHomepageBadgeSection(context, state, cubit, isDark),

            const SizedBox(height: AppSizes.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.lg),

            // Dynamic Form Section tailored to the product type
            const DynamicTypeFormSection(),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------------------------
  // HOMEPAGE BADGE SECTION (هوم بيج باتش)
  // ----------------------------------------------------------------------
  Widget _buildHomepageBadgeSection(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: state.isBadgeEnabled
              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          width: state.isBadgeEnabled ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Icon and Toggle Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'هوم بيج باتش (Homepage Badge)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColor.textPrimaryDark
                              : AppColor.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'تفعيل شارة ترويجية (مثل: SALE / NEW / POPULAR) تظهر على كارت المنتج بالصفحة الرئيسية',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColor.textSecondaryDark
                              : AppColor.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: state.isBadgeEnabled,
                activeThumbColor: const Color(0xFFF59E0B),
                onChanged: (v) => cubit.setBadgeEnabled(v),
              ),
            ],
          ),

          if (state.isBadgeEnabled) ...[
            const SizedBox(height: AppSizes.md),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.md),

            // Dynamic Firebase Badge selector (Clean text: SALE, NEW, POPULAR)
            BlocBuilder<BadgeCubit, BadgeState>(
              builder: (context, badgeState) {
                if (badgeState is BadgeLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final badges = badgeState is BadgeLoaded
                    ? badgeState.badges
                    : <BadgeModel>[];

                if (badges.isEmpty) {
                  final defaultOptions = [
                    'SALE',
                    'NEW',
                    'POPULAR',
                    'HOT DEAL',
                    'LIMITED',
                  ];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اختر نوع الباتش (أو أضف نوعاً جديداً في فايربيس):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: defaultOptions.map((opt) {
                          final isSelected = state.badgeId.toUpperCase() == opt;
                          return ChoiceChip(
                            label: Text(
                              opt,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected ? Colors.white : null,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFFF59E0B),
                            onSelected: (selected) {
                              if (selected) {
                                cubit.setBadgeId(opt);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          BadgeFormDialog.show(
                            context,
                            onSave: (b) {
                              context.read<BadgeCubit>().addBadge(b);
                              cubit.setBadgeId(b.name);
                            },
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('إضافة نوع باتش مخصص إلى فايربيس'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFF59E0B),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  );
                }

                if (state.badgeId.isEmpty && badges.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    cubit.setBadgeId(badges.first.name);
                  });
                }

                final selectedValue =
                    badges.any(
                      (b) =>
                          b.name.toUpperCase() == state.badgeId.toUpperCase() ||
                          b.id == state.badgeId,
                    )
                    ? (badges
                          .firstWhere(
                            (b) =>
                                b.name.toUpperCase() ==
                                    state.badgeId.toUpperCase() ||
                                b.id == state.badgeId,
                          )
                          .name)
                    : (badges.isNotEmpty ? badges.first.name : null);

                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedValue,
                        decoration: const InputDecoration(
                          labelText:
                              'نوع الباتش (Badge Type: SALE, NEW, POPULAR...) *',
                          prefixIcon: Icon(Icons.stars_rounded, size: 18),
                        ),
                        items: badges.map((b) {
                          return DropdownMenuItem<String>(
                            value: b.name,
                            child: Text(
                              b.nameAr.isNotEmpty
                                  ? '${b.name} (${b.nameAr})'
                                  : b.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            cubit.setBadgeId(val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 24,
                        color: Color(0xFFF59E0B),
                      ),
                      tooltip: 'إضافة نوع باتش جديد إلى فايربيس',
                      onPressed: () {
                        BadgeFormDialog.show(
                          context,
                          onSave: (b) {
                            context.read<BadgeCubit>().addBadge(b);
                            cubit.setBadgeId(b.name);
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // STEP 3: DYNAMIC VARIATIONS MATRIX
  // ----------------------------------------------------------------------
  Widget _buildStep3VariationsMatrix(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    return const DynamicVariationMatrixView(key: ValueKey('step_3_matrix'));
  }

  // ----------------------------------------------------------------------
  // STEP 4: REVIEW & CONFIRMATION
  // ----------------------------------------------------------------------
  Widget _buildStep4Review(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    final isDark = HelperFun.isDarkMode(context);
    final color = state.categoryType.accentColor;

    return Container(
      key: const ValueKey('step_4_review'),
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  state.thumbnail,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 80,
                    height: 80,
                    color: isDark
                        ? AppColor.darkSubCard
                        : AppColor.lightSubCard,
                    child: Icon(
                      state.categoryType.icon,
                      size: 36,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${state.categoryType.arabicName} | ${state.brandName}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        if (state.isBadgeEnabled &&
                            state.badgeId.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          BlocBuilder<BadgeCubit, BadgeState>(
                            builder: (context, bState) {
                              final badges = bState is BadgeLoaded
                                  ? bState.badges
                                  : <BadgeModel>[];
                              final b = badges.firstWhere(
                                (e) => e.id == state.badgeId,
                                orElse: () => BadgeModel(
                                  id: state.badgeId,
                                  name: state.badgeId,
                                ),
                              );
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  '⭐ ${b.name}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.title.isNotEmpty
                          ? state.title
                          : '${state.brandName} ${state.categoryType.displayName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.description.isNotEmpty
                          ? state.description
                          : 'No description provided',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.md),

          // Summary Metrics Row
          Row(
            children: [
              _buildReviewMetricCard(
                context,
                title: 'السعر الأساسي',
                value: AppFormatters.formatEGP(state.basePrice),
                icon: Icons.attach_money_rounded,
                color: AppColor.primary,
              ),
              const SizedBox(width: AppSizes.sm),
              _buildReviewMetricCard(
                context,
                title: 'سعر العرض',
                value: AppFormatters.formatEGP(state.salePrice),
                icon: Icons.local_offer_outlined,
                color: AppColor.success,
              ),
              const SizedBox(width: AppSizes.sm),
              _buildReviewMetricCard(
                context,
                title: 'إجمالي المتغيرات',
                value: '${state.variations.length} SKUs',
                icon: Icons.hub_rounded,
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: AppSizes.sm),
              _buildReviewMetricCard(
                context,
                title: 'المخزون الإجمالي',
                value: state.variations.isNotEmpty
                    ? '${state.variations.fold(0, (s, v) => s + v.stock)} قطعة'
                    : '${state.baseStock} قطعة',
                icon: Icons.inventory_2_rounded,
                color: AppColor.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          // Target Firestore Collection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              border: Border.all(
                color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.cloud_done_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                SizedBox(width: 8),
                Text(
                  'سيتم حفظ هذا الصنف في مسار Cloud Firestore: /Products/{id}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = HelperFun.isDarkMode(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.sm + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // ACTION BUTTONS
  // ----------------------------------------------------------------------
  Widget _buildActionButtons(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    final isFirstStep = state.currentStep == 0;
    final isLastStep = state.currentStep == 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isFirstStep)
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء (Cancel)'),
          )
        else
          OutlinedButton.icon(
            onPressed: () => cubit.prevStep(),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('السابق (Back)'),
          ),
        Row(
          children: [
            if (!isLastStep) ...[
              ElevatedButton.icon(
                onPressed: () {
                  // If moving from Step 2 to Step 3, automatically generate variations if empty
                  if (state.currentStep == 1 && state.variations.isEmpty) {
                    cubit.generateDynamicVariations();
                  }
                  cubit.nextStep();
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('التالي (Next)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: 12,
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: state.isSubmitting
                    ? null
                    : () => cubit.saveProduct(),
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 18),
                label: Text(
                  state.isSubmitting
                      ? 'جاري الحفظ...'
                      : 'حفظ ونشر المنتج (Save Product)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xl,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
