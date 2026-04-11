import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  bool get isConnected => socket?.connected ?? false;

  void initSocket() {
    socket = IO.io(
      'https://smartbusstop.me',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/backend/socket.io')
          .enableAutoConnect()
          .build(),
    );

    socket?.onConnect((_) {
      print('Passenger Socket Connected successfully!');
    });

    socket?.onConnectError((error) {
      print('Passenger Socket Error: $error');
    });
  }

  Future<void> connect() async => initSocket();

  void on(String event, Function(dynamic) callback) {
    socket?.on(event, callback);
  }

  void emit(String event, [dynamic data]) {
    socket?.emit(event, data);
  }

  void off(String event) {
    socket?.off(event);
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }
}
