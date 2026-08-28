import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import 'product_creation_wizard.dart';

class ProductFormDialog {
  ProductFormDialog._();

  static void show(
    BuildContext context, {
    ProductModel? initialProduct,
    required ValueChanged<ProductModel> onSave,
  }) {
    ProductCreationWizard.show(
      context,
      initialProduct: initialProduct,
      onSave: onSave,
    );
  }
}

