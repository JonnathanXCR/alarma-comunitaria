import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/exceptions.dart';

/// Tipos de eventos recibidos en tiempo real.
enum WsEventType {
  alertaNueva,
  alertaActualizada,
  respuestaNueva,
  respuestaActualizada,
  unknown
}

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
  RealtimeChannel? _responsesChannel;
  final List<void Function(WsEvent)> _listeners = [];

  bool get isConnected => _channel != null;

  /// Se suscribe a INSERTs y UPDATEs de la tabla `alertas` filtrados por [barrioId].
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
            _notifyListeners(event);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'alertas',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'barrio_id',
            value: barrioId,
          ),
          callback: (payload) {
            final event = WsEvent(
              type: WsEventType.alertaActualizada,
              payload: payload.newRecord,
            );
            _notifyListeners(event);
          },
        )
        .subscribe((status, [error]) {
          if (error != null) {
            throw WebSocketException('Realtime error: $error');
          }
        });
  }

  /// Se suscribe a INSERTs y UPDATEs de la tabla `respuestas_alerta` filtrados por [alertaId].
  void subscribeToAlertResponses(String alertaId) {
    unsubscribeFromAlertResponses();

    _responsesChannel = Supabase.instance.client
        .channel('respuestas-$alertaId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'respuestas_alerta',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'alerta_id',
            value: alertaId,
          ),
          callback: (payload) {
            final event = WsEvent(
              type: WsEventType.respuestaNueva,
              payload: payload.newRecord,
            );
            _notifyListeners(event);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'respuestas_alerta',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'alerta_id',
            value: alertaId,
          ),
          callback: (payload) {
            final event = WsEvent(
              type: WsEventType.respuestaActualizada,
              payload: payload.newRecord,
            );
            _notifyListeners(event);
          },
        )
        .subscribe();
  }

  void unsubscribeFromAlertResponses() {
    if (_responsesChannel != null) {
      Supabase.instance.client.removeChannel(_responsesChannel!);
      _responsesChannel = null;
    }
  }

  void _notifyListeners(WsEvent event) {
    for (final listener in _listeners) {
      listener(event);
    }
  }

  /// Registra un listener que será llamado cuando llegue un evento.
  void addListener(void Function(WsEvent) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(WsEvent) listener) {
    _listeners.remove(listener);
  }

  /// Cancela la suscripción a todos los canales actuales.
  void disconnect() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
    unsubscribeFromAlertResponses();
  }
}
