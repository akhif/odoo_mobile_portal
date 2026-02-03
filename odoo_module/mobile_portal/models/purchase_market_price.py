# -*- coding: utf-8 -*-

from odoo import models, fields, api


class PurchaseMarketPrice(models.Model):
    _name = 'purchase.market.price'
    _description = 'Market Price Entry'
    _order = 'date desc, create_date desc'
    _inherit = ['mail.thread']

    product_id = fields.Many2one(
        'product.product',
        string='Product',
        required=True,
        index=True,
        tracking=True,
    )
    product_tmpl_id = fields.Many2one(
        'product.template',
        string='Product Template',
        related='product_id.product_tmpl_id',
        store=True,
    )
    supplier_id = fields.Many2one(
        'res.partner',
        string='Supplier',
        domain=[('supplier_rank', '>', 0)],
    )
    price = fields.Float(
        string='Market Price',
        required=True,
        digits='Product Price',
        tracking=True,
    )
    currency_id = fields.Many2one(
        'res.currency',
        string='Currency',
        default=lambda self: self.env.company.currency_id,
        required=True,
    )
    date = fields.Date(
        string='Date',
        default=fields.Date.today,
        required=True,
        index=True,
    )
    notes = fields.Text(
        string='Notes',
    )
    user_id = fields.Many2one(
        'res.users',
        string='Recorded By',
        default=lambda self: self.env.user,
        required=True,
    )
    company_id = fields.Many2one(
        'res.company',
        string='Company',
        default=lambda self: self.env.company,
        required=True,
    )
    price_change = fields.Float(
        string='Price Change (%)',
        compute='_compute_price_change',
        store=True,
    )
    previous_price = fields.Float(
        string='Previous Price',
        compute='_compute_price_change',
        store=True,
    )

    @api.depends('product_id', 'price', 'date')
    def _compute_price_change(self):
        for record in self:
            # Find previous price for the same product
            previous = self.search([
                ('product_id', '=', record.product_id.id),
                ('id', '!=', record.id),
                ('date', '<', record.date),
            ], limit=1, order='date desc')

            if previous and previous.price:
                record.previous_price = previous.price
                record.price_change = ((record.price - previous.price) / previous.price) * 100
            else:
                record.previous_price = 0.0
                record.price_change = 0.0

    @api.model
    def create_from_mobile(self, product_id, price, date, notes=None, supplier_id=None):
        """Create market price entry from mobile app"""
        values = {
            'product_id': product_id,
            'price': price,
            'date': date,
            'notes': notes,
            'user_id': self.env.user.id,
        }
        if supplier_id:
            values['supplier_id'] = supplier_id

        return self.create(values).id

    @api.model
    def get_latest_prices(self, product_ids=None, limit=100):
        """Get latest market prices for products"""
        domain = []
        if product_ids:
            domain.append(('product_id', 'in', product_ids))

        # Group by product and get latest
        prices = self.read_group(
            domain,
            ['product_id', 'price:max', 'date:max'],
            ['product_id'],
            limit=limit,
        )

        result = []
        for price_group in prices:
            latest = self.search([
                ('product_id', '=', price_group['product_id'][0]),
            ], limit=1, order='date desc')

            if latest:
                result.append({
                    'product_id': latest.product_id.id,
                    'product_name': latest.product_id.display_name,
                    'price': latest.price,
                    'date': latest.date,
                    'price_change': latest.price_change,
                })

        return result
