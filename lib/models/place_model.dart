class Place {
  final String id;
  final String name;
  final String address;
  final String imageUrl;

  Place({required this.id, required this.name, required this.address, required this.imageUrl});

  // [02] 將 API 抓回來的 JSON 轉換成自訂型別
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['fsq_id'] ?? json['id'] ?? '', // 兼容不同 API
      name: json['name'] ?? '未知景點',
      address: json['location']?['formatted_address'] ?? '無地址資訊',
      // 假設 API 有提供圖片陣列，取第一張
      imageUrl: (json['photos'] != null && json['photos'].isNotEmpty) 
          ? json['photos'][0]['prefix'] + 'original' + json['photos'][0]['suffix']
          : 'https://via.placeholder.com/150', // 預設圖片
    );
  }
}