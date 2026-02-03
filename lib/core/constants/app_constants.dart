class AppConstants {
  // App Info
  static const String appName = 'Odoo Portal';
  static const String appVersion = '1.0.0';

  // Odoo Models
  static const String modelUser = 'res.users';
  static const String modelEmployee = 'hr.employee';
  static const String modelPayslip = 'hr.payslip';
  static const String modelLeave = 'hr.leave';
  static const String modelLeaveType = 'hr.leave.type';
  static const String modelAttendance = 'hr.attendance';
  static const String modelRemoteAttendance = 'hr.remote.attendance';
  static const String modelEmployeeDocument = 'hr.employee.document.request';
  static const String modelDocumentType = 'hr.document.type';
  static const String modelInvoice = 'account.move';
  static const String modelPartner = 'res.partner';
  static const String modelProduct = 'product.product';
  static const String modelProductTemplate = 'product.template';
  static const String modelPurchaseOrder = 'purchase.order';
  static const String modelPurchaseOrderLine = 'purchase.order.line';
  static const String modelMarketPrice = 'purchase.market.price';
  static const String modelProject = 'project.project';
  static const String modelTask = 'project.task';
  static const String modelGroups = 'res.groups';
  static const String modelAttachment = 'ir.attachment';

  // Security Groups for Role Detection
  static const String groupHrUser = 'hr.group_hr_user';
  static const String groupSalesUser = 'sales_team.group_sale_salesman';
  static const String groupSalesManager = 'sales_team.group_sale_manager';
  static const String groupPurchaseUser = 'purchase.group_purchase_user';
  static const String groupPurchaseManager = 'purchase.group_purchase_manager';
  static const String groupProjectUser = 'project.group_project_user';
  static const String groupProjectManager = 'project.group_project_manager';

  // Mobile Portal Groups (Custom)
  static const String groupMobileHr = 'mobile_portal.group_mobile_hr';
  static const String groupMobileSales = 'mobile_portal.group_mobile_sales';
  static const String groupMobilePurchase = 'mobile_portal.group_mobile_purchase';
  static const String groupMobileProject = 'mobile_portal.group_mobile_project';

  // Invoice States
  static const String invoiceStateDraft = 'draft';
  static const String invoiceStatePosted = 'posted';
  static const String invoiceStateCancelled = 'cancel';

  // Payment States
  static const String paymentNotPaid = 'not_paid';
  static const String paymentInPayment = 'in_payment';
  static const String paymentPaid = 'paid';
  static const String paymentPartial = 'partial';
  static const String paymentReversed = 'reversed';

  // Leave States
  static const String leaveStateDraft = 'draft';
  static const String leaveStateConfirm = 'confirm';
  static const String leaveStateRefuse = 'refuse';
  static const String leaveStateValidate1 = 'validate1';
  static const String leaveStateValidate = 'validate';

  // Attendance States
  static const String attendanceStateDraft = 'draft';
  static const String attendanceStateConfirmed = 'confirmed';
  static const String attendanceStateRejected = 'rejected';

  // Task States
  static const String taskStateNormal = '01_in_progress';
  static const String taskStateDone = '1_done';
  static const String taskStateCanceled = '1_canceled';

  // GPS Validation
  static const double minGpsAccuracy = 100.0; // meters
  static const int maxPhotoSizeKb = 500;

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayDateTimeFormat = 'dd MMM yyyy HH:mm';

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}
