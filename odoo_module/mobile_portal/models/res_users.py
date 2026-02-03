# -*- coding: utf-8 -*-

from odoo import models, fields, api


class ResUsers(models.Model):
    _inherit = 'res.users'

    mobile_hr_access = fields.Boolean(
        string='Mobile HR Access',
        default=True,
        help='Allow access to HR module in mobile app',
    )
    mobile_sales_access = fields.Boolean(
        string='Mobile Sales Access',
        default=False,
        help='Allow access to Sales module in mobile app',
    )
    mobile_purchase_access = fields.Boolean(
        string='Mobile Purchase Access',
        default=False,
        help='Allow access to Purchase module in mobile app',
    )
    mobile_project_access = fields.Boolean(
        string='Mobile Project Access',
        default=False,
        help='Allow access to Project module in mobile app',
    )

    @api.model
    def get_mobile_permissions(self):
        """Return current user's mobile module permissions"""
        user = self.env.user
        employee = self.env['hr.employee'].search([
            ('user_id', '=', user.id)
        ], limit=1)

        return {
            'user_id': user.id,
            'username': user.login,
            'display_name': user.name,
            'employee_id': employee.id if employee else False,
            'permissions': {
                'hr': user.mobile_hr_access,
                'sales': user.mobile_sales_access,
                'purchase': user.mobile_purchase_access,
                'project': user.mobile_project_access,
            }
        }

    @api.model
    def get_mobile_dashboard_data(self):
        """Return dashboard summary data for mobile app"""
        user = self.env.user
        employee = self.env['hr.employee'].search([
            ('user_id', '=', user.id)
        ], limit=1)

        data = {
            'user': {
                'id': user.id,
                'name': user.name,
                'email': user.email,
            },
            'employee': None,
            'summary': {}
        }

        if employee:
            data['employee'] = {
                'id': employee.id,
                'name': employee.name,
                'job_title': employee.job_title,
                'department': employee.department_id.name if employee.department_id else None,
            }

            # HR Summary
            if user.mobile_hr_access:
                pending_leaves = self.env['hr.leave'].search_count([
                    ('employee_id', '=', employee.id),
                    ('state', '=', 'confirm'),
                ])
                data['summary']['pending_leaves'] = pending_leaves

            # Sales Summary
            if user.mobile_sales_access:
                open_invoices = self.env['account.move'].search_count([
                    ('move_type', '=', 'out_invoice'),
                    ('state', '=', 'posted'),
                    ('payment_state', 'in', ['not_paid', 'partial']),
                ])
                data['summary']['open_invoices'] = open_invoices

            # Project Summary
            if user.mobile_project_access:
                my_tasks = self.env['project.task'].search_count([
                    ('user_ids', 'in', [user.id]),
                    ('stage_id.fold', '=', False),
                ])
                data['summary']['active_tasks'] = my_tasks

        return data
