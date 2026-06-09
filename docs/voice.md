Doc: Flutter FE Gửi Voice Order Và Nhận Response
1. Tổng Quan Luồng
Luồng hiện tại:

Flutter FE
  -> gửi file audio + store_id + JWT
  -> Voice service /asr
  -> Voice sinh final_text
  -> Voice gọi QuanOiBE /api/voice-orders/validate
  -> QuanOiBE gọi DeepSeek parse text thành JSON
  -> QuanOiBE kiểm tra bàn/sản phẩm trong database
  -> Voice trả response cuối cùng về FE
FE chỉ cần gọi:

POST http://<VOICE_HOST>:8000/asr
Không cần gọi trực tiếp DeepSeek.

2. Endpoint FE Cần Gọi
URL
Local web/desktop:

http://localhost:8000/asr
Android emulator:

http://10.0.2.2:8000/asr
Android device thật có thể dùng:

adb reverse tcp:8000 tcp:8000
Sau đó gọi:

http://localhost:8000/asr
3. Request
Method
POST
Headers
Authorization: Bearer <accessToken>
Content-Type: multipart/form-data
Authorization là JWT đăng nhập từ QuanOiBE. Voice service sẽ forward token này sang QuanOiBE.

Form Data
Field	Type	Required	Mô tả
file	audio file	Yes	File audio người dùng nói order
store_id	int	No nhưng nên gửi	ID cửa hàng để BE kiểm tra bàn/sản phẩm
Ví dụ voice người dùng nói:

bàn 3 gọi 2 cà phê sữa và 1 trà đào
4. Flutter Example
Thêm package:

dependencies:
  http: ^1.2.2
Code gửi voice:

import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> sendVoiceOrder({
  required String voiceApiBaseUrl,
  required String audioPath,
  required int storeId,
  required String accessToken,
}) async {
  final uri = Uri.parse('$voiceApiBaseUrl/asr');

  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $accessToken'
    ..fields['store_id'] = storeId.toString()
    ..files.add(await http.MultipartFile.fromPath('file', audioPath));

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  final body = jsonDecode(response.body) as Map<String, dynamic>;

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(body['message'] ?? 'Gửi voice order thất bại');
  }

  return body;
}
Gọi hàm:

final result = await sendVoiceOrder(
  voiceApiBaseUrl: 'http://10.0.2.2:8000',
  audioPath: recordedAudioPath,
  storeId: 1,
  accessToken: accessToken,
);

print(result['text']);
print(result['orderValidation']);
5. Response Thành Công
Ví dụ:

{
  "filename": "order.wav",
  "text": "bàn 3 gọi 2 cà phê sữa",
  "orderValidation": {
    "succeeded": true,
    "message": "Order voice hợp lệ.",
    "errors": [],
    "data": {
      "rawText": "bàn 3 gọi 2 cà phê sữa",
      "table": {
        "id": 3,
        "name": "Bàn 3",
        "status": "Available"
      },
      "items": [
        {
          "productId": 10,
          "name": "Cà phê sữa",
          "quantity": 2,
          "available": true,
          "message": null
        }
      ],
      "orderJson": {
        "storeId": 1,
        "tableName": "Bàn 3",
        "items": [
          {
            "productName": "Cà phê sữa",
            "quantity": 2,
            "note": null
          }
        ],
        "missingFields": []
      }
    }
  }
}
FE nên đọc:

final text = result['text'];
final validation = result['orderValidation'];
final isValid = validation['succeeded'] == true;
Nếu isValid == true, FE có thể hiển thị preview order cho nhân viên xác nhận.

6. Response Khi Lỗi Validate
Ví dụ sản phẩm không tồn tại:

