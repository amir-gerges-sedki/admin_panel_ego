import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../cubit/product_form_cubit.dart';
import 'type_forms/accessory_form_section.dart';
import 'type_forms/coils_and_cartridges_form_section.dart';
import 'type_forms/device_form_section.dart';
import 'type_forms/disposable_form_section.dart';
import 'type_forms/liquid_form_section.dart';

export 'type_forms/accessory_form_section.dart';
export 'type_forms/coils_and_cartridges_form_section.dart';
export 'type_forms/device_form_section.dart';
export 'type_forms/disposable_form_section.dart';
export 'type_forms/form_section_header.dart';
export 'type_forms/liquid_form_section.dart';

/// Dynamic product type form dispatcher based on active category
class DynamicTypeFormSection extends StatelessWidget {
  const DynamicTypeFormSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductFormCubit, ProductFormState>(
      builder: (context, state) {
        switch (state.categoryType) {
          case ProductCategoryType.liquid:
            return const LiquidFormSection();
          case ProductCategoryType.disposable:
            return const DisposableFormSection();
          case ProductCategoryType.device:
            return const DeviceFormSection();
          case ProductCategoryType.pod:
          case ProductCategoryType.coil:
            return const CoilsAndCartridgesFormSection();
          case ProductCategoryType.accessory:
            return const AccessoryFormSection();
        }
      },
    );
  }
}
