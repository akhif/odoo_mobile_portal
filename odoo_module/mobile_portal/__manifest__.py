# -*- coding: utf-8 -*-
{
    'name': 'Mobile Portal',
    'version': '17.0.1.0.0',
    'category': 'Human Resources/Employees',
    'summary': 'Mobile Portal API for Employee Self-Service',
    'description': '''
Mobile Portal Module
====================
This module provides:
- Remote attendance tracking with GPS and photo verification
- HR document request and submission workflow
- Market price entry for purchase department
- Mobile API endpoints for Flutter app integration
- Security groups for role-based access control
    ''',
    'author': 'Royal Al-Waha Trading Co.',
    'website': 'https://www.royalalwaha.com',
    'license': 'LGPL-3',
    'depends': [
        'base',
        'mail',
        'hr',
        'hr_attendance',
        'hr_holidays',
        'hr_payroll',
        'sale',
        'purchase',
        'project',
        'account',
    ],
    'data': [
        'security/mobile_portal_security.xml',
        'security/ir.model.access.csv',
        'views/hr_remote_attendance_views.xml',
        'views/hr_employee_document_views.xml',
        'views/purchase_market_price_views.xml',
        'views/menu_views.xml',
        'data/mobile_portal_data.xml',
    ],
    'installable': True,
    'application': True,
    'auto_install': False,
}
