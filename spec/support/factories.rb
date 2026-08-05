# frozen_string_literal: true

# Minimal valid request data, so each example only states the fields it cares
# about. Every helper returns something that passes the model's validations.
module Factories
  def build_invoice_item(overrides = {})
    Cetustek::Models::InvoiceItem.new(
      { code: 'A1', name: 'Item', quantity: 1, unit_price: 100 }.merge(overrides)
    )
  end

  def build_invoice_attributes(overrides = {})
    {
      order_id: 'ORD1',
      order_date: Date.new(2024, 1, 2),
      donate_mark: Cetustek::DonateMark::PAPER,
      payment_type: Cetustek::PayWay::CASH,
      items: [build_invoice_item]
    }.merge(overrides)
  end

  def build_invoice_data(overrides = {})
    Cetustek::Models::InvoiceData.new(build_invoice_attributes(overrides))
  end

  def build_allowance_attributes(overrides = {})
    {
      allowance_number: 'AL001',
      allowance_date: Date.new(2024, 1, 2),
      invoice_number: 'AB12345678',
      invoice_year: '2024',
      reason: '退貨',
      items: [build_invoice_item]
    }.merge(overrides)
  end

  def build_allowance_data(overrides = {})
    Cetustek::Models::AllowanceData.new(build_allowance_attributes(overrides))
  end
end
