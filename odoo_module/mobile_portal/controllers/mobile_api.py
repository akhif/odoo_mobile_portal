# -*- coding: utf-8 -*-

import base64
from datetime import datetime, date
from odoo import http, fields
from odoo.http import request


class MobilePortalController(http.Controller):
    """Mobile Portal API Controller for Flutter App"""

    # ==================== User & Auth ====================

    @http.route('/mobile/api/user/permissions', type='json', auth='user', methods=['POST'])
    def get_user_permissions(self):
        """Return current user's mobile module permissions"""
        return request.env['res.users'].get_mobile_permissions()

    @http.route('/mobile/api/user/dashboard', type='json', auth='user', methods=['POST'])
    def get_dashboard_data(self):
        """Return dashboard summary data"""
        return request.env['res.users'].get_mobile_dashboard_data()

    # ==================== HR - Payslips ====================

    @http.route('/mobile/api/hr/payslips', type='json', auth='user', methods=['POST'])
    def get_payslips(self, limit=20, offset=0):
        """Return employee payslips with pagination"""
        employee = self._get_current_employee()
        if not employee:
            return {'error': 'No employee record found for current user'}

        payslips = request.env['hr.payslip'].search_read(
            [('employee_id', '=', employee.id)],
            ['name', 'number', 'date_from', 'date_to', 'net_wage', 'state', 'struct_id'],
            limit=limit,
            offset=offset,
            order='date_from desc',
        )

        for payslip in payslips:
            if payslip.get('struct_id'):
                payslip['struct_name'] = payslip['struct_id'][1]
                payslip['struct_id'] = payslip['struct_id'][0]
            payslip['date_from'] = str(payslip['date_from']) if payslip['date_from'] else None
            payslip['date_to'] = str(payslip['date_to']) if payslip['date_to'] else None

        total = request.env['hr.payslip'].search_count([('employee_id', '=', employee.id)])

        return {
            'records': payslips,
            'total': total,
            'limit': limit,
            'offset': offset,
        }

    @http.route('/mobile/api/hr/payslip/<int:payslip_id>/pdf', type='json', auth='user', methods=['POST'])
    def get_payslip_pdf(self, payslip_id):
        """Return payslip PDF as base64"""
        employee = self._get_current_employee()
        if not employee:
            return {'error': 'No employee record found'}

        payslip = request.env['hr.payslip'].browse(payslip_id)
        if not payslip.exists() or payslip.employee_id.id != employee.id:
            return {'error': 'Payslip not found or access denied'}

        # Generate PDF report
        pdf_content, _ = request.env['ir.actions.report']._render_qweb_pdf(
            'hr_payroll.action_report_payslip',
            [payslip_id]
        )

        return {
            'filename': f'{payslip.number or payslip.name}.pdf',
            'content': base64.b64encode(pdf_content).decode('utf-8'),
        }

    # ==================== HR - Leave Requests ====================

    @http.route('/mobile/api/hr/leave/types', type='json', auth='user', methods=['POST'])
    def get_leave_types(self):
        """Return available leave types"""
        leave_types = request.env['hr.leave.type'].search_read(
            [('active', '=', True)],
            ['name', 'request_unit', 'requires_allocation'],
        )
        return {'records': leave_types}

    @http.route('/mobile/api/hr/leaves', type='json', auth='user', methods=['POST'])
    def get_leaves(self, limit=20, offset=0, state=None):
        """Return employee leave requests"""
        employee = self._get_current_employee()
        if not employee:
            return {'error': 'No employee record found'}

        domain = [('employee_id', '=', employee.id)]
        if state:
            domain.append(('state', '=', state))

        leaves = request.env['hr.leave'].search_read(
            domain,
            ['name', 'holiday_status_id', 'date_from', 'date_to', 'number_of_days',
             'state', 'notes', 'create_date'],
            limit=limit,
            offset=offset,
            order='create_date desc',
        )

        for leave in leaves:
            if leave.get('holiday_status_id'):
                leave['leave_type_name'] = leave['holiday_status_id'][1]
                leave['holiday_status_id'] = leave['holiday_status_id'][0]
            leave['date_from'] = str(leave['date_from']) if leave['date_from'] else None
            leave['date_to'] = str(leave['date_to']) if leave['date_to'] else None
            leave['create_date'] = str(leave['create_date']) if leave['create_date'] else None

        total = request.env['hr.leave'].search_count(domain)

        return {
            'records': leaves,
            'total': total,
        }

    @http.route('/mobile/api/hr/leave/create', type='json', auth='user', methods=['POST'])
    def create_leave_request(self, holiday_status_id, date_from, date_to, notes=None):
        """Create a new leave request"""
        employee = self._get_current_employee()
        if not employee:
            return {'error': 'No employee record found'}

        try:
            leave = request.env['hr.leave'].create({
                'employee_id': employee.id,
                'holiday_status_id': holiday_status_id,
                'date_from': date_from,
                'date_to': date_to,
                'notes': notes,
            })

            return {
                'success': True,
                'leave_id': leave.id,
                'message': 'Leave request created successfully',
            }
        except Exception as e:
            return {'error': str(e)}

    # ==================== HR - Remote Attendance ====================

    @http.route('/mobile/api/hr/attendance/status', type='json', auth='user', methods=['POST'])
    def get_attendance_status(self):
        """Return current attendance status"""
        employee = self._get_current_employee()
        if not employee:
            return {'error': 'No employee record found'}

        # Check for open attendance (checked in but not out)
        open_attendance = request.env['hr.remote.attendance'].search([
            ('employee_id', '=', employee.id),
            ('check_out', '=', False),
        ], limit=1, order='check_in desc')

        if open_attendance:
            return {
                'checked_in': True,
                'attendance_id': open_attendance.id,
                'check_in_time': str(open_attendance.check_in),
                'latitude': open_attendance.latitude,
                'longitude': open_attendance.longitude,
            }

        return {'checked_in': False}

    @http.route('/mobile/api/hr/attendance/check_in', type='json', auth='user', methods=['POST'])
    def remote_check_in(self, latitude, longitude, accuracy, photo_base64=None, device_info=None, is_mock=False):
        """Record remote attendance check-in"""
        employee = self._get_current_employee()
        if not employee:
            return {'error': 'No employee record found'}

        # Check if already checked in
        open_attendance = request.env['hr.remote.attendance'].search([
            ('employee_id', '=', employee.id),
            ('check_out', '=', False),
        ], limit=1)

        if open_attendance:
            return {'error': 'Already checked in. Please check out first.'}

        values = {
            'employee_id': employee.id,
            'check_in': fields.Datetime.now(),
            'latitude': latitude,
            'longitude': longitude,
            'gps_accuracy': accuracy,
            'device_info': device_info,
            'is_mock_location': is_mock,
        }

        if photo_base64:
            values['photo'] = photo_base64
            values['photo_filename'] = f'checkin_{employee.id}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.jpg'

        attendance = request.env['hr.remote.attendance'].create(values)

        return {
            'success': True,
            'attendance_id': attendance.id,
            'check_in_time': str(attendance.check_in),
            'message': 'Check-in recorded successfully',
        }

    @http.route('/mobile/api/hr/attendance/check_out', type='json', auth='user', methods=['POST'])
    def remote_check_out(self, latitude, longitude, accuracy, photo_base64=None, device_info=None, is_mock=False):
        """Record remote attendance check-out"""
        employee = self._get_current_employee()
        if not employee:
            return {'error': 'No employee record found'}

        open_attendance = request.env['hr.remote.attendance'].search([
            ('employee_id', '=', employee.id),
            ('check_out', '=', False),
        ], limit=1, order='check_in desc')

        if not open_attendance:
            return {'error': 'No open check-in found. Please check in first.'}

        values = {
            'check_out': fields.Datetime.now(),
            'checkout_latitude': latitude,
            'checkout_longitude': longitude,
            'checkout_accuracy': accuracy,
        }

        if photo_base64:
            values['checkout_photo'] = photo_base64
            values['checkout_photo_filename'] = f'checkout_{employee.id}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.jpg'

        open_attendance.write(values)

        return {
            'success': True,
            'attendance_id': open_attendance.id,
            'check_out_time': str(open_attendance.check_out),
            'worked_hours': open_attendance.worked_hours,
            'message': 'Check-out recorded successfully',
        }

    @http.route('/mobile/api/hr/attendance/history', type='json', auth='user', methods=['POST'])
    def get_attendance_history(self, limit=30, offset=0):
        """Return attendance history"""
        employee = self._get_current_employee()
        if not employee:
            return {'error': 'No employee record found'}

        attendances = request.env['hr.remote.attendance'].search_read(
            [('employee_id', '=', employee.id)],
            ['check_in', 'check_out', 'worked_hours', 'latitude', 'longitude', 'state'],
            limit=limit,
            offset=offset,
            order='check_in desc',
        )

        for att in attendances:
            att['check_in'] = str(att['check_in']) if att['check_in'] else None
            att['check_out'] = str(att['check_out']) if att['check_out'] else None

        total = request.env['hr.remote.attendance'].search_count([('employee_id', '=', employee.id)])

        return {
            'records': attendances,
            'total': total,
        }

    # ==================== HR - Documents ====================

    @http.route('/mobile/api/hr/documents', type='json', auth='user', methods=['POST'])
    def get_hr_documents(self, limit=20, offset=0):
        """Return HR document requests"""
        employee = self._get_current_employee()
        if not employee:
            return {'error': 'No employee record found'}

        documents = request.env['hr.employee.document.request'].search_read(
            [('employee_id', '=', employee.id)],
            ['name', 'document_type_id', 'description', 'state', 'submission_date', 'approval_date', 'rejection_reason'],
            limit=limit,
            offset=offset,
            order='create_date desc',
        )

        for doc in documents:
            if doc.get('document_type_id'):
                doc['document_type_name'] = doc['document_type_id'][1]
                doc['document_type_id'] = doc['document_type_id'][0]
            doc['submission_date'] = str(doc['submission_date']) if doc['submission_date'] else None
            doc['approval_date'] = str(doc['approval_date']) if doc['approval_date'] else None

        return {'records': documents}

    @http.route('/mobile/api/hr/document/types', type='json', auth='user', methods=['POST'])
    def get_document_types(self):
        """Return available document types"""
        types = request.env['hr.document.type'].search_read(
            [],
            ['name', 'description'],
        )
        return {'records': types}

    @http.route('/mobile/api/hr/document/submit', type='json', auth='user', methods=['POST'])
    def submit_hr_document(self, document_type_id, name, description=None, attachments=None):
        """Submit HR document request"""
        employee = self._get_current_employee()
        if not employee:
            return {'error': 'No employee record found'}

        try:
            doc = request.env['hr.employee.document.request'].create({
                'employee_id': employee.id,
                'document_type_id': document_type_id,
                'name': name,
                'description': description,
            })

            # Handle attachments
            if attachments:
                attachment_ids = []
                for att in attachments:
                    attachment = request.env['ir.attachment'].create({
                        'name': att.get('filename', 'document'),
                        'datas': att.get('content'),
                        'res_model': 'hr.employee.document.request',
                        'res_id': doc.id,
                    })
                    attachment_ids.append(attachment.id)

                doc.write({'attachment_ids': [(6, 0, attachment_ids)]})

            # Submit the document
            doc.action_submit()

            return {
                'success': True,
                'document_id': doc.id,
                'message': 'Document submitted successfully',
            }
        except Exception as e:
            return {'error': str(e)}

    # ==================== Sales - Invoices ====================

    @http.route('/mobile/api/sales/invoices', type='json', auth='user', methods=['POST'])
    def get_customer_invoices(self, limit=20, offset=0, state=None, partner_id=None):
        """Return customer invoices"""
        domain = [('move_type', '=', 'out_invoice')]
        if state:
            domain.append(('state', '=', state))
        if partner_id:
            domain.append(('partner_id', '=', partner_id))

        invoices = request.env['account.move'].search_read(
            domain,
            ['name', 'partner_id', 'invoice_date', 'invoice_date_due', 'amount_total',
             'amount_residual', 'state', 'payment_state'],
            limit=limit,
            offset=offset,
            order='invoice_date desc',
        )

        for inv in invoices:
            if inv.get('partner_id'):
                inv['partner_name'] = inv['partner_id'][1]
                inv['partner_id'] = inv['partner_id'][0]
            inv['invoice_date'] = str(inv['invoice_date']) if inv['invoice_date'] else None
            inv['invoice_date_due'] = str(inv['invoice_date_due']) if inv['invoice_date_due'] else None

        total = request.env['account.move'].search_count(domain)

        return {
            'records': invoices,
            'total': total,
        }

    @http.route('/mobile/api/sales/invoice/<int:invoice_id>', type='json', auth='user', methods=['POST'])
    def get_invoice_detail(self, invoice_id):
        """Return detailed invoice information"""
        invoice = request.env['account.move'].browse(invoice_id)
        if not invoice.exists():
            return {'error': 'Invoice not found'}

        lines = []
        for line in invoice.invoice_line_ids:
            lines.append({
                'id': line.id,
                'name': line.name,
                'product_id': line.product_id.id if line.product_id else None,
                'product_name': line.product_id.display_name if line.product_id else None,
                'quantity': line.quantity,
                'price_unit': line.price_unit,
                'discount': line.discount,
                'price_subtotal': line.price_subtotal,
            })

        return {
            'id': invoice.id,
            'name': invoice.name,
            'partner_id': invoice.partner_id.id,
            'partner_name': invoice.partner_id.display_name,
            'invoice_date': str(invoice.invoice_date) if invoice.invoice_date else None,
            'invoice_date_due': str(invoice.invoice_date_due) if invoice.invoice_date_due else None,
            'amount_untaxed': invoice.amount_untaxed,
            'amount_tax': invoice.amount_tax,
            'amount_total': invoice.amount_total,
            'amount_residual': invoice.amount_residual,
            'state': invoice.state,
            'payment_state': invoice.payment_state,
            'lines': lines,
        }

    # ==================== Sales - Customer Credit ====================

    @http.route('/mobile/api/sales/customer/credit', type='json', auth='user', methods=['POST'])
    def get_customer_credit(self, partner_id=None, limit=20, offset=0):
        """Return customer credit information with aging"""
        domain = [('customer_rank', '>', 0)]
        if partner_id:
            domain.append(('id', '=', partner_id))

        partners = request.env['res.partner'].search(domain, limit=limit, offset=offset)

        result = []
        for partner in partners:
            # Get aging data
            aging = self._calculate_partner_aging(partner.id)

            result.append({
                'id': partner.id,
                'name': partner.display_name,
                'credit_limit': partner.credit_limit,
                'total_receivable': partner.credit,
                'total_payable': partner.debit,
                'aging_0_30': aging.get('0_30', 0),
                'aging_31_60': aging.get('31_60', 0),
                'aging_61_90': aging.get('61_90', 0),
                'aging_90_plus': aging.get('90_plus', 0),
            })

        return {'records': result}

    def _calculate_partner_aging(self, partner_id):
        """Calculate aging buckets for a partner"""
        today = date.today()
        aging = {'0_30': 0, '31_60': 0, '61_90': 0, '90_plus': 0}

        invoices = request.env['account.move'].search([
            ('partner_id', '=', partner_id),
            ('move_type', '=', 'out_invoice'),
            ('state', '=', 'posted'),
            ('payment_state', 'in', ['not_paid', 'partial']),
        ])

        for inv in invoices:
            if not inv.invoice_date_due:
                continue

            days_due = (today - inv.invoice_date_due).days

            if days_due <= 30:
                aging['0_30'] += inv.amount_residual
            elif days_due <= 60:
                aging['31_60'] += inv.amount_residual
            elif days_due <= 90:
                aging['61_90'] += inv.amount_residual
            else:
                aging['90_plus'] += inv.amount_residual

        return aging

    # ==================== Sales - Products ====================

    @http.route('/mobile/api/sales/products', type='json', auth='user', methods=['POST'])
    def get_products(self, limit=50, offset=0, search=None):
        """Return product information"""
        domain = [('sale_ok', '=', True)]
        if search:
            domain.append('|')
            domain.append(('name', 'ilike', search))
            domain.append(('default_code', 'ilike', search))

        products = request.env['product.product'].search_read(
            domain,
            ['name', 'default_code', 'list_price', 'qty_available', 'virtual_available', 'uom_id'],
            limit=limit,
            offset=offset,
            order='name',
        )

        for prod in products:
            if prod.get('uom_id'):
                prod['uom_name'] = prod['uom_id'][1]
                prod['uom_id'] = prod['uom_id'][0]

        total = request.env['product.product'].search_count(domain)

        return {
            'records': products,
            'total': total,
        }

    # ==================== Purchase - Suppliers ====================

    @http.route('/mobile/api/purchase/suppliers', type='json', auth='user', methods=['POST'])
    def get_suppliers(self, limit=20, offset=0, search=None):
        """Return supplier information"""
        domain = [('supplier_rank', '>', 0)]
        if search:
            domain.append(('name', 'ilike', search))

        suppliers = request.env['res.partner'].search_read(
            domain,
            ['name', 'email', 'phone', 'mobile', 'street', 'city', 'country_id'],
            limit=limit,
            offset=offset,
            order='name',
        )

        for supp in suppliers:
            if supp.get('country_id'):
                supp['country_name'] = supp['country_id'][1]
                supp['country_id'] = supp['country_id'][0]

        return {'records': suppliers}

    @http.route('/mobile/api/purchase/supplier/<int:supplier_id>/prices', type='json', auth='user', methods=['POST'])
    def get_supplier_prices(self, supplier_id, limit=20):
        """Return last purchase prices from supplier"""
        # Get from purchase order lines
        order_lines = request.env['purchase.order.line'].search_read(
            [
                ('partner_id', '=', supplier_id),
                ('order_id.state', 'in', ['purchase', 'done']),
            ],
            ['product_id', 'price_unit', 'date_order', 'product_qty', 'product_uom'],
            limit=limit,
            order='date_order desc',
        )

        result = []
        seen_products = set()

        for line in order_lines:
            prod_id = line['product_id'][0] if line['product_id'] else None
            if prod_id and prod_id not in seen_products:
                seen_products.add(prod_id)
                result.append({
                    'product_id': prod_id,
                    'product_name': line['product_id'][1],
                    'last_price': line['price_unit'],
                    'last_qty': line['product_qty'],
                    'last_date': str(line['date_order']) if line['date_order'] else None,
                })

        return {'records': result}

    # ==================== Purchase - Market Prices ====================

    @http.route('/mobile/api/purchase/market_prices', type='json', auth='user', methods=['POST'])
    def get_market_prices(self, product_ids=None, limit=100):
        """Get latest market prices"""
        return request.env['purchase.market.price'].get_latest_prices(product_ids, limit)

    @http.route('/mobile/api/purchase/market_price/create', type='json', auth='user', methods=['POST'])
    def create_market_price(self, product_id, price, date_str, notes=None, supplier_id=None):
        """Record a new market price entry"""
        try:
            price_id = request.env['purchase.market.price'].create_from_mobile(
                product_id, price, date_str, notes, supplier_id
            )
            return {
                'success': True,
                'price_id': price_id,
                'message': 'Market price recorded successfully',
            }
        except Exception as e:
            return {'error': str(e)}

    # ==================== Project - Job Orders ====================

    @http.route('/mobile/api/project/tasks', type='json', auth='user', methods=['POST'])
    def get_project_tasks(self, limit=20, offset=0, project_id=None, stage_id=None):
        """Return assigned project tasks"""
        user = request.env.user
        domain = [('user_ids', 'in', [user.id])]

        if project_id:
            domain.append(('project_id', '=', project_id))
        if stage_id:
            domain.append(('stage_id', '=', stage_id))

        tasks = request.env['project.task'].search_read(
            domain,
            ['name', 'project_id', 'stage_id', 'date_deadline', 'priority',
             'description', 'progress', 'kanban_state'],
            limit=limit,
            offset=offset,
            order='date_deadline asc, priority desc',
        )

        for task in tasks:
            if task.get('project_id'):
                task['project_name'] = task['project_id'][1]
                task['project_id'] = task['project_id'][0]
            if task.get('stage_id'):
                task['stage_name'] = task['stage_id'][1]
                task['stage_id'] = task['stage_id'][0]
            task['date_deadline'] = str(task['date_deadline']) if task['date_deadline'] else None

        total = request.env['project.task'].search_count(domain)

        return {
            'records': tasks,
            'total': total,
        }

    @http.route('/mobile/api/project/task/<int:task_id>', type='json', auth='user', methods=['POST'])
    def get_task_detail(self, task_id):
        """Return detailed task information"""
        task = request.env['project.task'].browse(task_id)
        if not task.exists():
            return {'error': 'Task not found'}

        # Check if user has access
        if request.env.user.id not in task.user_ids.ids:
            return {'error': 'Access denied'}

        return {
            'id': task.id,
            'name': task.name,
            'project_id': task.project_id.id,
            'project_name': task.project_id.display_name,
            'stage_id': task.stage_id.id,
            'stage_name': task.stage_id.name,
            'date_deadline': str(task.date_deadline) if task.date_deadline else None,
            'priority': task.priority,
            'description': task.description,
            'progress': task.progress if hasattr(task, 'progress') else 0,
            'kanban_state': task.kanban_state,
        }

    @http.route('/mobile/api/project/task/<int:task_id>/update', type='json', auth='user', methods=['POST'])
    def update_task_progress(self, task_id, stage_id=None, progress=None, notes=None, kanban_state=None):
        """Update task progress"""
        task = request.env['project.task'].browse(task_id)
        if not task.exists():
            return {'error': 'Task not found'}

        if request.env.user.id not in task.user_ids.ids:
            return {'error': 'Access denied'}

        values = {}
        if stage_id is not None:
            values['stage_id'] = stage_id
        if progress is not None and hasattr(task, 'progress'):
            values['progress'] = progress
        if kanban_state is not None:
            values['kanban_state'] = kanban_state

        if values:
            task.write(values)

        # Add note as message
        if notes:
            task.message_post(body=notes, message_type='comment')

        return {
            'success': True,
            'message': 'Task updated successfully',
        }

    @http.route('/mobile/api/project/stages', type='json', auth='user', methods=['POST'])
    def get_project_stages(self, project_id=None):
        """Return project stages"""
        domain = []
        if project_id:
            domain.append(('project_ids', 'in', [project_id]))

        stages = request.env['project.task.type'].search_read(
            domain,
            ['name', 'sequence', 'fold'],
            order='sequence',
        )

        return {'records': stages}

    # ==================== Helper Methods ====================

    def _get_current_employee(self):
        """Get employee record for current user"""
        return request.env['hr.employee'].search([
            ('user_id', '=', request.env.user.id)
        ], limit=1)
