import '../../../../core/localization/app_localizations.dart';
import '../../../badges/presentation/widgets/badges_management_dialog.dart';
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
import '../../../brands/data/repositories/brand_repository.dart';
import '../../../brands/presentation/cubit/brand_cubit.dart';
import '../../../brands/presentation/widgets/brand_form_dialog.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../domain/variation_matrix_engine.dart';
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Harvest existing catalog flavors from ProductCubit if available
    try {
      final productCubit = context.read<ProductCubit>();
      if (productCubit.state is ProductLoaded) {
        final loaded = productCubit.state as ProductLoaded;
        GlobalFlavorsPool.harvestFromProducts(loaded.products);
        GlobalDeviceSpecsPool.harvestFromProducts(loaded.products);
        GlobalDisposableSpecsPool.harvestFromProducts(loaded.products);
      }
    } catch (_) {}
    UnifiedModalSheet.show(
      context: context,
      title: initialProduct == null
          ? (isArabic ? 'إضافة صنف جديد' : 'Add New Product')
          : (isArabic ? 'تعديل الصنف' : 'Edit Product'),
      subtitle: isArabic
          ? 'معالج متكامل لاختيار نوع المنتج، المواصفات الديناميكية، ومصفوفة المتغيرات'
          : 'Streamlined wizard for product category, dynamic specs, and variations matrix',
      icon: Icons.inventory_2_outlined,
      maxWidth: 1020,
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
          BlocProvider<BrandCubit>(
            create: (ctx) {
              final cubit = sl.isRegistered<BrandCubit>()
                  ? sl<BrandCubit>()
                  : BrandCubit(
                      sl.isRegistered<BrandRepository>()
                          ? sl<BrandRepository>()
                          : BrandRepositoryImpl(),
                    );
              return cubit..loadBrands();
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
            // Also notify ProductCubit & BrandCubit
            context.read<ProductCubit>().loadProducts();
            if (sl.isRegistered<BrandCubit>()) {
              sl<BrandCubit>().loadBrands();
            }
          }
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          HelperFun.successSnackbar(
            'تم حفظ الصنف بنجاح',
            'تم حفظ "${product.displayTitle}" في كتالوج المتجر وقاعدة البيانات.',
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
            _buildCurrentStepView(context, state, cubit),
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final steps = [
      {
        'index': 0,
        'title': isArabic ? '١. نوع المنتج' : '1. Product Type',
        'subtitle': isArabic ? 'التصنيف الرئيسي' : 'Category Type',
        'icon': Icons.category_rounded,
      },
      {
        'index': 1,
        'title': isArabic ? '٢. المواصفات الديناميكية' : '2. Dynamic Specs',
        'subtitle': isArabic ? 'الخصائص والمواصفات' : 'Attributes & Specs',
        'icon': Icons.tune_rounded,
      },
      {
        'index': 2,
        'title': isArabic ? '٣. مصفوفة المتغيرات' : '3. Variations Matrix',
        'subtitle': isArabic ? 'الأسعار والمخزون' : 'Pricing & Inventory',
        'icon': Icons.hub_rounded,
      },
      {
        'index': 3,
        'title': isArabic ? '٤. المراجعة والحفظ' : '4. Review & Save',
        'subtitle': isArabic ? 'المعاينة والاعتماد' : 'Review & Confirm',
        'icon': Icons.check_circle_outline_rounded,
      },
    ];

    final progressValue = (currentStep + 1) / steps.length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Sleek Progress Line
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 3,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColor.primary),
            ),
          ),
          const SizedBox(height: 8),

          // Stepper Items
          Row(
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColor.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadiusSm,
                      ),
                      border: isCurrent
                          ? Border.all(
                              color: AppColor.primary.withValues(alpha: 0.35),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? AppColor.primary
                                : (isPassed
                                      ? AppColor.success.withValues(alpha: 0.2)
                                      : (isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.05))),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppColor.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: isPassed
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: AppColor.success,
                                  )
                                : (isCurrent
                                      ? Text(
                                          '${idx + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        )
                                      : Icon(
                                          step['icon'] as IconData,
                                          size: 13,
                                          color: stepColor,
                                        )),
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
                                      ? FontWeight.w800
                                      : (isPassed
                                            ? FontWeight.w700
                                            : FontWeight.w600),
                                  color: isCurrent
                                      ? AppColor.primary
                                      : (isPassed
                                            ? (isDark
                                                  ? Colors.white
                                                  : Colors.black87)
                                            : (isDark
                                                  ? AppColor.textMutedDark
                                                  : AppColor.textMutedLight)),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                step['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 9.5,
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
        ],
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
                      isArabic
                          ? 'اختر نوع المنتج للبدء'
                          : 'Select Product Category to Begin',
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
                      isArabic
                          ? 'سيتم تخصيص شاشة المواصفات ومصفوفة المتغيرات بدقة وفقاً لنوع المنتج لتجنب أي حقول غير ضرورية'
                          : 'Specifications and variations matrix will adapt precisely to the selected product type.',
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

        // Grid of 4 Core Product Types (Compact & responsive layout)
        LayoutBuilder(
          builder: (context, constraints) {
            final int crossAxisCount;
            final double childAspectRatio;

            if (constraints.maxWidth > 860) {
              crossAxisCount = 4;
              childAspectRatio = 2.4;
            } else if (constraints.maxWidth > 520) {
              crossAxisCount = 2;
              childAspectRatio = 3.2;
            } else {
              crossAxisCount = 1;
              childAspectRatio = 4.0;
            }

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSizes.sm + 4,
              mainAxisSpacing: AppSizes.sm + 4,
              childAspectRatio: childAspectRatio,
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<BrandCubit, BrandState>(
      key: const ValueKey('step_2_specs'),
      builder: (context, brandState) {
        final List<String> brandsList = [];

        if (brandState is BrandLoaded) {
          for (final b in brandState.brands) {
            final name = b.name.trim();
            if (name.isNotEmpty && !brandsList.contains(name)) {
              brandsList.add(name);
            }
          }
        }
        if (brandState is BrandInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<BrandCubit>().loadBrands();
          });
        }

        if (state.brandName.isEmpty && brandsList.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final firstBrand = (brandState is BrandLoaded && brandState.brands.isNotEmpty)
                ? brandState.brands.first
                : null;
            cubit.updateBasicInfo(
              brandId: firstBrand?.id ?? '',
              brandName: firstBrand?.name ?? brandsList.first,
            );
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Category Indicator & Quick Change Button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm + 2,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    state.categoryType.accentColor.withValues(
                      alpha: isDark ? 0.16 : 0.08,
                    ),
                    state.categoryType.accentColor.withValues(
                      alpha: isDark ? 0.04 : 0.01,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: state.categoryType.accentColor.withValues(alpha: 0.25),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 560;

                  final infoWidget = Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: state.categoryType.accentColor.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: state.categoryType.accentColor.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Icon(
                          state.categoryType.icon,
                          color: state.categoryType.accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    isArabic
                                        ? 'المواصفات الأساسية للصنف: ${state.categoryType.arabicName}'
                                        : 'Core Specs: ${state.categoryType.displayName}',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppColor.textPrimaryDark
                                          : AppColor.textPrimaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: state.categoryType.accentColor
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    state.categoryType.displayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: state.categoryType.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.categoryType.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColor.textMutedDark
                                    : AppColor.textMutedLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final actionButton = OutlinedButton.icon(
                    onPressed: () => cubit.setStep(0),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: Text(
                      isArabic ? 'تغيير نوع المنتج' : 'Change Product Type',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: state.categoryType.accentColor,
                      side: BorderSide(
                        color: state.categoryType.accentColor.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        infoWidget,
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: actionButton,
                        ),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: infoWidget),
                      const SizedBox(width: 12),
                      actionButton,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // CARD 1: IDENTITY & BRAND
            _buildIdentityCard(
              context,
              state,
              cubit,
              isDark,
              brandState,
              brandsList,
            ),
            const SizedBox(height: AppSizes.md),

            // CARD 2: MEDIA & LIVE THUMBNAIL
            _buildMediaCard(context, state, cubit, isDark),
            const SizedBox(height: AppSizes.md),

            // CARD 3: MARKETING & HOMEPAGE PROMO BADGES
            _buildMarketingCard(context, state, cubit, isDark),
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
  // HELPER WIDGETS
  // ----------------------------------------------------------------------
  Widget _buildWizardOriginButton({
    required BuildContext context,
    required String title,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = HelperFun.isDarkMode(context);
    const activeColor = Color(0xFF0EA5E9);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 13,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.25)),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // CARD 1: IDENTITY & BRAND
  // ----------------------------------------------------------------------
  Widget _buildIdentityCard(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
    bool isDark,
    BrandState brandState,
    List<String> brandsList,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: isArabic ? 'هوية الصنف والماركة المصنعة' : 'Product Identity & Brand',
            icon: Icons.badge_outlined,
            color: AppColor.primary,
          ),
          const SizedBox(height: AppSizes.md),

          // Title & Brand Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 620;

              final titleWidget = state.categoryType == ProductCategoryType.liquid
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.darkCard : AppColor.lightCard,
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadiusSm,
                        ),
                        border: Border.all(
                          color: const Color(0xFF0EA5E9).withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, originConstraints) {
                          final isNarrow = originConstraints.maxWidth < 410;

                          final label = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.water_drop_rounded,
                                size: 18,
                                color: Color(0xFF0EA5E9),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? 'مصدر الليكويد:' : 'Liquid Origin:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );

                          final buttons = Row(
                            mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                            children: [
                              isNarrow
                                  ? Expanded(
                                      child: _buildWizardOriginButton(
                                        context: context,
                                        title: isArabic ? 'سائل محلي' : 'Local Liquid',
                                        emoji: '🇪🇬',
                                        isSelected: state.liquidOrigin == 'Local',
                                        onTap: () => cubit.setLiquidOrigin('Local'),
                                      ),
                                    )
                                  : _buildWizardOriginButton(
                                      context: context,
                                      title: isArabic ? 'سائل محلي' : 'Local Liquid',
                                      emoji: '🇪🇬',
                                      isSelected: state.liquidOrigin == 'Local',
                                      onTap: () => cubit.setLiquidOrigin('Local'),
                                    ),
                              const SizedBox(width: 6),
                              isNarrow
                                  ? Expanded(
                                      child: _buildWizardOriginButton(
                                        context: context,
                                        title: isArabic ? 'مستورد بريميوم' : 'Premium Liquid',
                                        emoji: '🌍',
                                        isSelected: state.liquidOrigin == 'Premium',
                                        onTap: () => cubit.setLiquidOrigin('Premium'),
                                      ),
                                    )
                                  : _buildWizardOriginButton(
                                      context: context,
                                      title: isArabic ? 'مستورد بريميوم' : 'Premium Liquid',
                                      emoji: '🌍',
                                      isSelected: state.liquidOrigin == 'Premium',
                                      onTap: () => cubit.setLiquidOrigin('Premium'),
                                    ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                label,
                                const SizedBox(height: 6),
                                buttons,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              label,
                              const Spacer(),
                              buttons,
                            ],
                          );
                        },
                      ),
                    )
                  : state.categoryType == ProductCategoryType.disposable
                      ? Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? AppColor.darkCard : AppColor.lightCard,
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadiusSm,
                            ),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cloud_queue_rounded,
                                size: 20,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isArabic
                                          ? 'سحبة جاهزة (Disposable Vape)'
                                          : 'Disposable Vape',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      isArabic
                                          ? 'يُحدد الاسم تلقائياً في المتجر من النكهة والماركة'
                                          : 'Title auto-resolved from Flavor & Brand in storefront',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark
                                            ? AppColor.textSecondaryDark
                                            : AppColor.textSecondaryLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextFormField(
                          initialValue: state.title,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'اسم الصنف / العنوان *' : 'Product Title *',
                            hintText: isArabic ? 'مثال: Pod Kit / Box Mod / Coil' : 'e.g. Pod Kit / Box Mod / Coil',
                            prefixIcon: const Icon(
                              Icons.label_outline_rounded,
                              size: 18,
                            ),
                          ),
                          onChanged: (v) => cubit.updateBasicInfo(title: v),
                        );

              final brandWidget = Row(
                children: [
                  Expanded(
                    child: brandState is BrandLoading
                        ? Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColor.darkCard
                                  : AppColor.lightCard,
                              borderRadius: BorderRadius.circular(
                                AppSizes.borderRadiusSm,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppColor.darkBorder
                                    : AppColor.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isArabic ? 'جاري جلب قائمة الماركات...' : 'Loading brands...',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : (brandsList.isEmpty
                              ? TextFormField(
                                  initialValue: state.brandName,
                                  decoration: InputDecoration(
                                    labelText: isArabic ? 'الماركة المصنعة *' : 'Brand Name *',
                                    hintText: isArabic ? 'اكتب اسم الماركة...' : 'Enter brand name...',
                                    prefixIcon: const Icon(
                                      Icons.business_rounded,
                                      size: 18,
                                    ),
                                  ),
                                  onChanged: (val) =>
                                      cubit.updateBasicInfo(brandName: val),
                                )
                              : DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue:
                                      brandsList.contains(state.brandName)
                                      ? state.brandName
                                      : brandsList.first,
                                  decoration: InputDecoration(
                                    labelText: isArabic ? 'الماركة المصنعة *' : 'Brand Name *',
                                    prefixIcon: const Icon(
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
                                      final matched =
                                          (brandState is BrandLoaded)
                                          ? brandState.brands
                                              .where((b) => b.name == val)
                                              .firstOrNull
                                          : null;
                                      cubit.updateBasicInfo(
                                        brandId: matched?.id ?? '',
                                        brandName: val,
                                      );
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
                    tooltip: isArabic ? 'إضافة ماركة جديدة' : 'Add New Brand',
                    onPressed: () {
                      BrandFormDialog.show(
                        context,
                        onSave: (brand) {
                          context.read<BrandCubit>().addBrand(brand);
                          cubit.updateBasicInfo(
                            brandId: brand.id,
                            brandName: brand.name,
                          );
                        },
                      );
                    },
                  ),
                ],
              );

              if (isStacked) {
                return Column(
                  children: [
                    titleWidget,
                    const SizedBox(height: AppSizes.md),
                    brandWidget,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 6, child: titleWidget),
                  const SizedBox(width: AppSizes.md),
                  Expanded(flex: 4, child: brandWidget),
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.md),

          // Description
          TextFormField(
            initialValue: state.description,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: isArabic ? 'وصف المنتج ومميزاته' : 'Product Description',
              hintText: isArabic
                  ? 'اكتب مواصفات وتفاصيل الفيب ومحتويات العلبة...'
                  : 'Enter vape specifications, details, and box contents...',
              prefixIcon: const Icon(Icons.notes_rounded, size: 18),
            ),
            onChanged: (v) => cubit.updateBasicInfo(description: v),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // CARD 2: MEDIA & LIVE THUMBNAIL
  // ----------------------------------------------------------------------
  Widget _buildMediaCard(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
    bool isDark,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: isArabic ? 'الصورة الرئيسية للمنتج' : 'Main Product Image',
            icon: Icons.image_outlined,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(height: AppSizes.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Live Image Preview box with subtle elevation
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkCard : AppColor.lightCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: state.thumbnail.isNotEmpty
                        ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                        : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                    width: state.thumbnail.isNotEmpty ? 1.5 : 1,
                  ),
                  boxShadow: state.thumbnail.isNotEmpty
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                clipBehavior: Clip.antiAlias,
                child: state.thumbnail.isNotEmpty
                    ? Image.network(
                        state.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                size: 24,
                                color: AppColor.error,
                              ),
                            ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 28,
                          color: Colors.grey,
                        ),
                      ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      key: ValueKey('thumb_${state.thumbnail.isEmpty ? "empty" : "filled"}'),
                      initialValue: state.thumbnail,
                      decoration: InputDecoration(
                        labelText: isArabic
                            ? 'رابط صورة المنتج الرئيسية'
                            : 'Main Product Image URL',
                        hintText: 'https://example.com/image.jpg',
                        prefixIcon: const Icon(Icons.link_rounded, size: 18),
                        suffixIcon: state.thumbnail.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  size: 16,
                                ),
                                tooltip: isArabic ? 'مسح الرابط' : 'Clear URL',
                                onPressed: () =>
                                    cubit.updateBasicInfo(thumbnail: ''),
                              )
                            : null,
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          cubit.updateBasicInfo(thumbnail: v.trim()),
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
                              .map(
                                (v) => InkWell(
                                  onTap: () => cubit.setThumbnail(v.image),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColor.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColor.primary.withValues(
                                          alpha: 0.3,
                                        ),
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
                                ),
                              ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // CARD 3: MARKETING & HOMEPAGE BADGES
  // ----------------------------------------------------------------------
  Widget _buildMarketingCard(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
    bool isDark,
  ) {
    return _buildHomepageBadgeSection(context, state, cubit, isDark);
  }

  Widget _buildCardHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // HOMEPAGE BADGE SECTION (شارة الصفحة الرئيسية)
  // ----------------------------------------------------------------------
  Widget _buildHomepageBadgeSection(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
    bool isDark,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
              Expanded(
                child: Row(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'شارة الصفحة الرئيسية' : 'Homepage Badge',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColor.textPrimaryDark
                                  : AppColor.textPrimaryLight,
                            ),
                          ),
                          Text(
                            isArabic
                                ? 'تفعيل شارة ترويجية (مثل: SALE / NEW / HOT DEAL) لعرض الصنف وتمييزه بالصفحة الرئيسية'
                                : 'Enable promotional badge (e.g. SALE / NEW / HOT DEAL) to feature product on homepage',
                            style: TextStyle(
                              fontSize: 11,
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
              ),
              const SizedBox(width: 8),
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

            // Live Badge Preview
            if (state.badgeId.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'معاينة شارة المتجر: ${state.badgeId}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
            ],

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
                        isExpanded: true,
                        initialValue: selectedValue,
                        decoration: InputDecoration(
                          labelText: isArabic
                              ? 'نوع الشارة (SALE, NEW, POPULAR...) *'
                              : 'Badge Type (SALE, NEW, POPULAR...) *',
                          prefixIcon: const Icon(Icons.stars_rounded, size: 18),
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
                              overflow: TextOverflow.ellipsis,
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
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        size: 22,
                        color: Color(0xFFF59E0B),
                      ),
                      tooltip: 'manage_badges'.tr,
                      onPressed: () => BadgesManagementDialog.show(context),
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
  // STEP 4: REVIEW & CONFIRMATION (WITH REALISTIC STOREFRONT PREVIEW)
  // ----------------------------------------------------------------------
  Widget _buildStep4Review(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    final isDark = HelperFun.isDarkMode(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final color = state.categoryType.accentColor;

    // Resolve effective lowest price for Storefront card and metrics preview
    double resolvedPrice = state.basePrice;
    double resolvedSalePrice = state.salePrice;
    if (state.variations.isNotEmpty) {
      final pricedVars = state.variations
          .where((v) => v.price > 0 || v.salePrice > 0)
          .toList();
      final pool = pricedVars.isNotEmpty ? pricedVars : state.variations;
      ProductVariationModel lowestVar = pool.first;
      double lowestEffective = VariationMatrixEngine.effectivePrice(lowestVar);
      for (final v in pool) {
        final eff = VariationMatrixEngine.effectivePrice(v);
        if (eff > 0 && (lowestEffective == 0 || eff < lowestEffective)) {
          lowestEffective = eff;
          lowestVar = v;
        }
      }
      if (lowestVar.salePrice > 0 && lowestVar.salePrice < lowestVar.price) {
        resolvedPrice = lowestVar.price;
        resolvedSalePrice = lowestVar.salePrice;
      } else {
        resolvedPrice = lowestVar.price > 0 ? lowestVar.price : lowestVar.salePrice;
        resolvedSalePrice = 0.0;
      }
    }

    final hasDiscount = resolvedPrice > 0 &&
        resolvedSalePrice > 0 &&
        resolvedSalePrice < resolvedPrice;
    final discountPercent = hasDiscount
        ? ((resolvedPrice - resolvedSalePrice) / resolvedPrice * 100).round()
        : 0;
    final totalUnits = state.variations.isNotEmpty
        ? state.variations.fold(0, (s, v) => s + v.stock)
        : state.baseStock;
    final totalInventoryValue = state.variations.isNotEmpty
        ? state.variations.fold<double>(
            0.0,
            (s, v) => s + ((v.salePrice > 0 ? v.salePrice : v.price) * v.stock),
          )
        : (resolvedSalePrice > 0 ? resolvedSalePrice : resolvedPrice) *
              totalUnits;
    final totalInventoryCost = state.variations.isNotEmpty
        ? state.variations.fold<double>(
            0.0,
            (s, v) => s + (v.costPrice * v.stock),
          )
        : state.baseCostPrice * totalUnits;
    final totalInventoryProfit = totalInventoryValue - totalInventoryCost;
    final totalProfitMargin = totalInventoryValue > 0
        ? (totalInventoryProfit / totalInventoryValue * 100)
        : 0.0;

    return Column(
      key: const ValueKey('step_4_review'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Storefront Customer Preview Card
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkCard : AppColor.lightCard,
            borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 16,
                          color: AppColor.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'معاينة كارت المتجر للعملاء'
                                : 'Customer Storefront Card Preview',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColor.textSecondaryDark
                                  : AppColor.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isArabic ? 'معاينة حية' : 'Live Preview',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColor.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // Mock Card Body
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image with Promo Badge Overlay
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: state.thumbnail.isNotEmpty
                            ? Image.network(
                                state.thumbnail,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 100,
                                  height: 100,
                                  color: isDark
                                      ? AppColor.darkSubCard
                                      : AppColor.lightSubCard,
                                  child: Icon(
                                    state.categoryType.icon,
                                    size: 40,
                                    color: color,
                                  ),
                                ),
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                color: isDark
                                    ? AppColor.darkSubCard
                                    : AppColor.lightSubCard,
                                child: Icon(
                                  state.categoryType.icon,
                                  size: 40,
                                  color: color,
                                ),
                              ),
                      ),
                      if (state.isBadgeEnabled && state.badgeId.isNotEmpty)
                        Builder(
                          builder: (context) {
                            Color badgeColor = const Color(0xFFF59E0B);
                            try {
                              final badges =
                                  context.read<BadgeCubit>().currentBadges;
                              final match = badges
                                  .where((b) =>
                                      b.id == state.badgeId ||
                                      b.name.toUpperCase() ==
                                          state.badgeId.toUpperCase())
                                  .firstOrNull;
                              if (match != null && match.colorHex.isNotEmpty) {
                                final clean =
                                    match.colorHex.replaceAll('#', '').trim();
                                badgeColor =
                                    Color(int.parse('FF$clean', radix: 16));
                              }
                            } catch (_) {}
                            return Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  state.badgeId,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSizes.md),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${isArabic ? state.categoryType.arabicName : state.categoryType.displayName} | ${state.brandName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                            if (state.liquidOrigin.isNotEmpty &&
                                state.categoryType ==
                                    ProductCategoryType.liquid)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0EA5E9,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  state.liquidOrigin == 'Local'
                                      ? (isArabic ? '🇪🇬 محلي' : '🇪🇬 Local')
                                      : (isArabic ? '🌍 مستورد' : '🌍 Premium'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0EA5E9),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.title.isNotEmpty && !state.title.toLowerCase().contains('untitled')
                              ? state.title
                              : (state.categoryType == ProductCategoryType.disposable
                                  ? (state.selectedFlavors.length == 1
                                      ? '${state.brandName} - ${state.selectedFlavors.first}'
                                      : '${state.brandName} (${state.categoryType.displayName})')
                                  : (state.categoryType == ProductCategoryType.liquid
                                      ? '${state.brandName} (${state.categoryType.displayName})'
                                      : '${state.brandName} ${state.categoryType.displayName}')),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.description.isNotEmpty
                              ? state.description
                              : (isArabic ? 'لا يوجد وصف للمنتج' : 'No description provided'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColor.textSecondaryDark
                                : AppColor.textSecondaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Pricing Row
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (state.variations.isNotEmpty)
                              Text(
                                isArabic ? 'يبدأ من ' : 'From ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.primary,
                                ),
                              ),
                            Text(
                              AppFormatters.formatEGP(
                                resolvedSalePrice > 0
                                    ? resolvedSalePrice
                                    : resolvedPrice,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColor.success,
                              ),
                            ),
                            if (hasDiscount) ...[
                              Text(
                                AppFormatters.formatEGP(resolvedPrice),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '-$discountPercent%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.error,
                                  ),
                                ),
                              ),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColor.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${state.variations.length} ${isArabic ? "متغير متاح" : "SKUs available"}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Summary KPI Metrics Row
        LayoutBuilder(
          builder: (context, constraints) {
            final card1 = _buildReviewMetricCard(
              context,
              title: isArabic ? 'يبدأ من (أقل سعر)' : 'Starts From (Min Price)',
              value: AppFormatters.formatEGP(
                resolvedSalePrice > 0 ? resolvedSalePrice : resolvedPrice,
              ),
              icon: Icons.monetization_on_outlined,
              color: AppColor.primary,
            );
            final card2 = _buildReviewMetricCard(
              context,
              title: isArabic ? 'عدد المتغيرات' : 'Variations Count',
              value: '${state.variations.length} ${isArabic ? "متغير" : "variants"}',
              icon: Icons.hub_rounded,
              color: AppColor.success,
            );
            final card3 = _buildReviewMetricCard(
              context,
              title: isArabic ? 'المخزون الإجمالي' : 'Total Stock',
              value: '$totalUnits ${isArabic ? "قطعة" : "units"}',
              icon: Icons.inventory_2_rounded,
              color: AppColor.warning,
            );
            final card4 = _buildReviewMetricCard(
              context,
              title: isArabic ? 'القيمة التقديرية' : 'Estimated Value',
              value: AppFormatters.formatEGP(totalInventoryValue),
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF8B5CF6),
            );
            final card5 = _buildReviewMetricCard(
              context,
              title: isArabic ? 'صافي الربح التقديري' : 'Projected Profit',
              value: totalInventoryCost > 0
                  ? '${AppFormatters.formatEGP(totalInventoryProfit)} (${totalProfitMargin.toStringAsFixed(0)}%)'
                  : AppFormatters.formatEGP(totalInventoryValue),
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF10B981),
            );

            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  Row(
                    children: [
                      card1,
                      const SizedBox(width: AppSizes.sm),
                      card2,
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      card3,
                      const SizedBox(width: AppSizes.sm),
                      card4,
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      card5,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                card1,
                const SizedBox(width: AppSizes.sm),
                card2,
                const SizedBox(width: AppSizes.sm),
                card3,
                const SizedBox(width: AppSizes.sm),
                card4,
                const SizedBox(width: AppSizes.sm),
                card5,
              ],
            );
          },
        ),
        const SizedBox(height: AppSizes.md),

        // Target Firestore Collection Ready Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_done_rounded,
                size: 18,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic
                      ? 'جاهز للنشر: سيتم حفظ بيانات الصنف والمواصفات ومصفوفة الـ SKUs في مسار Cloud Firestore: /Products/{id}'
                      : 'Ready to publish: Product details, specs, and SKUs will be saved to Cloud Firestore: /Products/{id}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
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
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColor.textSecondaryDark
                          : AppColor.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // ACTION BUTTONS (WITH STEP PROGRESS AND MODERN LABELS)
  // ----------------------------------------------------------------------
  Widget _buildActionButtons(
    BuildContext context,
    ProductFormState state,
    ProductFormCubit cubit,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isFirstStep = state.currentStep == 0;
    final isLastStep = state.currentStep == 3;

    String nextLabel;
    switch (state.currentStep) {
      case 0:
        nextLabel = isArabic ? 'المتابعة إلى المواصفات' : 'Continue to Specs';
        break;
      case 1:
        nextLabel = isArabic ? 'الانتقال إلى المتغيرات' : 'Continue to Variations';
        break;
      case 2:
        nextLabel = isArabic ? 'مراجعة الصنف النهائي' : 'Review Product';
        break;
      case 3:
      default:
        nextLabel = isArabic ? 'حفظ ونشر المنتج' : 'Save & Publish Product';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 500;

          final prevButton = isFirstStep
              ? OutlinedButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                )
              : OutlinedButton.icon(
                  onPressed: () => cubit.prevStep(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(isArabic ? 'السابق' : 'Back'),
                );

          final stepPill = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isArabic
                  ? 'الخطوة ${state.currentStep + 1} من 4'
                  : 'Step ${state.currentStep + 1} of 4',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColor.primary,
              ),
            ),
          );

          final nextButton = !isLastStep
              ? ElevatedButton.icon(
                  onPressed: () {
                    // Automatically generate and sync variations with specs when moving from Step 2 to Step 3
                    if (state.currentStep == 1) {
                      cubit.generateDynamicVariations();
                    }
                    cubit.nextStep();
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(nextLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: 12,
                    ),
                  ),
                )
              : ElevatedButton.icon(
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
                        ? (isArabic ? 'جاري الحفظ...' : 'Saving...')
                        : nextLabel,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: 14,
                    ),
                  ),
                );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: stepPill),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: prevButton),
                    const SizedBox(width: 10),
                    Expanded(child: nextButton),
                  ],
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              prevButton,
              stepPill,
              nextButton,
            ],
          );
        },
      ),
    );
  }
}

