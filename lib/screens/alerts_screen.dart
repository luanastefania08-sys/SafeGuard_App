import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';

class AlertItem {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final AlertSeverity severity;
  bool isRead;

  AlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.severity,
    this.isRead = false,
  });
}

enum AlertSeverity { high, medium, low, info }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<AlertItem> _alerts = [
    AlertItem(
      id: '1',
      title: '¡Llamada de Fraude Bloqueada!',
      description:
          'Se bloqueó una llamada desde +52 55 4567-8901 que intentó robar tu información bancaria. Usaron la táctica: "Tu cuenta está bloqueada".',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      severity: AlertSeverity.high,
    ),
    AlertItem(
      id: '2',
      title: 'Número Sospechoso Detectado',
      description:
          'El número +1 800-555-0199 ha sido reportado como posible estafa de premios. Se recomienda no devolver la llamada.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      severity: AlertSeverity.medium,
    ),
    AlertItem(
      id: '3',
      title: 'Nueva Modalidad de Fraude',
      description:
          'Alerta nacional: Estafadores están suplantando al IMSS para robar datos personales. Si recibes una llamada de este tipo, cuelga inmediatamente.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      severity: AlertSeverity.medium,
      isRead: true,
    ),
    AlertItem(
      id: '4',
      title: 'Protección Activada',
      description:
          'SafeGuard Mobile está monitoreando todas tus llamadas entrantes. Tu dispositivo está protegido.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      severity: AlertSeverity.info,
      isRead: true,
    ),
    AlertItem(
      id: '5',
      title: 'Base de Datos Actualizada',
      description:
          '500 nuevos números de estafadores agregados a la lista negra. Tu protección es más fuerte.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      severity: AlertSeverity.low,
      isRead: true,
    ),
  ];

  int get _unreadCount => _alerts.where((a) => !a.isRead).length;

  void _markAllRead() {
    setState(() {
      for (final alert in _alerts) {
        alert.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alertas'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.alertRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Marcar todo'),
            ),
        ],
      ),
      body: SafeArea(
        child: _alerts.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _buildAlertCard(_alerts[index]),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textMuted,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin alertas',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todas tus alertas aparecerán aquí',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    final color = _severityColor(alert.severity);
    final icon = _severityIcon(alert.severity);

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.alertRed.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            const Icon(Icons.delete_outline_rounded, color: AppColors.alertRed),
      ),
      onDismissed: (_) {
        setState(() => _alerts.remove(alert));
      },
      child: GestureDetector(
        onTap: () {
          if (!alert.isRead) {
            setState(() => alert.isRead = true);
          }
          _showAlertDetail(alert);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: alert.isRead
                  ? AppColors.borderSubtle
                  : color.withOpacity(0.4),
              width: alert.isRead ? 1 : 1.5,
            ),
            boxShadow: alert.isRead
                ? null
                : [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: alert.isRead
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                          ),
                        ),
                        if (!alert.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: alert.isRead
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(alert.timestamp),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDetail(AlertItem alert) {
    final color = _severityColor(alert.severity);
    final icon = _severityIcon(alert.severity);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(alert.timestamp),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              alert.description,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _severityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.high:
        return AppColors.alertRed;
      case AlertSeverity.medium:
        return AppColors.warningAmber;
      case AlertSeverity.low:
        return AppColors.neonCyan;
      case AlertSeverity.info:
        return AppColors.safeGreen;
    }
  }

  IconData _severityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.high:
        return Icons.dangerous_rounded;
      case AlertSeverity.medium:
        return Icons.warning_amber_rounded;
      case AlertSeverity.low:
        return Icons.info_outline_rounded;
      case AlertSeverity.info:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} día(s)';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
