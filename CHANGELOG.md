# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-06-29

### Added
- `Cetustek::QueryInvoice.query(invoice_number, invoice_year)` — 查詢發票資訊 (§2.4)
- `Cetustek::QueryInvoiceNumberByOrderId.query(order_id)` — 以訂單編號查發票號碼 (§2.6)
- `Cetustek::CreateAllowance.new(allowance_data, check_allowance:).execute` — 開立折讓單 (§2.9)
- `Cetustek::CancelAllowance.new(allowance_number, reason).execute` — 作廢折讓單 (§2.10)
- `Cetustek::QueryAllowance.query(allowance_number)` — 查詢折讓資料 (§2.11)
- `Cetustek::PhoneBarcode.valid?(phone_code)` — 手機條碼驗證 (§3.1, HTTP/JSON, not SOAP)
- `Cetustek::Models::AllowanceData` value object and an optional `unit` on `InvoiceItem`

### Changed
- `hastax` is now taken from the order via `InvoiceData.new(hastax:)` (default `1`,
  tax-inclusive) instead of being hardcoded — e.g. tax-exclusive/tax-free purchases
  can send `0`
- All generated XML is forced to UTF-8 encoding, preventing `Encoding::CompatibilityError`
  from Savon when invoices/allowances contain Chinese text

## [0.3.0] - 2026-06-13

### Added
- Configurable tax handling per spec V4.16: `TaxType`, `TaxRate`, and `InvoiceType`
  on `InvoiceData`, with a `Cetustek::TaxType` constants module
- Zero-rate invoice support (`TaxType` 2/5)
- Mixed-tax invoice support (`TaxType` 9): per-item `tax_type` emits the required
  `DType` (`TZ`/`TN`/blank) on every detail line
- `carrier_id2` attribute on `InvoiceData` (previously read by the XML builder but
  never settable, which raised `NoMethodError` when issuing an invoice)
- Test suite for the XML builder and data models

### Changed
- XML builder now HTML-escapes every interpolated field (previously only buyer name
  and product name), preventing malformed XML / injection from special characters

### Removed
- **Breaking:** application-specific auto line items and their `InvoiceData` fields
  (`total_discount`, `coupon_discount`, `delivery_fee`, `handling_fee`). These were
  not part of the Cetustek API. Model discounts/fees as ordinary `InvoiceItem`s
  (use a negative `unit_price` for a discount)

## [0.2.0] - 2025-01-22

### Added
- Environment-specific configuration support (sandbox/production)
- Service-oriented architecture implementation
- XML builder service for invoice generation
- SOAP service wrapper
- Response handler with improved error handling
- Data transfer objects for invoice data

### Changed
- Refactored CreateInvoice class to use service pattern
- Unified configuration system
- Improved code organization and maintainability
- Enhanced error handling and logging

### Removed
- Deprecated Config class in favor of Configuration

## [0.1.0] - 2025-01-22

### Added
- Initial release
- Electronic invoice cancellation functionality
- Integrated SOAP Web Services
- Added `ox` gem for XML processing
- Added `savon` gem for SOAP service integration
