import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🌟 記得確保有引入這行
import 'home_screen.dart'; // 記得確認檔名是否正確

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoginMode = true; 
  bool _obscurePassword = true; 
  bool _isLoading = false; // 🌟 新增：控制轉圈圈的載入狀態，防止黑客連點

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  static const Color gooseYellowBg = Color(0xFFFFFDF2);
  static const Color darkBlue = Color(0xFF1A365D);
  static const Color earthyYellow = Color(0xFFD49E35);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // 🧠 串接 Supabase 的核心大腦
  Future<void> _submitAuthForm() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    FocusScope.of(context).unfocus();

    // 🌟 開始載入，按鈕反灰
    setState(() {
      _isLoading = true;
    });

    // 🌟 獲取全域的 Supabase 客戶端實例
    final supabase = Supabase.instance.client;

    try {
      if (_isLoginMode) {
        // ----------------- 🔑 執行真實登入 -----------------
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        
        final user = supabase.auth.currentUser;
        
        // 2. 從資料中把我們註冊時存的 username 拿出來（如果剛好沒抓到，就預設叫 '探險家'）
        final String displayName = user?.userMetadata?['username'] as String? ?? '探險家';

        // 3. 帶著名字跳轉到首頁！(注意：因為 displayName 是變數，所以前面的 const 必須拿掉)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userName: displayName), // 🌟 把名字完美傳遞過去！
          ), 
        );

      } else {
        // ----------------- ✨ 執行真實註冊 -----------------
        await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {
            'username': _usernameController.text.trim(),
          },
        );

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ 註冊成功！已可登入！'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );

        setState(() {
          _isLoginMode = true;
        });
      }
    } on AuthException catch (error) {
      _showErrorDialog(error.message);
    } catch (error) {
      _showErrorDialog('發生未知錯誤，請稍後再試！');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 🎨 抽出來的防呆錯誤彈窗
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: gooseYellowBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('出錯了', style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: darkBlue)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('好的', style: TextStyle(color: earthyYellow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gooseYellowBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.travel_explore, size: 80, color: earthyYellow),
                const SizedBox(height: 12),
                const Text(
                  'STEP BY STEP',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkBlue, letterSpacing: 2),
                ),
                Text(
                  _isLoginMode ? '要去哪裡玩呢？' : '還在等什麼？',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                if (!_isLoginMode) ...[
                  TextFormField(
                    controller: _usernameController,
                    key: const ValueKey('username'),
                    enabled: !_isLoading, // 載入中時停用輸入
                    style: const TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
                    decoration: _buildInputDecoration(labelText: '暱稱', icon: Icons.person_outline),
                    validator: (val) {
                      if (val == null || val.trim().length < 2) return '暱稱至少需要 2 個字喔';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailController,
                  key: const ValueKey('email'),
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
                  decoration: _buildInputDecoration(labelText: '電子信箱 (Email)', icon: Icons.mail_outline),
                  validator: (val) {
                    if (val == null || !val.contains('@') || !val.contains('.')) return '請輸入正確的 Email 格式';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  key: const ValueKey('password'),
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
                  decoration: _buildInputDecoration(
                    labelText: '密碼', 
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: earthyYellow),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) return '為了安全，密碼長度至少需要 6 位數';
                    return null;
                  },
                ),
                
                if (_isLoginMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : () {}, 
                      child: const Text('忘記密碼？', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  ),

                const SizedBox(height: 24),

                // 🌟 按鈕區塊：加入 Loading 判斷
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _submitAuthForm, // 🌟 載入中不讓使用者點擊
                    child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            _isLoginMode ? '登入' : '註冊帳號',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),

                TextButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                      _formKey.currentState?.reset(); 
                    });
                  },
                  child: Text(
                    _isLoginMode ? '還沒有帳號 ➡️ 點此註冊' : '已經是老玩咖了？ ➡️ 點此登入',
                    style: const TextStyle(color: earthyYellow, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String labelText, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: earthyYellow),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: earthyYellow.withOpacity(0.3), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: earthyYellow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}