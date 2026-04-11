import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_background.dart';

class DonationsPage extends StatelessWidget {
  const DonationsPage({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado al portapapeles'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroHeader(),
                        const SizedBox(height: 32),
                        const Text(
                          'MÉTODOS DE CONTRIBUCIÓN',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBankAccount(context),
                        const SizedBox(height: 24),
                        _buildQrCode(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          const Text(
            'DONACIONES',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.red.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.volunteer_activism_rounded,
            color: AppColors.redBright,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Apoya a tu Comunidad',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Con tu aporte voluntario, ayudas a mantener los servicios de ALUMBRA funcionando y mejoras la seguridad del barrio. Puedes apoyarnos mediante transferencia directa o escaneando nuestro código QR.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBankAccount(BuildContext context) {
    const accountName = 'Junta Directiva Alarma Comunitaria';
    const accountCedula = '0000000000';
    const bankName = 'Banco de Ejemplo';
    const accountType = 'Cuenta de Ahorros';
    const accountNumber = '1234567890';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Datos Bancarios',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDataRow(context, 'Titular', accountName),
          const Divider(color: AppColors.borderLight, height: 24),
          _buildDataRow(context, 'Cédula / RUC', accountCedula, copyable: true),
          const Divider(color: AppColors.borderLight, height: 24),
          _buildDataRow(context, 'Banco', bankName),
          const Divider(color: AppColors.borderLight, height: 24),
          _buildDataRow(context, 'Tipo de Cuenta', accountType),
          const Divider(color: AppColors.borderLight, height: 24),
          _buildDataRow(
            context,
            'Número de Cuenta',
            accountNumber,
            copyable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    String label,
    String value, {
    bool copyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (copyable)
          GestureDetector(
            onTap: () => _copyToClipboard(context, value, label),
            child: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.copy_rounded,
                color: AppColors.redLight,
                size: 18,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQrCode(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Pago Rápido QR',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: Colors.black87,
              size: 160,
            ),
            // TODO: Replace Placeholder Icon with an actual Image:
            // Image.asset('assets/images/qr_institucional.png', height: 160, width: 160),
          ),
          const SizedBox(height: 16),
          const Text(
            'Escanea este código con tu app de banca móvil paral realizar una transferencia rápida.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
