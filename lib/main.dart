import 'package:flutter/material.dart';

// 引入你剛剛建立的畫面 (注意路徑要對應你的資料夾結構)
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/trip_overview_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  // 執行你的 App
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://joeeixdphsoflufkcuoz.supabase.co', // 替換成你的 Supabase URL
    anonKey: 'sb_publishable_HbbpS8xkEM0hOdn8AINoVg_6NGkwZAx', // 替換成你的 Supabase 匿名金鑰
  );
  runApp(const TravelPlannerApp());
}

class TravelPlannerApp extends StatelessWidget {
  const TravelPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 定義你的專屬視覺色票
    const Color gooseYellowBg = Color(0xFFFFFDF2);  // 柔和偏白的鵝黃色 (適合當全頁背景，眼睛不疲勞)
    const Color gooseYellowCard = Color(0xFFFFF9D6); // 稍微飽和的鵝黃色 (適合當卡片、局部區塊)
    const Color khaki = Color(0xFFF0E68C);          // 柔和的卡其色 (適合當按鈕、標籤背景)
    const Color earthyYellow = Color(0xFFD49E35);    // 質感的土黃色 (適合輔助按鈕、邊框、重要標籤)

    const Color lightBlue = Color(0xFFE6F3FF);       // 清爽的淡藍色 (適合分頁標籤、小提示背景)
    const Color skyblue = Color(0xFF87CEEB);        // 明亮的天空藍 (適合強調文字、圖示)
    const Color darkBlue = Color(0xFF1A365D);        // 深邃的深藍色 (適合主按鈕、AppBar、標題文字)

    return MaterialApp(
      title: 'STEP BY STEP',
      debugShowCheckedModeBanner: false,
      
      // 🌟 全域視覺主題設定
      theme: ThemeData(
        useMaterial3: true,
        // 設定全頁背景色為舒壓的鵝黃
        scaffoldBackgroundColor: gooseYellowBg,
        
        // 設定全域色彩架構
        colorScheme: ColorScheme.light(
          primary: darkBlue,         // 主要顏色 (如預設文字、重要元件)
          secondary: earthyYellow,   // 次要顏色 (土黃)
          surface: gooseYellowCard,  // 卡片與容器的表面色
          background: gooseYellowBg,
        ),

        // 頂部導覽列 (AppBar) 主題
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF0E68C),
          foregroundColor: Colors.white, // 讓上方的標題與返回鍵自動變白色
          elevation: 0,
        ),

        // 1. 實心按鈕 (ElevatedButton) 主題：採用深藍底、白字
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkBlue,
            foregroundColor: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        // 2. 線條按鈕 (OutlinedButton) 主題：採用土黃色線條與文字
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: earthyYellow,
            side: const BorderSide(color: earthyYellow, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        // 側邊欄 (Drawer) 主題
        drawerTheme: const DrawerThemeData(
          backgroundColor: gooseYellowBg,
        ),
      ),
      home: const AuthScreen(),
    );
  }

}