# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [Unreleased]

### Added
- None

### Changed
- None

### Deprecated
- None

### Removed
- None

### Fixed
- None

### Security
- None
