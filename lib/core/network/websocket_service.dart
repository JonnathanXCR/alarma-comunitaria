import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/exceptions.dart';

/// Tipos de eventos de alerta recibidos en tiempo real.
enum WsEventType { alertaNueva, unknown }

class WsEvent {
  final WsEventType type;
  final Map<String, dynamic> payload;

  const WsEvent({required this.type, required this.payload});
}

/// Servicio singleton que gestiona las suscripciones Realtime de Supabase.
/// Reemplaza el WebSocket custom anterior.
/// Llama a [connect] tras el login y a [disconnect] al cerrar sesión.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  RealtimeChannel? _channel;
  final List<void Function(WsEvent)> _listeners = [];

  bool get isConnected => _channel != null;

  /// Se suscribe a INSERTs de la tabla `alertas` filtrados por [barrioId].
  void connect({required String barrioId}) {
    disconnect();

    _channel = Supabase.instance.client
        .channel('alertas-$barrioId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alertas',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'barrio_id',
            value: barrioId,
          ),
          callback: (payload) {
            final event = WsEvent(
              type: WsEventType.alertaNueva,
              payload: payload.newRecord,
            );
            for (final listener in _listeners) {
              listener(event);
            }
          },
        )
        .subscribe((status, [error]) {
          if (error != null) {
            throw WebSocketException('Realtime error: $error');
          }
        });
  }

  /// Registra un listener que será llamado cuando llegue un evento.
  void addListener(void Function(WsEvent) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(WsEvent) listener) {
    _listeners.remove(listener);
  }

  /// Cancela la suscripción al canal actual.
  void disconnect() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
  }
}