{
  "filename": "order.wav",
  "text": "bàn 3 gọi 2 trà đào",
  "orderValidation": {
    "succeeded": false,
    "message": "Order voice chưa hợp lệ.",
    "errors": [
      "Không tìm thấy sản phẩm 'trà đào'."
    ],
    "data": {
      "rawText": "bàn 3 gọi 2 trà đào",
      "table": {
        "id": 3,
        "name": "Bàn 3",
        "status": "Available"
      },
      "items": [
        {
          "productId": null,
          "name": "trà đào",
          "quantity": 2,
          "available": false,
          "message": "Sản phẩm không tồn tại."
        }
      ],
      "orderJson": {
        "storeId": 1,
        "tableName": "Bàn 3",
        "items": [
          {
            "productName": "trà đào",
            "quantity": 2,
            "note": null
          }
        ],
        "missingFields": []
      }
    }
  }
}
FE nên hiển thị:

final errors = validation['errors'] as List<dynamic>;
final message = errors.join('\n');
7. Các Trường FE Cần Quan Tâm
Root response
Field	Mô tả
filename	Tên file audio đã gửi
text	Text ASR nhận diện được
orderValidation	Kết quả QuanOiBE validate
orderValidation
Field	Mô tả
succeeded	true nếu order hợp lệ
message	Message tổng
errors	Danh sách lỗi
data	Dữ liệu order đã parse + validate
data.table
Field	Mô tả
id	ID bàn trong DB
name	Tên bàn
status	Trạng thái bàn
data.items
Field	Mô tả
productId	ID sản phẩm trong DB, có thể null nếu không tìm thấy
name	Tên sản phẩm
quantity	Số lượng
available	Sản phẩm còn bán hay không
message	Lý do lỗi riêng của item
8. Lưu Ý Quan Trọng
Hiện flow này chỉ validate order, chưa tạo đơn thật trong DB.

Nếu FE muốn tạo order thật, bước tiếp theo nên là:

FE hiển thị preview
-> nhân viên bấm xác nhận
-> FE gọi endpoint tạo order thật
Hiện BE cũng chưa ghi DB log riêng cho voice order validation. Log runtime có trên server, nhưng FE không nhận internal log.



code tham khảo có khử tiếng ồn ở trên frontend:
"
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MaterialApp(home: VoiceTestApp()));

class VoiceTestApp extends StatefulWidget {
  const VoiceTestApp({Key? key}) : super(key: key);
  @override
  State<VoiceTestApp> createState() => _VoiceTestAppState();
}

class _VoiceTestAppState extends State<VoiceTestApp> {
  final AudioRecorder _recorder = AudioRecorder();
  String _resultText = "Nhấn giữ nút màu đỏ để nói...";
  bool _isRecording = false;

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/test_voice.wav';

      // BẬT KHỬ ỒN PHẦN CỨNG TẠI ĐÂY
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          echoCancel: true,     // Khử vang
          noiseSuppress: true,  // Khử ồn nền
          autoGain: true,       // Tự kích âm nếu nói nhỏ
        ),
        path: path,
      );
      setState(() {
        _isRecording = true;
        _resultText = "Đang nghe...";
      });
    }
  }

  Future<void> _stopAndSend() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _resultText = "Đang xử lý...";
    });

    if (path != null) {
      // Do bạn đang dùng cáp (adb reverse), để 127.0.0.1 là chuẩn nhất
      var uri = Uri.parse("http://127.0.0.1:5000/api/voice");
      // var uri = Uri.parse("http://192.168.1.6:5000/api/voice");
      
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('audioFile', path));

      try {
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();
        setState(() => _resultText = responseBody);
      } catch (e) {
        setState(() => _resultText = "Lỗi kết nối: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Voice Order")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ĐÃ SỬA: Bọc Text trong Expanded và SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _resultText,
                    style: const TextStyle(fontSize: 20, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            // Nút thu âm
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0), // Đẩy nút lên một chút
              child: GestureDetector(
                onTapDown: (_) => _startRecording(),
                onTapUp: (_) => _stopAndSend(),
                onTapCancel: () => _stopAndSend(),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: _isRecording ? Colors.red : Colors.grey,
                  child: const Icon(Icons.mic, size: 50, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
"