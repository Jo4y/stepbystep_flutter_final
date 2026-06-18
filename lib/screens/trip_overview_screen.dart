import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'add_spot_screen.dart';
import 'package:lottie/lottie.dart';

class ItineraryItem {
  final String id;             
  final String spotName;       
  final double lat;            
  final double lon;            
  int durationMinutes;         
  String arrivalTime;          
  int travelTimeToNextNode;    
  String transportMode;        

  ItineraryItem({
    required this.id, 
    required this.spotName,
    required this.lat,
    required this.lon,
    this.durationMinutes = 60,
    this.arrivalTime = "09:00",
    this.travelTimeToNextNode = 0,
    this.transportMode = 'driving', 
  });
}

class TripOverviewScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;
  const TripOverviewScreen({super.key, required this.tripData});

  @override
  State<TripOverviewScreen> createState() => _TripOverviewScreenState();
}

class _TripOverviewScreenState extends State<TripOverviewScreen> {
  int _totalDays = 1; 
  late final Map<int, List<ItineraryItem>> _dailyItineraries = {};
  
  bool _isLoadingCloudData = true; 
  bool _isCalculating = false;
  Map<int, String> _dayIdMap = {}; 
  // 🌟 核心新增：儲存每一天自訂出發時間的狀態大腦 (格式如 {0: "09:00", 1: "08:30"})
  final Map<int, String> _dayStartTimes = {}; 

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _calculateTotalDays();
    
    for (int i = 0; i < _totalDays; i++) {
      _dailyItineraries[i] = [];
      _dayStartTimes[i] = "09:00"; // 預設每一天都是九點出發
    }

