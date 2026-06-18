import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';

class ApiService {
  
  // 1. 抓取國家資訊 (免 Key)
  static Future<List<Country>> fetchCountries(String keyword) async {
    final url = Uri.parse('https://restcountries.com/v3.1/name/$keyword');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Country.fromJson(json)).toList();
    } else {
      throw Exception('找不到該國家，請重新輸入。');
    }
  }

  // 2. 搜尋景點 (需 Foursquare API Key)
  static Future<List<Place>> searchPlaces(String query, String location) async {
    const apiKey = 'QA4DHR3TZRKFQ4TKTBHTCTJVOOHI4MPQS05EELFJ1IQ3EE0A'; 
    
    // query: 想找什麼(如咖啡廳), near: 在哪裡(如Tokyo)
    final url = Uri.parse('https://places-api.foursquare.com/places/search?query=$query&near=$location&fields=name,location');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $apiKey',
      'Accept': 'application/json',
      'X-Places-Api-Version': '2025-02-05',
    });

    print('Foursquare 狀態碼: ${response.statusCode}');
    print('Foursquare 回應內容: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'];
      return results.map((json) => Place.fromJson(json)).toList();
    } else {
      throw Exception('無法載入景點，請檢查網路或 API Key。');
    }
  }

  // 3. 取得最新匯率 (免 Key)
  static Future<ExchangeRate> fetchExchangeRates() async {
    // 以 TWD 為基準抓取最新匯率
    final url = Uri.parse('https://open.er-api.com/v6/latest/TWD');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return ExchangeRate.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('無法獲取匯率資料。');
    }
  }

  // 4. 地址轉經緯度 (Nominatim / 免 Key)
  static Future<List<GeoLocation>> getCoordinates(String address) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$address&format=json');
    
    // Nominatim 規定必須加上 User-Agent，否則會被擋下來 (HTTP 403)
    final response = await http.get(url, headers: {
      'User-Agent': 'TravelPlannerApp_StudentProject/1.0', 
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => GeoLocation.fromJson(json)).toList();
    } else {
      throw Exception('找不到該地址的座標。');
    }
  }

  // 5. 計算兩點之間的車程時間 (OSRM API)
  // profile 可以是 driving (開車), bike (腳踏車), foot (步行)
  static Future<int> fetchTravelTime({
    required double startLat, required double startLon,
    required double endLat, required double endLon,
    String profile = 'driving',
  }) async {
    // OSRM 的格式很特別：經度,緯度;經度,緯度
    final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/$profile/$startLon,$startLat;$endLon,$endLat?overview=false'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // OSRM 回傳的 duration 單位是「秒」
        final double durationInSeconds = data['routes'][0]['duration'];
        // 把秒換算成分鐘，並四捨五入
        return (durationInSeconds / 60).round();
      }
    } catch (e) {
      print('OSRM API 錯誤: $e');
    }
    return 15; // 如果 API 壞了，預設給個 15 分鐘當作防退路
  }
}