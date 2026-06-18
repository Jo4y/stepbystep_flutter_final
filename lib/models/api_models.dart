// 1. 國家資訊模型 (REST Countries)
class Country {
  final String name;
  final String flagUrl;
  final String? currencyCode;

  Country({required this.name, required this.flagUrl, this.currencyCode});

  factory Country.fromJson(Map<String, dynamic> json) {
    // 解析出貨幣代碼
    String? parsedCurrency;
    
    // 防呆(確認 JSON)
    if (json['currencies'] != null) {
      try {
        parsedCurrency = (json['currencies'] as Map<String, dynamic>).keys.first;
      } catch (e) {
        parsedCurrency = null; 
      }
    }

    return Country(
      name: json['name']['common'] ?? '未知國家',
      flagUrl: json['flags']['png'] ?? '',
      currencyCode: parsedCurrency,
    );
  }
}

// 2. 景點資訊模型 (Foursquare)
class Place {
  final String name;
  final String address;
  final String imageUrl;

  Place({required this.name, required this.address, required this.imageUrl});

  factory Place.fromJson(Map<String, dynamic> json) {
    String img = 'https://via.placeholder.com/150'; // 預設圖片
    if (json['photos'] != null && (json['photos'] as List).isNotEmpty) {
      final photo = json['photos'][0];
      img = '${photo['prefix']}original${photo['suffix']}';
    }
    
    return Place(
      name: json['name'] ?? '未知景點',
      address: json['location']?['formatted_address'] ?? '無地址資訊',
      imageUrl: img,
    );
  }
}

// 3. 匯率模型 (ER-API)
class ExchangeRate {
  final String baseCode;
  final Map<String, dynamic> rates;

  ExchangeRate({required this.baseCode, required this.rates});

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      baseCode: json['base_code'] ?? 'TWD',
      rates: json['rates'] ?? {},
    );
  }
}

// 4. 地理座標模型 (Nominatim)
class GeoLocation {
  final String displayName;
  final double lat;
  final double lon;

  GeoLocation({required this.displayName, required this.lat, required this.lon});

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat'] ?? '0.0'),
      lon: double.parse(json['lon'] ?? '0.0'),
    );
  }
}

class ScheduleItem {
  final String spotName;     // 景點名稱 (例如：基隆廟口)
  final double lat;          // 緯度
  final double lon;          // 經度
  int durationMinutes;       // 預計停留時間 (分鐘)
  
  // 以下是透過 API 動態算出來的欄位
  String arrivalTime;        // 預計抵達時間 (例如: "14:30")
  int travelTimeToNextNode;  // 到下一個景點的車程 (分鐘)

  ScheduleItem({
    required this.spotName,
    required this.lat,
    required this.lon,
    this.durationMinutes = 60, // 預設留一小時
    this.arrivalTime = "09:00", // 預設第一站九點出發
    this.travelTimeToNextNode = 0,
  });
}