part of '../ocr_review_screen.dart';

extension _OcrReviewCards on _OcrReviewScreenState {
  Widget _buildStoreHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    final store = _draft.store;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(AppIcons.store, size: 24, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store.name ?? 'Estabelecimento não identificado',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(AppIcons.edit, size: 20),
                  tooltip: 'Editar estabelecimento',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => _showEditHeaderDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // CNPJ display and validation (RN-194)
            Row(
              children: [
                Text(
                  'CNPJ: ${store.cnpj ?? store.rawCnpj ?? 'Não informado'}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                if (!store.isCnpjValid &&
                    (store.cnpj != null || store.rawCnpj != null))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade400),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.qualityWarning,
                          size: 14,
                          color: Colors.orange.shade900,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CNPJ não confirmado',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Data da compra
            if (_draft.purchasedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(AppIcons.calendar, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Data: ${_formatDateTime(_draft.purchasedAt!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],

            // Chave de acesso / Nota
            if (_draft.accessKey != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(AppIcons.bill, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'NFC-e: ${_draft.accessKey}',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Widget _buildDivergenceBanner(BuildContext context) {
    if (!_draft.isDivergent()) {
      return const SizedBox.shrink();
    }

    final absDiv = _draft.absoluteDivergence?.formatPtBr() ?? 'R\$ 0,00';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.orange.shade400),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            AppIcons.qualityWarning,
            color: Colors.orange.shade900,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Divergência no valor total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Divergência de $absDiv. O sistema não ajusta automaticamente.\n'
                  'Soma dos itens: ${_draft.itemsSum.formatPtBr()} | Total lido: ${_draft.total?.formatPtBr() ?? "R\$ 0,00"}',
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowConfidenceBanner(BuildContext context) {
    if (!_draft.hasLowConfidenceItems) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(AppIcons.qualityWarning, color: Colors.amber.shade900, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Há ${_draft.lowConfidenceItemsCount} item(ns) com baixa confiança lidos do cupom. Verifique e marque os corretos.',
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Totais da Nota',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(AppIcons.edit, size: 20),
                  tooltip: 'Editar totais',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => _showEditTotalsDialog(context),
                ),
              ],
            ),
            if (_draft.subtotal != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text(_draft.subtotal!.formatPtBr()),
                ],
              ),
              const SizedBox(height: 2),
            ],
            if (_draft.discount != null && _draft.discount!.cents > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Desconto:'),
                  Text('- ${_draft.discount!.formatPtBr()}'),
                ],
              ),
              const SizedBox(height: 2),
            ],
            if (_draft.total != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total lido do cupom:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _draft.total!.formatPtBr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 2),
            ],
            const Divider(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Soma dos itens selecionados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _draft.itemsSum.formatPtBr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
