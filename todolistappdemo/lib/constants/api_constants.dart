// File: lib/constants/api_constants.dart

// 10.0.2.2 là địa chỉ IP đặc biệt để máy ảo Android
// gọi đến localhost của máy tính đang chạy nó.
//
// Nếu bạn chạy trên MÁY THẬT (cắm cáp USB), hãy thay 10.0.2.2
// bằng địa chỉ IP trong mạng LAN của máy tính (ví dụ: 192.168.1.10)

// !!! Quan trọng: Thay 5123 bằng cổng (port) của Back-end bạn tìm thấy lúc nãy
const String BASE_URL = "http://10.0.2.2:5209/api";