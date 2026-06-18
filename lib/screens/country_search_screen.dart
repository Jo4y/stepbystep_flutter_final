// 檔案：lib/screens/country_search_screen.dart
import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

class CountrySearchScreen extends StatefulWidget {
  const CountrySearchScreen({super.key});

  @override
  State<CountrySearchScreen> createState() => _CountrySearchScreenState();
}

class _CountrySearchScreenState extends State<CountrySearchScreen> {
  final TextEditingController _keywordController = TextEditingController();
  
  List<Country> _countries = [];
  bool _isLoading = false;
  String _errorMessage = '';

  static const Color gooseYellowBg = Color(0xFFFFFDF2);
  static const Color darkBlue = Color(0xFF1A365D);
  static const Color earthyYellow = Color(0xFFD49E35);
  static const Color lightBlue = Color(0xFFE6F3FF);

  Future<void> _performSearch() async {
    if (_keywordController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _countries = [];
    });

    try {
      final results = await ApiService.fetchCountries(_keywordController.text.trim());
      setState(() {
        _countries = results;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gooseYellowBg, 
      appBar: AppBar(
        title: const Text('選擇旅遊目的地', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: darkBlue, 
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🌟 核心修正：全面升級為官方標準 `SearchBar` 元件！
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _keywordController,
              hintText: '輸入國家名稱 (英文，如 Taiwan, Japan)',
              leading: const Icon(Icons.public, color: earthyYellow),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.white),
              side: WidgetStateProperty.all(BorderSide(color: earthyYellow.withOpacity(0.5), width: 1.5)),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              textStyle: WidgetStateProperty.all(const TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
              hintStyle: WidgetStateProperty.all(const TextStyle(color: Colors.grey)),
              // 🌟 將搜尋按鈕與轉圈圈動態整合進 SearchBar 尾端，維持視覺乾淨度
              trailing: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: darkBlue),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: darkBlue),
                    onPressed: _performSearch,
                  ),
              ],
              onSubmitted: (_) => _performSearch(),
            ),
          ),

          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ),

          // 下半部：國家清單顯示區
          Expanded(
            child: _countries.isEmpty && !_isLoading && _errorMessage.isEmpty
                ? const Center(child: Text('輸入英文名稱來尋找貨幣！', style: TextStyle(color: Colors.grey, fontSize: 16)))
                : _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: darkBlue)) // 🌟 清單載入中防呆
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _countries.length,
                        itemBuilder: (context, index) {
                          final country = _countries[index];
                          return Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: earthyYellow.withOpacity(0.2)),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  country.flagUrl,
                                  width: 60,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                      const Icon(Icons.flag, size: 40, color: Colors.grey),
                                ),
                              ),
                              title: Text(country.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBlue)),
                              trailing: const Icon(Icons.add_circle, color: earthyYellow, size: 28),
                              onTap: () {
                                Navigator.pop(context, {
                                  'country': country.name, 
                                  'currency': country.currencyCode ?? 'USD', 
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}