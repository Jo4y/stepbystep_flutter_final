// 檔案：lib/screens/add_spot_screen.dart
import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

class AddSpotScreen extends StatefulWidget {
  const AddSpotScreen({super.key});

  @override
  State<AddSpotScreen> createState() => _AddSpotScreenState();
}

class _AddSpotScreenState extends State<AddSpotScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<GeoLocation> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  static const Color gooseYellowBg = Color(0xFFFFFDF2);
  static const Color gooseYellowCard = Color(0xFFFFF9D6);
  static const Color earthyYellow = Color(0xFFD49E35);
  static const Color darkBlue = Color(0xFF1A365D);

  Future<void> _searchPlace() async {
    if (_searchController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = [];
    });

    try {
      final results = await ApiService.getCoordinates(_searchController.text.trim());
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '找不到相關景點，請換個關鍵字試試！';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _askDurationAndConfirm(GeoLocation selectedLoc) {
    final durationController = TextEditingController(text: '60'); 

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: gooseYellowBg, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.timer, color: earthyYellow),
              SizedBox(width: 8),
              Text('設定停留時間', style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📍 ${selectedLoc.displayName.split(',')[0]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkBlue)),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: '預計停留時間 (分鐘)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: earthyYellow.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: earthyYellow, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: earthyYellow, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final int minutes = int.tryParse(durationController.text) ?? 60;
                Navigator.pop(context); 
                
                Navigator.pop(context, {
                  'spotName': selectedLoc.displayName.split(',')[0],
                  'lat': selectedLoc.lat,
                  'lon': selectedLoc.lon,
                  'duration': minutes,
                });
              },
              child: const Text('確認加入', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gooseYellowBg, 
      appBar: AppBar(
        title: const Text('搜尋並插入新景點', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: darkBlue, 
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          //  `SearchBar`
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: '輸入想去的店名、景點或地址...',
              leading: const Icon(Icons.search, color: earthyYellow),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.white),
              side: WidgetStateProperty.all(BorderSide(color: earthyYellow.withOpacity(0.5), width: 1.5)),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              textStyle: WidgetStateProperty.all(const TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
              hintStyle: WidgetStateProperty.all(const TextStyle(color: Colors.grey)),
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
                    onPressed: _searchPlace,
                  ),
              ],
              onSubmitted: (_) => _searchPlace(),
            ),
          ),

          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),

          // 搜尋結果列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: darkBlue))
                : _searchResults.isEmpty
                    ? const Center(child: Text('想去哪裡呢？在上方輸入看看吧！', style: TextStyle(color: Colors.grey, fontSize: 16)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final loc = _searchResults[index];
                          final shortName = loc.displayName.split(',')[0];
                          
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
                              title: Text(shortName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkBlue)),
                              subtitle: Text(loc.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                              trailing: ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('加入', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: earthyYellow, 
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: () => _askDurationAndConfirm(loc),
                              ),
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