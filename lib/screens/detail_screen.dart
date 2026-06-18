import 'package:flutter/material.dart';
import '../models/place_model.dart';

class DetailScreen extends StatelessWidget {
  final Place place;
  const DetailScreen({super.key, required this.place});

  Future<void> _refreshDetails() async {
    // [05] 下拉更新功能
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(place.name)),
      // [05] 下拉更新元件
      body: RefreshIndicator(
        onRefresh: _refreshDetails,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Hero(
              tag: place.id,
              child: Image.network(place.imageUrl, width: double.infinity, height: 250, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('地址: ${place.address}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '我的旅遊備註',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // 這裡呼叫 DbHelper.insertPlace(...) 將景點存入資料庫
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已加入行程！')));
                    },
                    child: const Text('加入行程'),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}