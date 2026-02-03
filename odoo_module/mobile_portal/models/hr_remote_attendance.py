# -*- coding: utf-8 -*-

from odoo import models, fields, api
from odoo.exceptions import ValidationError


class HrRemoteAttendance(models.Model):
    _name = 'hr.remote.attendance'
    _description = 'Remote Attendance'
    _order = 'check_in desc'
    _inherit = ['mail.thread', 'mail.activity.mixin']

    employee_id = fields.Many2one(
        'hr.employee',
        string='Employee',
        required=True,
        ondelete='cascade',
        index=True,
    )
    check_in = fields.Datetime(
        string='Check In',
        required=True,
        default=fields.Datetime.now,
    )
    check_out = fields.Datetime(
        string='Check Out',
    )
    latitude = fields.Float(
        string='Latitude',
        digits=(10, 7),
    )
    longitude = fields.Float(
        string='Longitude',
        digits=(10, 7),
    )
    gps_accuracy = fields.Float(
        string='GPS Accuracy (meters)',
    )
    photo = fields.Binary(
        string='Photo',
        attachment=True,
    )
    photo_filename = fields.Char(
        string='Photo Filename',
    )
    device_info = fields.Char(
        string='Device Info',
    )
    is_mock_location = fields.Boolean(
        string='Mock Location Detected',
        default=False,
    )
    state = fields.Selection([
        ('draft', 'Draft'),
        ('confirmed', 'Confirmed'),
        ('rejected', 'Rejected'),
    ], string='Status', default='draft', required=True)
    worked_hours = fields.Float(
        string='Worked Hours',
        compute='_compute_worked_hours',
        store=True,
    )
    notes = fields.Text(
        string='Notes',
    )
    location_address = fields.Char(
        string='Check-In Address',
        help='Geocoded address of check-in location',
    )
    # Checkout location fields
    checkout_latitude = fields.Float(
        string='Checkout Latitude',
        digits=(10, 7),
    )
    checkout_longitude = fields.Float(
        string='Checkout Longitude',
        digits=(10, 7),
    )
    checkout_accuracy = fields.Float(
        string='Checkout GPS Accuracy (meters)',
    )
    checkout_photo = fields.Binary(
        string='Checkout Photo',
        attachment=True,
    )
    checkout_photo_filename = fields.Char(
        string='Checkout Photo Filename',
    )
    company_id = fields.Many2one(
        'res.company',
        string='Company',
        related='employee_id.company_id',
        store=True,
    )

    @api.depends('check_in', 'check_out')
    def _compute_worked_hours(self):
        for attendance in self:
            if attendance.check_in and attendance.check_out:
                delta = attendance.check_out - attendance.check_in
                attendance.worked_hours = delta.total_seconds() / 3600.0
            else:
                attendance.worked_hours = 0.0

    @api.constrains('check_in', 'check_out')
    def _check_validity(self):
        for attendance in self:
            if attendance.check_out and attendance.check_out < attendance.check_in:
                raise ValidationError('Check Out time cannot be before Check In time.')

    @api.constrains('gps_accuracy')
    def _check_gps_accuracy(self):
        for attendance in self:
            if attendance.gps_accuracy and attendance.gps_accuracy > 100:
                attendance.notes = (attendance.notes or '') + '\nWarning: Low GPS accuracy detected.'

    def action_confirm(self):
        for record in self:
            if record.is_mock_location:
                raise ValidationError('Cannot confirm attendance with mock location detected.')
            record.state = 'confirmed'

    def action_reject(self):
        self.write({'state': 'rejected'})

    def action_reset_draft(self):
        self.write({'state': 'draft'})

    @api.model
    def create_from_mobile(self, employee_id, latitude, longitude, accuracy, photo_base64, device_info, is_mock, is_checkout=False):
        """Create attendance record from mobile app"""
        import base64

        employee = self.env['hr.employee'].browse(employee_id)
        if not employee.exists():
            raise ValidationError('Employee not found')

        values = {
            'employee_id': employee_id,
            'latitude': latitude,
            'longitude': longitude,
            'gps_accuracy': accuracy,
            'device_info': device_info,
            'is_mock_location': is_mock,
        }

        if photo_base64:
            values['photo'] = photo_base64
            values['photo_filename'] = f'attendance_{employee_id}_{fields.Datetime.now()}.jpg'

        if is_checkout:
            # Find open attendance
            open_attendance = self.search([
                ('employee_id', '=', employee_id),
                ('check_out', '=', False),
            ], limit=1, order='check_in desc')

            if open_attendance:
                open_attendance.write({
                    'check_out': fields.Datetime.now(),
                    'latitude': latitude,
                    'longitude': longitude,
                })
                return open_attendance.id
            else:
                raise ValidationError('No open attendance record found')
        else:
            values['check_in'] = fields.Datetime.now()
            return self.create(values).id
