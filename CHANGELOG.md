# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Breaking**: 最低 Ruby 版本提高到 3.3.0。3.0 已於 2024-04 EOL，不再收安全更新。

## [0.11.1] - 2026-09-04

### Fixed

- `QueryAllowance.find` 查無折讓單時會 raise `ResultError: nodata`，而不是回 nil。
  `nodata` 的判斷原本是 `Xml.parse_response` 的 `nil_values:` 參數，只有
  `QueryInvoice` 有傳。改成 `Xml::NIL_VALUES` 常數，所有查詢共用同一個判斷。

## [0.11.0] - 2026-08-24

### Added

- `config.transport` — `:httpi` (預設，維持現有行為) 或 `:faraday`。設成其他值
  在 `Cetustek.configure` 當下就 raise `ArgumentError`。

### Fixed

- 沙盒端點 `invoice.cetustek.com.tw` 的 `certificate verify failed`：savon 預設
  的 HTTPI 首選 adapter 是 httpclient，而 httpclient 只認 gem 內附的
  `cacert.pem`，裡面沒有該端點憑證鏈的根 Certum Trusted Root CA。只要 bundle
  裡有 httpclient，沙盒開票就會全數失敗。`config.transport = :faraday` 改走
  Faraday 的 `net_http`，讀系統信任庫。production (`www.ei.com.tw`) 不受影響。
  Faraday 路徑不能傳 `open_timeout`/`read_timeout`（savon 2.17 的
  `FaradayMigrationHint::OPTIONS` 會 raise），改由 `client.faraday.options`
  設定，兩條路徑的 300 秒逾時一致。

## [0.10.0] - 2026-08-07

延續 0.9.0 的 code review：統一驗證力度與查詢介面，讓四個查詢類別與
`CancelInvoice`/`CancelAllowance` 的行為一致。

### Added
- `QueryInvoice.find`、`QueryInvoiceByOrderId.find`、`QueryInvoiceNumberByOrderId.find`：
  比照既有的 `QueryAllowance.find`，把 Savon 回應解析成 snake_case 的 Hash（`QueryInvoice`
  與 `QueryInvoiceByOrderId` 共用 Table 13 格式，含 `:seller`/`:buyer`/`:details`），
  `nil` 表示空回覆或規格說的 `"nodata"`，非 XML 的代碼字串一律拋 `Cetustek::ResultError`
- `CancelInvoice` 補上 `invoice_number`/`invoice_year` 必填檢查（Table 9 皆為 Y），
  原本只驗證 `remark`，另兩個欄位空白時要等伺服器回 `M:?` 才會發現

### Changed
- 四個查詢類別的 XML 解析共用邏輯(`text_of`/`snake_case`)搬到 `Cetustek::Xml.parse_fields`，
  不再各自留一份幾乎相同的 private method
- `QueryInvoice`/`QueryInvoiceNumberByOrderId`/`QueryAllowance` 改用 `Soap#soap_call`，
  不再手動組 `source`/`rentid`，與 `QueryInvoiceByOrderId`/`CancelInvoice` 等類別一致
- `QueryInvoice.parse`/`QueryAllowance.parse` 共用的「空值/nodata 判斷、非 XML 代碼丟
  `ResultError`、解析成 Ox root」邏輯收成 `Cetustek::Xml.parse_response`
- `QueryInvoice.party` 改名 `parse_party`，跟同一個類別的 `parse` 放在一起看更清楚

### Fixed
- **Breaking:** `QueryInvoiceNumberByOrderId.find` 原本會把非發票號碼、非 `"nodata"`
  的回覆(如 `Invalid`)直接當發票號碼回傳；現在會比對 Table 9 的字軌+8碼數字格式，
  格式不符者一律丟 `Cetustek::ResultError`，跟其他 `Query*.find` 一致

## [0.9.0] - 2026-08-05

比對規格 AVM-26-03 做的 code review 修正:0.8.0 有幾條規則寫得比規格寬或比規格嚴,
另外把四份重複的 SOAP/XML 樣板收成共用模組。

### Fixed
- **Breaking:** `carrier_id2` 只在無顯碼隱碼區分的載具(手機條碼 `3J0002`、自然人憑證
  `CQ0001`)自動鏡射顯碼。會員載具(如鯨躍發票卡 `EJ0011`)兩碼本來就不同,0.8.0 會把顯碼
  當隱碼送出;現在未填 `carrier_id2` 會直接丟 `ArgumentError`
- `donate_mark: 0` 不再強制 `carrier_type`:規格註明「使用鯨躍發票卡,電子郵件必填,
  載具類別可為空或填 EJ0011」,原本的檢查讓這個情境無法送出。必填改為 `buyer_email`
  與 `carrier_id1`/`carrier_id2`
- `QueryAllowance.find` 移除規格沒有的 `'nodata'` 哨兵值;非 XML 的回覆(代碼字串)
  改為丟 `ResultError`,只有真的空回覆才回傳 `nil`
- 修掉註解裡捏造的規格出處(`spec V4.16`)與 TaxType 9 的「限收銀機類型發票」限制,
  Table 1 只寫「9:混合(應稅、零稅率與免稅)」

### Added
- `Cetustek::CarrierType`:`MOBILE_BARCODE` / `CITIZEN_CERT` / `CETUSTEK_CARD` 常數
- `AllowanceData` 依 Table 15 驗證必填(折讓單號、折讓日期、發票號碼、發票年份、
  折讓原因、至少一筆明細)與 `round_num` 0-7、`reason` 20 字。原本 `allowance_date`
  為 nil 會在組 XML 時炸成 `NoMethodError`
- `InvoiceItem` 依 Table 2/16 驗證 `code`/`name`/`quantity`/`unit_price` 必填(`unit` 選填)
- `CancelAllowance` 驗證 Table 18 的兩個必填欄位與 20 字上限
- `InvoiceData` 補上規格寫死的條件與範圍:`zero_reason` 限 `tax_type` 2/5、
  `mail_send` 限 `donate_mark: 0`、`round_num` 0-7、`remark` 200 字

### Changed
- **Breaking:** `CancelInvoice` 的 `remark:`(作廢原因)改為必填且限 20 字 —— Table 9 是
  必填欄位,預設 `'退貨'` 等於幫呼叫端編造理由
- **Breaking:** 移除 `Services::InvoiceService`,它只剩一次 Savon 呼叫;`CreateInvoice`
  直接送出
- `ResponseHandler` 失敗時丟 `ResultError` 本身,與折讓路徑一致。
  `ResponseHandler::InvalidResponseError` 改為 `ResultError` 的別名常數(deprecated),
  既有 `rescue InvalidResponseError` 仍然攔得到
- 新增 `Cetustek::Xml` 與 `Cetustek::Soap`,收掉五份 Savon client 與四份 `raw_tag` 複製;
  Table 7/10/17/19 共用的代碼列集中在 `ResultCode::COMMON` 與 `ResultCode::DETAILS`。
  `Cetustek::Queries` 成為 `Cetustek::Soap` 的別名(deprecated)

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
