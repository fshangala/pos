import 'cart_item_model.dart';
import 'local_order_model.dart';

class HeldOrderDraftModel {
  const HeldOrderDraftModel({required this.order, required this.items});

  final LocalOrderModel order;
  final List<CartItemModel> items;
}
