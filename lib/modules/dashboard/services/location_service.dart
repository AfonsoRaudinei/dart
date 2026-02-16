import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// 🌍 SERVIÇO DE LOCALIZAÇÃO GPS - STREAM REAL
/// 
/// Responsabilidades:
/// - Criar stream do sistema via Geolocator.getPositionStream()
/// - Configurar precisão e filtros
/// - Gerenciar lifecycle do stream
/// - Não conter lógica de UI
/// 
/// Performance:
/// - distanceFilter: 5m (ideal para agro)
/// - accuracy: high (quando necessário)
/// - Stream único (singleton pattern)
class LocationService {
  static LocationService? _instance;
  StreamController<LatLng>? _controller;
  StreamSubscription<Position>? _subscription;
  
  // Singleton pattern para evitar múltiplos streams
  factory LocationService() {
    _instance ??= LocationService._();
    return _instance!;
  }
  
  LocationService._();

  /// Stream de localização GPS (reativo)
  /// 
  /// Configuração otimizada para campo:
  /// - Atualiza apenas quando movimento > 5m
  /// - Precisão alta para desenho de talhão
  /// - Não rebuilda se parado
  Stream<LatLng> get locationStream {
    // Criar stream apenas uma vez
    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<LatLng>.broadcast(
        onCancel: _onCancel,
      );
      _startListening();
    }
    
    return _controller!.stream;
  }

  void _startListening() {
    // Configuração de stream do sistema
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // 5 metros (campo parado = zero rebuild)
      // timeLimit não usado (stream contínuo)
    );

    _subscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        // Converter Position para LatLng e emitir
        if (_controller != null && !_controller!.isClosed) {
          _controller!.add(LatLng(position.latitude, position.longitude));
        }
      },
      onError: (error) {
        // Emitir erro no stream (widget pode tratar)
        if (_controller != null && !_controller!.isClosed) {
          _controller!.addError(error);
        }
      },
      cancelOnError: false, // Continuar ouvindo mesmo após erro
    );
  }

  void _onCancel() {
    // Callback quando último listener cancela
    // Não fechar stream imediatamente (pode ter novos listeners)
  }

  /// Verificar se GPS está disponível (permissões + service enabled)
  Future<bool> checkAvailability() async {
    // 1. Verificar serviço
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    // 2. Verificar permissão
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Obter posição atual uma vez (sem stream)
  /// Útil para centralizar mapa na primeira vez
  Future<LatLng?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  /// Limpar recursos (opcional - stream é broadcast e se auto-gerencia)
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller?.close();
    _controller = null;
  }
}
