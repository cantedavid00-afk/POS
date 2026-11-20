import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../../shared/models/cart_item.dart' show parseModifiers;
import '../../../../../shared/models/sale.dart';
import '../../../../../shared/models/store.dart';
import '../../../../../shared/widgets/bottom_padding.dart';
import '../../../../sales/data/pdf_service.dart';
import 'admin_theme_tokens.dart';
import 'widgets/admin_card.dart';
import 'widgets/admin_section_header.dart';
import 'widgets/admin_status_badge.dart';

/// Detalle amplio de un recibo con la paleta del dashboard:
/// cabecera con folio y badges, datos del ticket, productos con
/// modificadores y descuentos, totales desglosados y devoluciones.
/// Incluye botón PDF (misma generación que el ticket clásico).
class AdminSaleDetailScreen extends StatelessWidget {
  const AdminSaleDetailScreen({
    super.key,
    required this.businessName,
    required this.storeName,
    required this.store,
    required this.sale,
  });

  final String businessName;
  final String storeName;
  final Store? store;
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.light(),
      child: Scaffold(
        backgroundColor: AdminColors.appBg,
        appBar: AppBar(
          title: Text(sale.isRefund ? 'Devolución ${sale.folio}' : 'Ticket ${sale.folio}'),
          actions: [
            if (store != null)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'PDF',
                onPressed: () => _generatePdf(context),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24).copyWith(
            bottom: BottomPadding.of(context, minimum: 24),
          ),
          children: [
            AdminSectionHeader(
              title: sale.isRefund ? 'Devolución ${sale.folio}' : 'Ticket ${sale.folio}',
              subtitle: '$businessName · $storeName',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AdminStatusBadge.saleStatus(sale.status, isRefund: sale.isRefund),
                const SizedBox(width: 8),
                AdminStatusBadge.payment(sale.paymentMethod),
              ],
            ),
            const SizedBox(height: 16),
            AdminCard(
              title: 'Datos del ticket',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _row('Folio', sale.folio),
                  _row('Sucursal', storeName),
                  _row('Fecha', _dateLabel()),
                  _row('Pago', _paymentLabel()),
                  if (sale.paymentMethod == 'split') ...[
                    _row('Efectivo', AdminFormat.money(sale.cashAmount ?? 0)),
                    _row('Tarjeta', AdminFormat.money(sale.cardAmount ?? 0)),
                  ],
                  if (sale.discountTotal > 0)
                    _row(
                      'Descuento ticket${sale.discountName.isNotEmpty ? ' (${sale.discountName})' : ''}',
                      '-${AdminFormat.money(sale.discountTotal)}',
                    ),
                  if (sale.cashReceived != null) _row('Recibido', AdminFormat.money(sale.cashReceived!)),
                  if (sale.changeDue != null) _row('Cambio', AdminFormat.money(sale.changeDue!)),
                  if (sale.originalSaleId != null) _row('Ticket original', sale.originalSaleId!),
                  if (sale.cancelReason != null && sale.cancelReason!.isNotEmpty)
                    _row('Motivo', sale.cancelReason!),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AdminCard(
              title: 'Productos (${sale.items.length})',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [for (final item in sale.items) _itemRow(item)],
              ),
            ),
            const SizedBox(height: 12),
            AdminCard(
              title: 'Totales',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _row('Subtotal', AdminFormat.money(sale.subtotal)),
                  _row('Descuentos', '-${AdminFormat.money(_totalDiscounts())}'),
                  const Divider(height: 20, color: AdminColors.border),
                  _row(
                    sale.isRefund ? 'Total devuelto' : 'Total',
                    AdminFormat.money(sale.total),
                    bold: true,
                  ),
                ],
              ),
            ),
            if (sale.returnedItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              AdminCard(
                title: 'Productos devueltos',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in sale.returnedItems)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '• ${item['name'] ?? 'Producto'}: ${AdminFormat.qty((item['quantity'] as num? ?? 0).toDouble())}',
                          style: AdminText.body,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (sale.refundIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              AdminCard(
                title: 'Devoluciones ligadas',
                child: Text(
                  sale.refundIds.join(' · '),
                  style: AdminText.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _totalDiscounts() {
    var total = sale.discountTotal;
    for (final item in sale.items) {
      total += (item['discount'] as num? ?? 0).toDouble();
    }
    return total;
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = bold
        ? AdminText.body.copyWith(fontWeight: FontWeight.w800, fontSize: 16)
        : AdminText.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: style)),
        ],
      ),
    );
  }

  Widget _itemRow(Map<String, dynamic> item) {
    final name = item['name'] as String? ?? 'Producto';
    final quantity = (item['quantity'] as num? ?? 0).toDouble();
    final unitPrice = (item['unitPrice'] as num? ?? 0).toDouble();
    final subtotal = (item['subtotal'] as num? ?? 0).toDouble();
    final discount = (item['discount'] as num? ?? 0).toDouble();
    final discountName = item['discountName'] as String? ?? '';
    final modifiers = parseModifiers(item['modifiers']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AdminText.body.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${AdminFormat.qty(quantity)} x ${AdminFormat.money(unitPrice)}',
                  style: AdminText.bodySmall,
                ),
                for (final m in modifiers)
                  Text(
                    m.price == 0 ? '+ ${m.name}' : '+ ${m.name} (+${AdminFormat.money(m.price)})',
                    style: AdminText.bodySmall,
                  ),
                if (discount > 0)
                  Text(
                    'Descuento${discountName.isNotEmpty ? ' ($discountName)' : ''}: -${AdminFormat.money(discount)}',
                    style: AdminText.bodySmall.copyWith(color: AdminColors.success),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(AdminFormat.money(subtotal),
              style: AdminText.body.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _paymentLabel() {
    switch (sale.paymentMethod) {
      case 'card':
        return 'Tarjeta';
      case 'split':
        return 'Mixto';
      default:
        return 'Efectivo';
    }
  }

  String _dateLabel() {
    final d = sale.clientCreatedAt ?? sale.createdAt;
    if (d == null) return '—';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$min';
  }

  Future<void> _generatePdf(BuildContext context) async {
    final currentStore = store;
    if (currentStore == null) return;
    final pdfBytes = await PdfService().generateTicketPdf(
      businessName: businessName,
      store: currentStore,
      sale: sale,
    );
    if (!context.mounted) return;
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }
}
