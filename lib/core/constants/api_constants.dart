class ApiConstants {
  // JSON-RPC Endpoints
  static const String jsonRpcEndpoint = '/jsonrpc';
  static const String webEndpoint = '/web';
  static const String sessionEndpoint = '/web/session/authenticate';

  // JSON-RPC Services
  static const String serviceCommon = 'common';
  static const String serviceObject = 'object';
  static const String serviceDb = 'db';

  // JSON-RPC Methods
  static const String methodAuthenticate = 'authenticate';
  static const String methodExecuteKw = 'execute_kw';
  static const String methodVersion = 'version';
  static const String methodList = 'list';

  // ORM Methods
  static const String ormSearchRead = 'search_read';
  static const String ormSearch = 'search';
  static const String ormRead = 'read';
  static const String ormCreate = 'create';
  static const String ormWrite = 'write';
  static const String ormUnlink = 'unlink';
  static const String ormSearchCount = 'search_count';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Mobile Portal API Endpoints
  static const String mobileApiBase = '/mobile/api';
  static const String mobileUserRoles = '/mobile/api/user/roles';
  static const String mobileHrPayslips = '/mobile/api/hr/payslips';
  static const String mobileHrLeaveCreate = '/mobile/api/hr/leave/create';
  static const String mobileHrAttendanceCheckIn = '/mobile/api/hr/attendance/check_in';
  static const String mobileHrAttendanceCheckOut = '/mobile/api/hr/attendance/check_out';
  static const String mobileSalesInvoices = '/mobile/api/sales/invoices';
  static const String mobilePurchaseMarketPrice = '/mobile/api/purchase/market_price/create';
}
