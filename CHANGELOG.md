# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.0] - 2026-08-04

### Added
- `Cetustek.config.logger`(預設 `nil`,即這個 gem 不寫任何東西)。只記訂單編號、
  發票號碼與結果代碼,失敗時才以 debug 記下請求 XML
- 開立發票補上規格 Table 1/2 缺漏的欄位:明細的 `Unit`,主檔的 `Remark`、`ZeroReason`、
  `RoundNum`、`MailSend`、`RtnMsg`,以及 `BuyerAddress`/`BuyerPersonInCharge`/
  `BuyerTelephoneNumber`/`BuyerFacsimileNumber`/`BuyerCustomerNumber`
- `InvoiceData` 依規格驗證必填與條件欄位(`order_id`/`order_date`/`items`/
  `donate_mark`/`payment_type` 必填;`donate_mark=0` 需 email 與載具三欄;
  `donate_mark=1` 需 3-7 碼 `npo_ban`;`tax_type=4` 需明確 `tax_rate` 且
  `invoice_type` 為 `08`),違反時建構就丟 `ArgumentError`
- `carrier_id1` 成為顯碼的正式名稱(`carrier_id` 保留為別名),`carrier_id2` 未填時
  自動鏡射顯碼 —— 手機條碼與自然人憑證沒有顯隱碼之分
- `CancelInvoice` 支援 `remark:`(作廢原因,預設 `'退貨'`)與
  `return_tax_document_number:`(專案作廢核准文號,超過申報期間作廢時需要)

### Changed
- **Breaking:** 開立發票預設帶 `<RtnMsg>Json</RtnMsg>`,`CreateInvoice#execute` 除了
  既有的 `:number`/`:random_number` 另外回傳 `:date`/`:time` 與各項金額。發票日期改以
  API 回傳為準,不再用本機 `Time.zone.today` 推測(`Intertemporal` 回開會讓本機日期錯誤)。
  傳 `rtn_msg: nil` 可退回舊的 15 碼字串模式
- **Breaking:** 開立與作廢發票失敗一律丟 `Cetustek::ResultError`,帶原始代碼與 Table 7 /
  Table 10 的中文說明。`ResponseHandler::InvalidResponseError` 降為 `ResultError` 的子類
  (deprecated,既有 rescue 仍可運作);`CancelInvoice` 不再靜默回傳 nil
- **Breaking:** `CancelInvoice.new(invoice_number, invoice_year, remark:)` 改收明確參數,
  不再接受 invoice 物件,也不再回寫 `canceled: true`
- **Breaking:** 移除 `CreateInvoice` 的 `invoice_info` 回寫與兩處 `Rails.root/log/*` 寫檔
  (原本會把含買受人 email 的整包回應寫進固定路徑);`InvoiceService.new(xml, hastax)`
  不再接受 `order_id`
- 成功判斷改用規格寫的 15 碼規則(`發票號碼;隨機碼`),而非「字串含分號」

## [0.7.0] - 2026-08-04

### Added
- `Cetustek::QueryAllowance.find(allowance_number)` — 查詢折讓資料 (§2.11) with the
  returned XML parsed into a Hash (snake_case keys + `:details` array); `nil` when the
  allowance number is unknown. `.query` still returns the raw Savon response
- `Cetustek::ResultError` (with `#code`) plus the full 折讓 result-code tables from
  spec Table 17/19, including the suffixed forms (`M:欄位`, `D2_3`)

### Changed
- **Breaking:** `CreateAllowance#execute` / `CancelAllowance#execute` now raise
  `Cetustek::ResultError` on any code other than `A0` / `C0` instead of returning it
  (e.g. `A2` 折讓金額大於原發票, `A7` 折讓日期早於發票日, `C2` 已申報無法作廢)
- **Breaking:** `AllowanceData` validates `tax_type`; only `1` 應稅 / `2` 零稅率 /
  `3` 免稅 are valid on a 折讓單 (spec Table 15), the invoice-only `4`/`5`/`9` now
  raise `ArgumentError`
- **Breaking:** `CreateAllowance.new(data, check_allowance: 1)` now raises
  `ArgumentError`. The spec struck out the unconfirmed-allowance flag — 114/01/01 起
  上傳的折讓單皆為已確認,只能送 `0`

## [0.6.0] - 2026-06-30

### Added
- `Cetustek::DonateMark` constants for 捐贈註記 (spec AVM-26-03 Table 1):
  `CARRIER` (0), `DONATE` (1), `PAPER` (2). Convenience only — `donate_mark`
  still accepts any raw value.

## [0.5.0] - 2026-06-30

### Added
- `Cetustek::PayWay` constants for the 付款方式 codes (spec AVM-26-03 Table 4):
  `CASH`/`ATM`/`CREDIT_CARD`/`CVS`/`OTHER`/`E_PAYMENT` plus `APPLE_PAY`, `LINE_PAY`,
  `GOOGLE_PAY`, `JKO_PAY`, `TAIWAN_PAY`, etc. Convenience only — `payment_type` still
  accepts any raw value, so new platform codes need no gem update.

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
