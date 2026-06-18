import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import 'country_search_screen.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  Future<ExchangeRate>? _exchangeFuture;
  
  String _inputAmount = '100';      
  String _sourceCurrency = 'TWD';  
  String _targetCurrency = 'JPY';  

  final List<String> _currencies = ['TWD', 'JPY', 'KRW', 'USD', 'EUR', 'HKD', 'THB'];

  static const Color gooseYellowBg = Color(0xFFFFFDF2);
  static const Color gooseYellowCard = Color(0xFFFFF9D6);
  static const Color earthyYellow = Color(0xFFD49E35);
  static const Color lightBlue = Color(0xFFE6F3FF);
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color darkBlue = Color(0xFF1A365D);

  @override
  void initState() {
    super.initState();
    _exchangeFuture = ApiService.fetchExchangeRates();
  }

  void _onKeyPressed(String value) {
    setState(() {
      if (value == 'C') {
        _inputAmount = '0';
      } else if (value == '⌫') {
        if (_inputAmount.length > 1) {
          _inputAmount = _inputAmount.substring(0, _inputAmount.length - 1);
        } else {
          _inputAmount = '0';
        }
      } else {
        if (_inputAmount == '0') {
          _inputAmount = value;
        } else if (_inputAmount.length < 8) {
          _inputAmount += value;
        }
      }
    });
  }

  String _convertCurrency(Map<String, dynamic> rates) {
    final double? amount = double.tryParse(_inputAmount);
    if (amount == null || amount == 0) return '0';

    final double sourceRate = _sourceCurrency == 'TWD' 
        ? 1.0 : ((rates[_sourceCurrency] ?? 1.0) as num).toDouble();
        
    final double targetRate = _targetCurrency == 'TWD' 
        ? 1.0 : ((rates[_targetCurrency] ?? 1.0) as num).toDouble();

    final double twdBase = amount / sourceRate;
    final double result = twdBase * targetRate;

    return result % 1 == 0 ? result.toStringAsFixed(0) : result.toStringAsFixed(2);
  }

  Future<void> _searchAndSetCurrency(bool isSource) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (context) => const CountrySearchScreen()),
    );

    if (result != null && context.mounted) {
      final selectedCountry = result['country']!;
      final newCurrency = result['currency']!;
      
      setState(() {
        if (!_currencies.contains(newCurrency)) {
          _currencies.add(newCurrency);
        }
        if (isSource) {
          _sourceCurrency = newCurrency;
        } else {
          _targetCurrency = newCurrency;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('偵測到 $selectedCountry，已切換為 $newCurrency'),
          backgroundColor: skyBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gooseYellowBg,
      appBar: AppBar(
        title: const Text('旅遊匯率計算機', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<ExchangeRate>(
        future: _exchangeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: darkBlue));
          } else if (snapshot.hasError) {
            return Center(child: Text('載入失敗: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          } else if (snapshot.hasData) {
            final rates = snapshot.data!.rates;
            final String convertedResult = _convertCurrency(rates);

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: earthyYellow, width: 2),
                    boxShadow: [BoxShadow(color: earthyYellow.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              DropdownButton<String>(
                                value: _sourceCurrency,
                                underline: const SizedBox(),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBlue),
                                items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (val) => setState(() => _sourceCurrency = val!),
                              ),
                              IconButton(
                                icon: const Icon(Icons.travel_explore, color: darkBlue, size: 24),
                                onPressed: () => _searchAndSetCurrency(true), 
                              ),
                            ],
                          ),
                          Expanded(
                            child: Text(
                              _inputAmount,
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkBlue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: lightBlue),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              DropdownButton<String>(
                                value: _targetCurrency,
                                underline: const SizedBox(),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: earthyYellow),
                                items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (val) => setState(() => _targetCurrency = val!),
                              ),
                              IconButton(
                                icon: const Icon(Icons.travel_explore, color: earthyYellow, size: 24),
                                onPressed: () => _searchAndSetCurrency(false), 
                              ),
                            ],
                          ),
                          Expanded(
                            child: Text(
                              convertedResult,
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: earthyYellow),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '• 即時匯率每小時更新 (Open Exchange Rates)',
                          style: TextStyle(fontSize: 10, color: Colors.black26, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 8),
                  decoration: BoxDecoration(
                    color: gooseYellowCard,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -3))],
                  ),
                  child: SafeArea(
                    top: false,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3, // 🌟 關鍵：一行 3 格
                      childAspectRatio: 1.4,
                      children: [
                        _buildKey('1'), _buildKey('2'), _buildKey('3'),
                        _buildKey('4'), _buildKey('5'), _buildKey('6'),
                        _buildKey('7'), _buildKey('8'), _buildKey('9'),
                        _buildKey('C', textColor: earthyYellow),
                        _buildKey('0'),
                        _buildKey('⌫', textColor: earthyYellow),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildKey(String label, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: InkWell(
        onTap: () => _onKeyPressed(label),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1))],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor ?? darkBlue),
            ),
          ),
        ),
      ),
    );
  }
}