    _syncCloudData();
  }

  void _calculateTotalDays() {
    try {
      String dateRange = widget.tripData['date_range']; 
      final parts = dateRange.split(' - ');
      if (parts.length == 2) {
        final startParts = parts[0].split('/');
        final endParts = parts[1].split('/');
        final start = DateTime(int.parse(startParts[0]), int.parse(startParts[1]), int.parse(startParts[2]));
        final end = DateTime(int.parse(endParts[0]), int.parse(endParts[1]), int.parse(endParts[2]));
        _totalDays = end.difference(start).inDays + 1;
      }
    } catch (e) {
      _totalDays = 1; 
    }
  }

  // ☁️ 雲端資料同步
  Future<void> _syncCloudData() async {
    setState(() => _isLoadingCloudData = true);
    final String tripId = widget.tripData['id'];

    try {
      for (int i = 0; i < _totalDays; i++) {
        _dailyItineraries[i]!.clear();
      }

      final existingDays = await supabase
          .from('trip_days')
          .select()
          .eq('trip_id', tripId)
          .order('day_index', ascending: true);

      List<Map<String, dynamic>> allDays = List.from(existingDays);
      List<int> existingIndices = existingDays.map<int>((d) => d['day_index'] as int).toList();

      for (int i = 0; i < _totalDays; i++) {
        if (!existingIndices.contains(i)) {
          final newDay = await supabase.from('trip_days').insert({
            'trip_id': tripId,
            'day_index': i,
          }).select().single();
          allDays.add(newDay);
        }
      }

      for (var day in allDays) {
        int dIdx = day['day_index'];
        _dayIdMap[dIdx] = day['id'];
        // 🌟 核心修正：從雲端讀取這一天自訂的開始時間，若欄位不存在則防呆給 "09:00"
        _dayStartTimes[dIdx] = day['start_time'] ?? "09:00"; 
      }

      final dayIds = _dayIdMap.values.toList();
      if (dayIds.isNotEmpty) {
        final itemsData = await supabase
            .from('itinerary_items')
            .select()
            .inFilter('day_id', dayIds) 
            .order('sort_order', ascending: true);

        for (var row in itemsData) {
          int dayIdx = _dayIdMap.entries.firstWhere((e) => e.value == row['day_id']).key;
          
          _dailyItineraries[dayIdx]!.add(ItineraryItem(
            id: row['id'],
            spotName: row['spot_name'],
            lat: (row['lat'] as num).toDouble(),
            lon: (row['lon'] as num).toDouble(),
            durationMinutes: row['duration_minutes'],
            transportMode: row['transport_mode'] ?? 'driving', 
          ));
        }
      }

      await _updateTimeline(_currentDayIndex);

    } catch (e) {
      print('雲端同步發生錯誤: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCloudData = false);
    }
  }

  int _currentDayIndex = 0;

  // 彈出時間選擇器並更新出發時間
  Future<void> _selectStartTime(int dayIndex) async {
    String currentStart = _dayStartTimes[dayIndex] ?? "09:00";
    
    // 🌟 核心修正：跟時間軸一樣，進場前先把可能殘留的單雙引號、空白全部洗乾淨！
    currentStart = currentStart.replaceAll("'", "").replaceAll('"', '').trim();
    if (!currentStart.contains(':')) {
      currentStart = "09:00";
    }

    final parts = currentStart.split(':');
    
    // 🌟 安全防呆：改用 tryParse，就算天崩地裂也絕對不讓按鈕卡死閃退
    int hour = int.tryParse(parts[0]) ?? 9;
    int minute = int.tryParse(parts[1]) ?? 0;
    TimeOfDay initialTime = TimeOfDay(hour: hour, minute: minute);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: '選擇今日出發時間',
      cancelText: '取消',
      confirmText: '確定',
    );

    if (picked != null) {
      final String formattedTime = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      
      setState(() {
        _dayStartTimes[dayIndex] = formattedTime;
      });

      // ☁️ 同步回雲端表格
      try {
        final dayId = _dayIdMap[dayIndex];
        if (dayId != null) {
          await supabase.from('trip_days').update({'start_time': formattedTime}).eq('id', dayId);
        }
      } catch (e) {
        print('提醒：雲端 trip_days 尚未建立 start_time 欄位，僅於本地記憶體生效。');
      }

      // 時間改了，立刻重新連鎖推算整天時間軸！
      await _updateTimeline(dayIndex);
    }
  }

  Future<int> _getTravelTime({
    required double startLat, required double startLon,
    required double endLat, required double endLon,
    required String mode, 
  }) async {
    final String apiKey = "d527d8e950b94b26827765b33729d063"; 
    
    String geoMode = 'drive'; 
    if (mode == 'walking') geoMode = 'walk'; 
    if (mode == 'transit') geoMode = 'transit'; 

    final url = Uri.parse(
      'https://api.geoapify.com/v1/routing'
      '?waypoints=$startLat,$startLon|$endLat,$endLon'
      '&mode=$geoMode'
      '&apiKey=$apiKey'
    );
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final double durationInSeconds = data['features'][0]['properties']['time'].toDouble();
          int finalMinutes = (durationInSeconds / 60).round();
          return finalMinutes < 1 ? 1 : finalMinutes; 
        }
      } else {
        print('Geoapify 伺服器回應錯誤: ${response.body}');
      }
    } catch (e) {
      print('Geoapify API 連線發生錯誤: $e');
    }
    
    return mode == 'walking' ? 10 : (mode == 'transit' ? 25 : 15); 
  }

  // 🌟 連鎖時間軸智算引擎
  Future<void> _updateTimeline(int dayIndex) async {
    List<ItineraryItem> items = _dailyItineraries[dayIndex] ?? [];
    if (items.isEmpty) return;

    setState(() => _isCalculating = true);

    // 1. 讀取時間，並加上防禦濾網：自動拔掉可能誤入的單引號、雙引號與前後空白
    String startTime = _dayStartTimes[dayIndex] ?? "09:00";
    startTime = startTime.replaceAll("'", "").replaceAll('"', '').trim();
    
    // 2. 二次防呆：萬一字串被格式化壞了，強制還原成 09:00
    if (!startTime.contains(':')) {
      startTime = "09:00";
    }

    final timeParts = startTime.split(':');
    
    // 3. 採用 tryParse 代替 parse，就算失敗也只會給預設值，絕對不閃退！
    int currentHour = int.tryParse(timeParts[0]) ?? 9;
    int currentMinute = int.tryParse(timeParts[1]) ?? 0;
    
    // 重新格式化乾淨的時間給第一個景點
    items[0].arrivalTime = "${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}";

    for (int i = 0; i < items.length; i++) {
      currentMinute += items[i].durationMinutes;

      if (i < items.length - 1) {
        int driveTime = await _getTravelTime(
          startLat: items[i].lat,   startLon: items[i].lon,
          endLat: items[i + 1].lat, endLon: items[i + 1].lon,
          mode: items[i].transportMode,
        );

        items[i].travelTimeToNextNode = driveTime;
        currentMinute += driveTime;

        currentHour += currentMinute ~/ 60;
        currentMinute = currentMinute % 60;

        final String nextHour = currentHour.toString().padLeft(2, '0');
        final String nextMin = currentMinute.toString().padLeft(2, '0');
        
        items[i + 1].arrivalTime = "$nextHour:$nextMin";
      }
    }

    if (mounted) setState(() => _isCalculating = false);
  }

  void _showTransportModePicker(ItineraryItem item, int dayIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFDF2),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '選擇前往下一站的交通方式',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)), 
                ),
              ),
              const Divider(height: 1),
              _buildTransportOption(item, dayIndex, 'driving', Icons.directions_car, '開車前往'),
              _buildTransportOption(item, dayIndex, 'transit', Icons.directions_bus, '大眾運輸'),
              _buildTransportOption(item, dayIndex, 'walking', Icons.directions_walk, '步行前往'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransportOption(ItineraryItem item, int dayIndex, String mode, IconData icon, String label) {
    final bool isSelected = item.transportMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFFD49E35) : const Color(0xFF1A365D)),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF1A365D))),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFD49E35)) : null,
      onTap: () async {
        Navigator.pop(context); 
        setState(() {
          item.transportMode = mode;
        });
        
        try {
          await supabase.from('itinerary_items').update({'transport_mode': mode}).eq('id', item.id);
          await _updateTimeline(dayIndex); 
        } catch (e) {
          print('同步交通方式失敗: $e');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _totalDays,
      child: Builder(
        builder: (BuildContext context) {
          final TabController tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              _currentDayIndex = tabController.index;
              _updateTimeline(_currentDayIndex);
            }
          });

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.tripData['title']), 
            ),
            body: _isLoadingCloudData 
              ? const TravelLoadingWidget() 
              : Stack(
              children: [
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F3FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBCD6F5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📅 旅遊日期: ${widget.tripData['date_range']}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                    ),
                    TabBar(
                      isScrollable: _totalDays > 4, 
                      labelColor: const Color(0xFF1A365D),
                      unselectedLabelColor: Colors.black38,
                      indicatorColor: const Color(0xFF1A365D),
                      tabs: List.generate(_totalDays, (index) => Tab(text: 'Day ${index + 1}')),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: List.generate(_totalDays, (index) => _buildTimelinePage(index)),
                      ),
                    ),
                  ],
                ),
                if (_isCalculating)
                  const TravelLoadingWidget(), 
              ],
            ),
            floatingActionButton: _isLoadingCloudData ? null : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(builder: (context) => const AddSpotScreen()),
                );

                if (result != null && context.mounted) {
                  setState(() => _isCalculating = true);
                  
                  try {
                    final dayId = _dayIdMap[_currentDayIndex];
                    final sortOrder = _dailyItineraries[_currentDayIndex]!.length;

                    final insertedData = await supabase.from('itinerary_items').insert({
                      'day_id': dayId,
                      'spot_name': result['spotName'],
                      'lat': result['lat'],
                      'lon': result['lon'],
                      'duration_minutes': result['duration'],
                      'sort_order': sortOrder,
                    }).select().single();

                    final newItem = ItineraryItem(
                      id: insertedData['id'], 
                      spotName: insertedData['spot_name'],
                      lat: (insertedData['lat'] as num).toDouble(),
                      lon: (insertedData['lon'] as num).toDouble(),
                      durationMinutes: insertedData['duration_minutes'],
                      transportMode: insertedData['transport_mode'] ?? 'driving',
                    );

                    _dailyItineraries[_currentDayIndex]!.add(newItem);
                    await _updateTimeline(_currentDayIndex);
                    
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('儲存景點失敗：$e'), backgroundColor: Colors.redAccent),
                    );
                    setState(() => _isCalculating = false);
                  }
                }
              },
              label: const Text('加入新景點', style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add_location_alt),
              backgroundColor: const Color(0xFFF0E68C),
              foregroundColor: const Color(0xFFD49E35),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelinePage(int dayIndex) {
    List<ItineraryItem> items = _dailyItineraries[dayIndex] ?? [];

    if (items.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF1A365D),
        onRefresh: () => _syncCloudData(), 
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(), 
          child: SizedBox(
            height: 400, 
            child: Center(
              child: Text(
                '今天還空空如也，點擊右下角開始規劃吧！\n(可往下拉手動刷新)', 
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1A365D),
      onRefresh: () => _syncCloudData(), 
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            color: const Color(0xFFFFFDF2),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, color: Color(0xFFD49E35), size: 18),
                const SizedBox(width: 8),
                Text(
                  '今日預計出發時間：${_dayStartTimes[dayIndex] ?? "09:00"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A365D), fontSize: 14),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _selectStartTime(dayIndex),
                  icon: const Icon(Icons.edit_calendar, size: 16, color: Color(0xFFD49E35)),
                  label: const Text('更改', style: TextStyle(color: Color(0xFFD49E35), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),
          
          // 列表主體
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: items.length,
              onReorder: (int oldIndex, int newIndex) async {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                });
                
                try {
                  for (int i = 0; i < items.length; i++) {
                    await supabase.from('itinerary_items').update({'sort_order': i}).eq('id', items[i].id);
                  }
                } catch (e) {
                  print('更新排序失敗: $e');
                }

                await _updateTimeline(dayIndex);
              },
              itemBuilder: (context, index) {
                final item = items[index];
                final bool isLast = index == items.length - 1;

                IconData transportIcon = Icons.directions_car;
                if (item.transportMode == 'transit') transportIcon = Icons.directions_bus;
                if (item.transportMode == 'walking') transportIcon = Icons.directions_walk;

                return Dismissible(
                  key: Key(item.id), 
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Color(0xFF750000), borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('確認刪除', style: TextStyle(color: Color(0xFF750000))),
                          content: Text('確定要把「${item.spotName}」從行程中移除嗎？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消', style: TextStyle(color: Colors.grey))),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF750000), foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('刪除'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) async {
                    try {
                      await supabase.from('itinerary_items').delete().eq('id', item.id);
                    } catch (e) {
                      print('雲端刪除失敗: $e');
                    }

                    setState(() {
                      items.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.spotName} 已刪除'), behavior: SnackBarBehavior.floating),
                    );
                    await _updateTimeline(dayIndex);
                  },
                  child: Column(
                    key: Key(item.id), 
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Text(item.arrivalTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A365D))),
                              const SizedBox(height: 6),
                              const CircleAvatar(radius: 8, backgroundColor: Color(0xFFD49E35)),
                              if (!isLast)
                                Container(width: 2, height: 90, color: const Color(0xFF1A365D).withOpacity(0.3)),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3))
                                ]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.spotName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('預計停留 ${item.durationMinutes} 分鐘', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                      const Spacer(),
                                      const Icon(Icons.drag_handle, color: Colors.black26),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.only(left: 65.0, top: 4.0, bottom: 12.0),
                          child: InkWell(
                            onTap: () => _showTransportModePicker(item, dayIndex),
                            borderRadius: BorderRadius.circular(20),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(transportIcon, size: 18, color: const Color(0xFF1A365D)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A365D), 
                                    borderRadius: BorderRadius.circular(20), 
                                    border: Border.all(color: const Color(0xFFBCD6F5)),
                                  ),
                                  child: Text(
                                    '預估耗時：${item.travelTimeToNextNode} 分鐘',
                                    style: const TextStyle(color: Color(0xFFE6F3FF), fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFFD49E35)), 
                              ],
                            ),
                          ),
                        ),
                    ],
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

class TravelLoadingWidget extends StatelessWidget {
  const TravelLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Lottie.network(
          'https://lottie.host/59415f90-8837-4529-b353-6c38853fd075/euMrJBHOn1.json', 
          
          width: 280,
          height: 280,
          fit: BoxFit.contain,

          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            );
          },
        ),
      ),
    );
  }
}