import '../../../../core/utils/date_utils.dart';

class InvoiceModel {
  final int id;
  final String name;
  final int? partnerId;
  final String? partnerName;
  final double amountTotal;
  final double amountResidual;
  final double amountPaid;
  final DateTime? invoiceDate;
  final DateTime? invoiceDateDue;
  final String state;
  final String paymentState;
  final String? currency;
  final List<InvoiceLineModel> lines;

  InvoiceModel({
    required this.id,
    required this.name,
    this.partnerId,
    this.partnerName,
    required this.amountTotal,
    required this.amountResidual,
    required this.amountPaid,
    this.invoiceDate,
    this.invoiceDateDue,
    required this.state,
    required this.paymentState,
    this.currency,
    this.lines = const [],
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      partnerId: json['partner_id'] is List
          ? (json['partner_id'] as List)[0] as int
          : json['partner_id'] as int?,
      partnerName: json['partner_id'] is List && (json['partner_id'] as List).length > 1
          ? (json['partner_id'] as List)[1] as String
          : null,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      amountResidual: (json['amount_residual'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amount_total'] as num?)?.toDouble() ?? 0.0 -
                  ((json['amount_residual'] as num?)?.toDouble() ?? 0.0),
      invoiceDate: AppDateUtils.parseOdooDate(json['invoice_date']),
      invoiceDateDue: AppDateUtils.parseOdooDate(json['invoice_date_due']),
      state: json['state'] as String? ?? 'draft',
      paymentState: json['payment_state'] as String? ?? 'not_paid',
      currency: json['currency_id'] is List && (json['currency_id'] as List).length > 1
          ? (json['currency_id'] as List)[1] as String
          : null,
    );
  }

  InvoiceModel copyWithLines(List<InvoiceLineModel> newLines) {
    return InvoiceModel(
      id: id,
      name: name,
      partnerId: partnerId,
      partnerName: partnerName,
      amountTotal: amountTotal,
      amountResidual: amountResidual,
      amountPaid: amountPaid,
      invoiceDate: invoiceDate,
      invoiceDateDue: invoiceDateDue,
      state: state,
      paymentState: paymentState,
      currency: currency,
      lines: newLines,
    );
  }

  bool get isOverdue => paymentState != 'paid' &&
      invoiceDateDue != null &&
      invoiceDateDue!.isBefore(DateTime.now());

  String get stateLabel {
    switch (state) {
      case 'draft':
        return 'Draft';
      case 'posted':
        return 'Posted';
      case 'cancel':
        return 'Cancelled';
      default:
        return state;
    }
  }

  String get paymentStateLabel {
    if (isOverdue) return 'Overdue';
    switch (paymentState) {
      case 'not_paid':
        return 'Open';
      case 'in_payment':
        return 'In Payment';
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Partial';
      case 'reversed':
        return 'Reversed';
      default:
        return paymentState;
    }
  }
}

class InvoiceLineModel {
  final int id;
  final String name;
  final int? productId;
  final String? productName;
  final double quantity;
  final double priceUnit;
  final double priceSubtotal;
  final double discount;

  InvoiceLineModel({
    required this.id,
    required this.name,
    this.productId,
    this.productName,
    required this.quantity,
    required this.priceUnit,
    required this.priceSubtotal,
    this.discount = 0,
  });

  factory InvoiceLineModel.fromJson(Map<String, dynamic> json) {
    return InvoiceLineModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      productId: json['product_id'] is List
          ? (json['product_id'] as List)[0] as int
          : json['product_id'] as int?,
      productName: json['product_id'] is List && (json['product_id'] as List).length > 1
          ? (json['product_id'] as List)[1] as String
          : null,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      priceUnit: (json['price_unit'] as num?)?.toDouble() ?? 0.0,
      priceSubtotal: (json['price_subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CustomerCreditModel {
  final int partnerId;
  final String partnerName;
  final double creditLimit;
  final double creditUsed;
  final double creditAvailable;
  final double totalDue;
  final double totalOverdue;

  CustomerCreditModel({
    required this.partnerId,
    required this.partnerName,
    required this.creditLimit,
    required this.creditUsed,
    required this.creditAvailable,
    required this.totalDue,
    required this.totalOverdue,
  });
}

class InvoiceDashboard {
  final double monthlyTotal;
  final double totalOutstanding;
  final double totalOverdue;
  final int overdueCount;
  final int invoiceCount;

  InvoiceDashboard({
    required this.monthlyTotal,
    required this.totalOutstanding,
    required this.totalOverdue,
    required this.overdueCount,
    required this.invoiceCount,
  });
}
