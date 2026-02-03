# Odoo Mobile Portal

A production-ready Flutter mobile application for Odoo Portal Users (Employees) with dynamic server configuration, secure authentication, role-based access control, and four main modules: HR, Sales, Purchase, and Project.

## Features

### Authentication & Security
- Dynamic Odoo server configuration (URL, database)
- Secure credential storage using flutter_secure_storage
- Session persistence across app restarts
- Automatic session validation and re-authentication

### Role-Based Access Control
| Role | HR | Sales | Purchase | Project |
|------|-----|-------|----------|---------|
| All Employees | ✓ | - | - | - |
| Sales Staff | ✓ | ✓ | - | - |
| Purchase Staff | ✓ | - | ✓ | - |
| Project Staff | ✓ | - | - | ✓ |

### HR Module
- **Payslips**: View payslip list, download/share PDF
- **Leave Requests**: Submit leave requests with attachments
- **Vacation Requests**: Dedicated vacation request flow
- **Remote Attendance**: GPS + photo capture for check-in/check-out
- **HR Documents**: Submit documents with approval workflow

### Sales Module
- **Customer Invoices**: View invoice list and details
- **Customer Credit**: Credit limits, outstanding amounts, aging analysis
- **Product Info**: Product details, pricing, stock availability

### Purchase Module
- **Supplier Details**: Contact information, last purchase prices
- **Market Price Entry**: Record market prices for products

### Project Module
- **Job Orders**: View assigned tasks and job orders
- **Progress Updates**: Update task status with notes and attachments

### Settings
- Light/Dark theme toggle
- Server configuration display
- Logout and app reset options

## Prerequisites

- Flutter SDK >= 3.16.0
- Dart SDK >= 3.2.0
- Odoo 17 server with the `mobile_portal` module installed

## Installation

### Flutter App Setup

1. Clone the repository:
```bash
git clone https://github.com/akhif/odoo_mobile_portal.git
cd odoo_mobile_portal
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code (freezed models):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run
```

### Odoo Module Setup

1. Copy the `odoo_module/mobile_portal` folder to your Odoo addons directory:
```bash
cp -r odoo_module/mobile_portal /path/to/odoo/addons/
```

2. Restart Odoo server and update the apps list

3. Install the "Mobile Portal" module from Odoo Apps

4. Configure user permissions in Odoo:
   - Go to Settings > Users
   - Edit user and navigate to "Mobile Portal" tab
   - Enable appropriate module access (HR, Sales, Purchase, Project)

## Project Structure

```
odoo_portal_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # MaterialApp configuration
│   ├── core/
│   │   ├── config/               # App configuration
│   │   ├── constants/            # API and app constants
│   │   ├── network/              # Dio client, Odoo RPC client
│   │   ├── storage/              # Secure storage, preferences
│   │   ├── theme/                # App theme, colors, text styles
│   │   ├── widgets/              # Reusable widgets
│   │   └── utils/                # Utility functions
│   ├── features/
│   │   ├── auth/                 # Authentication flow
│   │   ├── dashboard/            # Dashboard with role-based tiles
│   │   ├── hr/                   # HR module screens
│   │   ├── sales/                # Sales module screens
│   │   ├── purchase/             # Purchase module screens
│   │   ├── project/              # Project module screens
│   │   └── settings/             # Settings screen
│   └── routes/
│       └── app_router.dart       # GoRouter configuration
├── odoo_module/
│   └── mobile_portal/            # Custom Odoo module
│       ├── models/               # Python models
│       ├── controllers/          # API controllers
│       ├── views/                # XML views
│       ├── security/             # Access rights
│       └── data/                 # Initial data
├── pubspec.yaml
└── README.md
```

## Tech Stack

### Flutter App
- **State Management**: flutter_riverpod
- **Navigation**: go_router
- **Networking**: dio
- **Storage**: flutter_secure_storage, shared_preferences
- **PDF Viewer**: syncfusion_flutter_pdfviewer
- **Location**: geolocator, permission_handler
- **Camera**: camera, image_picker
- **UI**: flutter_screenutil, shimmer, flutter_animate

### Odoo Module
- **Models**: hr.remote.attendance, hr.employee.document.request, purchase.market.price
- **API Controllers**: JSON-RPC endpoints for mobile app
- **Security**: Role-based access control groups

## API Endpoints

The mobile_portal Odoo module provides the following API endpoints:

### Authentication
- `POST /mobile/api/user/permissions` - Get user permissions
- `POST /mobile/api/user/dashboard` - Get dashboard summary

### HR
- `POST /mobile/api/hr/payslips` - Get payslip list
- `POST /mobile/api/hr/payslip/<id>/pdf` - Get payslip PDF
- `POST /mobile/api/hr/leave/types` - Get leave types
- `POST /mobile/api/hr/leaves` - Get leave requests
- `POST /mobile/api/hr/leave/create` - Create leave request
- `POST /mobile/api/hr/attendance/status` - Get attendance status
- `POST /mobile/api/hr/attendance/check_in` - Check in
- `POST /mobile/api/hr/attendance/check_out` - Check out
- `POST /mobile/api/hr/documents` - Get document requests
- `POST /mobile/api/hr/document/submit` - Submit document

### Sales
- `POST /mobile/api/sales/invoices` - Get invoices
- `POST /mobile/api/sales/invoice/<id>` - Get invoice detail
- `POST /mobile/api/sales/customer/credit` - Get customer credit
- `POST /mobile/api/sales/products` - Get products

### Purchase
- `POST /mobile/api/purchase/suppliers` - Get suppliers
- `POST /mobile/api/purchase/supplier/<id>/prices` - Get supplier prices
- `POST /mobile/api/purchase/market_prices` - Get market prices
- `POST /mobile/api/purchase/market_price/create` - Create market price

### Project
- `POST /mobile/api/project/tasks` - Get tasks
- `POST /mobile/api/project/task/<id>` - Get task detail
- `POST /mobile/api/project/task/<id>/update` - Update task
- `POST /mobile/api/project/stages` - Get project stages

## Building for Production

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Royal Al-Waha Trading Co.
