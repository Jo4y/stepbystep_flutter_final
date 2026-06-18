import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'trip_overview_screen.dart';
import 'currency_screen.dart';
import 'country_search_screen.dart';

// 🌟 步驟 1：升級成 StatefulWidget 以支援畫面即時更新
class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 🌟 步驟 2：準備裝行程的清單與輸入框控制器
  List<Map<String, dynamic>> _myTrips = [];
  bool _isLoading = true; // 🌟 雲端載入狀態

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  
  // 🌟 取得全域 Supabase 客戶端
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // 🌟 畫面一載入，立刻呼叫抓取雲端資料的函式
    _fetchTrips();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // ☁️ 核心魔法 1：從 Supabase 讀取行程
  Future<void> _fetchTrips() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('trips')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _myTrips = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('讀取行程失敗：$error'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // ☁️ 核心魔法 2：實作刪除行程功能 (連動雲端)
  void _deleteTrip(String id) async {
    // 為了配合 Dismissible 動畫，先在畫面上同步移除
    setState(() {
      _myTrips.removeWhere((trip) => trip['id'] == id);
    });

    // 背景執行雲端刪除
    try {
      await supabase.from('trips').delete().eq('id', id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('雲端刪除失敗：$error'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // 🌟 步驟 3：實作新增與編輯的彈出視窗 (連動雲端)
  void _showTripForm({Map<String, dynamic>? trip}) {
    final isEditing = trip != null;

    // 填入初始值 (💡 注意資料庫欄位叫做 date_range)
    _titleController.text = isEditing ? trip['title'] : '';
    _dateController.text = isEditing ? trip['date_range'] : '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFDF2), // 🌟 對話框背景：溫馨鵝黃
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? '✏️ 編輯行程' : '✨ 建立新行程',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A365D)), // 深藍標題
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Color(0xFF1A365D), fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: '行程名稱',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFD49E35).withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD49E35), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dateController,
                readOnly: true, // 🌟 關鍵 1：設為唯讀，這樣點擊時才不會跳出鍵盤擋住畫面
                style: const TextStyle(color: Color(0xFF1A365D), fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: '日期區間',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: '點擊選擇起訖日期',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.calendar_month, color: Color(0xFFD49E35)), // 土黃色 Icon
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFD49E35).withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD49E35), width: 2),
                  ),
                ),
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  final DateTime now = DateTime.now();
                  
                  final DateTimeRange? pickedRange = await showDateRangePicker(
                    context: context,
                    firstDate: now, 
                    lastDate: now.add(const Duration(days: 365 * 5)),
                    helpText: '選擇行程起訖日期',
                    cancelText: '取消',
                    confirmText: '確定',
                    saveText: '完成',
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          datePickerTheme: const DatePickerThemeData(
                            rangeSelectionBackgroundColor: Color(0xFFE6F3FF), 
                          ),
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF1A365D),         
                            onPrimary: Colors.white,            
                            surface: Color(0xFFFFFDF2),         
                            onSurface: Color(0xFF1A365D),       
                            primaryContainer: Color(0xFFE6F3FF),
                            onPrimaryContainer: Color(0xFF1A365D),
                            secondaryContainer: Color(0xFFE6F3FF),
                            onSecondaryContainer: Color(0xFF1A365D),
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFD49E35), 
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (pickedRange != null) {
                    final start = pickedRange.start;
                    final end = pickedRange.end;
                    
                    final String startStr = '${start.year}/${start.month.toString().padLeft(2, '0')}/${start.day.toString().padLeft(2, '0')}';
                    final String endStr = '${end.year}/${end.month.toString().padLeft(2, '0')}/${end.day.toString().padLeft(2, '0')}';
                    
                    _dateController.text = '$startStr - $endStr';
                  }
                },
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
                backgroundColor: const Color(0xFF1A365D), // 🌟 按鈕用深藍色
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (_titleController.text.trim().isEmpty || _dateController.text.trim().isEmpty) return;

                final title = _titleController.text.trim();
                final dateRange = _dateController.text.trim();
                final userId = supabase.auth.currentUser!.id;

                try {
                  if (isEditing) {
                    // ☁️ 雲端更新
                    final updatedData = await supabase.from('trips').update({
                      'title': title,
                      'date_range': dateRange,
                    }).eq('id', trip['id']).select().single();

                    setState(() {
                      final index = _myTrips.indexWhere((t) => t['id'] == trip['id']);
                      if (index != -1) _myTrips[index] = updatedData;
                    });
                  } else {
                    // ☁️ 雲端寫入
                    final newData = await supabase.from('trips').insert({
                      'user_id': userId,
                      'title': title,
                      'date_range': dateRange,
                    }).select().single();

                    setState(() {
                      _myTrips.insert(0, newData);
                    });
                  }
                  if (mounted) Navigator.pop(context);
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('儲存失敗：$error'), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: const Text('儲存', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName}的行程'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Builder(
              builder: (context) {
                final user = supabase.auth.currentUser;
                final userEmail = user?.email ?? '未知信箱';
                final displayName = widget.userName; // 直接用從 Auth 傳過來的名字

                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF1A365D)), // 質感深藍
                  accountName: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  accountEmail: Text(userEmail, style: const TextStyle(color: Color(0xFFD49E35))), // 土黃色點綴
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Color(0xFF1A365D)),
                  ),
                );
              }
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('首頁'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: const Text('匯率換算器'),
              onTap: () {
                Navigator.pop(context); // 先關掉 Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CurrencyScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF750000)),
              title: const Text('登出帳號', style: TextStyle(color: Color(0xFF750000))),
              onTap: () async {
                await supabase.auth.signOut();
                if (mounted) {
                  Navigator.pop(context); // 關掉 Drawer
                  Navigator.pushReplacementNamed(context, '/'); // 這裡確保有回到登入頁，可依你的路由調整
                }
              },
            ),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            color: const Color(0xFF1A365D), // 下拉箭頭顏色：質感深藍
            backgroundColor: Colors.white,
            onRefresh: _fetchTrips, // 🌟 核心：下拉時自動重新呼叫 Supabase 讀取最新行程
            child: SingleChildScrollView( 
              // 🌟 關鍵防呆：強制讓頁面隨時可滾動。就算只有 1、2 個行程，也絕對拉得動下拉更新！
              physics: const AlwaysScrollableScrollPhysics(), 
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 動態產生行程卡片
                    ..._myTrips.map((trip) => _buildDynamicTripCard(trip)).toList(),
                    
                    const SizedBox(height: 24),
                    
                    // 建立新行程按鈕
                    ElevatedButton.icon(
                      onPressed: () => _showTripForm(),
                      icon: const Icon(Icons.add_task),
                      label: const Text('建立新行程', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // 🌟 原汁原味的左滑刪除卡片！
  Widget _buildDynamicTripCard(Map<String, dynamic> trip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(trip['id']),
        direction: DismissDirection.endToStart, 
        
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFF750000)),
                    SizedBox(width: 8),
                    Text('確認刪除'),
                  ],
                ),
                content: Text('你確定要刪除「${trip['title']}」嗎？\n刪除後該行程的所有內容將無法復原喔！'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF750000),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('刪除', style: TextStyle(fontSize: 16)),
                  ),
                ],
              );
            },
          );
        },
        
        background: Container(
          decoration: BoxDecoration(
            color: Color(0xFF750000),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
        ),
        
        onDismissed: (direction) {
          _deleteTrip(trip['id']);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${trip['title']} 已刪除'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface, 
            border: Border.all(color: const Color(0xFFE6E0B8)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => TripOverviewScreen(tripData: trip))
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A365D))),
                        const SizedBox(height: 4),
                        // 💡 注意這裡：改抓 date_range 來顯示
                        Text(trip['date_range'] ?? '未定日期', style: const TextStyle(color: Colors.black54, fontSize: 14)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: Color(0xFFD49E35), size: 28),
                    onPressed: () => _showTripForm(trip: trip),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}