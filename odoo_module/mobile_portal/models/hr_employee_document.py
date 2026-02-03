# -*- coding: utf-8 -*-

from odoo import models, fields, api


class HrDocumentType(models.Model):
    _name = 'hr.document.type'
    _description = 'HR Document Type'
    _order = 'sequence, name'

    name = fields.Char(
        string='Document Type',
        required=True,
    )
    description = fields.Text(
        string='Description',
    )
    is_required = fields.Boolean(
        string='Required',
        default=False,
    )
    sequence = fields.Integer(
        string='Sequence',
        default=10,
    )
    active = fields.Boolean(
        string='Active',
        default=True,
    )


class HrEmployeeDocumentRequest(models.Model):
    _name = 'hr.employee.document.request'
    _description = 'HR Document Request'
    _order = 'create_date desc'
    _inherit = ['mail.thread', 'mail.activity.mixin']

    name = fields.Char(
        string='Document Name',
        required=True,
        tracking=True,
    )
    employee_id = fields.Many2one(
        'hr.employee',
        string='Employee',
        required=True,
        ondelete='cascade',
        index=True,
    )
    document_type_id = fields.Many2one(
        'hr.document.type',
        string='Document Type',
        required=True,
    )
    description = fields.Text(
        string='Description',
    )
    attachment_ids = fields.Many2many(
        'ir.attachment',
        'hr_document_attachment_rel',
        'document_id',
        'attachment_id',
        string='Attachments',
    )
    state = fields.Selection([
        ('requested', 'Requested'),
        ('submitted', 'Submitted'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ], string='Status', default='requested', required=True, tracking=True)
    submission_date = fields.Datetime(
        string='Submission Date',
    )
    approval_date = fields.Datetime(
        string='Approval Date',
    )
    approved_by = fields.Many2one(
        'res.users',
        string='Approved By',
    )
    rejection_reason = fields.Text(
        string='Rejection Reason',
    )
    company_id = fields.Many2one(
        'res.company',
        string='Company',
        related='employee_id.company_id',
        store=True,
    )

    @api.model
    def create(self, vals):
        """Override create to set name if not provided"""
        if not vals.get('name') and vals.get('document_type_id'):
            doc_type = self.env['hr.document.type'].browse(vals['document_type_id'])
            employee = self.env['hr.employee'].browse(vals.get('employee_id'))
            vals['name'] = f"{doc_type.name} - {employee.name}"
        return super().create(vals)

    def action_submit(self):
        """Submit document for approval"""
        for record in self:
            if not record.attachment_ids:
                raise models.ValidationError('Please attach at least one document before submitting.')
            record.write({
                'state': 'submitted',
                'submission_date': fields.Datetime.now(),
            })

    def action_approve(self):
        """Approve the document"""
        self.write({
            'state': 'approved',
            'approval_date': fields.Datetime.now(),
            'approved_by': self.env.user.id,
        })

    def action_reject(self):
        """Reject the document"""
        return {
            'type': 'ir.actions.act_window',
            'name': 'Rejection Reason',
            'res_model': 'hr.document.reject.wizard',
            'view_mode': 'form',
            'target': 'new',
            'context': {'default_document_id': self.id},
        }

    def action_reset_to_requested(self):
        """Reset to requested state"""
        self.write({
            'state': 'requested',
            'submission_date': False,
            'approval_date': False,
            'approved_by': False,
            'rejection_reason': False,
        })


class HrDocumentRejectWizard(models.TransientModel):
    _name = 'hr.document.reject.wizard'
    _description = 'Document Rejection Wizard'

    document_id = fields.Many2one(
        'hr.employee.document.request',
        string='Document',
        required=True,
    )
    rejection_reason = fields.Text(
        string='Rejection Reason',
        required=True,
    )

    def action_reject(self):
        """Confirm rejection"""
        self.document_id.write({
            'state': 'rejected',
            'rejection_reason': self.rejection_reason,
        })
        return {'type': 'ir.actions.act_window_close'}
