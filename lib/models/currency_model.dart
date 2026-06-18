class CurrencyRate {
  final String baseCode;
  final Map<String, dynamic> conversionRates;

  CurrencyRate({required this.baseCode, required this.conversionRates});

  // [02] 解析匯率 API 的 JSON
  factory CurrencyRate.fromJson(Map<String, dynamic> json) {
    return CurrencyRate(
      baseCode: json['base_code'] ?? 'TWD',
      conversionRates: json['conversion_rates'] ?? {},
    );
  }
}