import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/components/app_scaffold.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/extras/domain/models/checklist_item.dart';
import 'package:my_sweet_home/features/extras/presentation/checklist_providers.dart';

class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(checklistControllerProvider);

    return ValueListenableBuilder<ChecklistState>(
      valueListenable: controller,
      builder: (context, state, child) {
        return AppScaffold(
          title: 'Checklist da casa',
          actions: [
            IconButton(
              key: const Key('export_unmarked_to_shopping_list_button'),
              tooltip: 'Gerar lista de compras',
              icon: const Icon(AppIcons.sendToList),
              onPressed: state.unmarkedCount == 0
                  ? null
                  : () => _showExportToShoppingListDialog(
                      context,
                      controller,
                      state,
                    ),
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddItemDialog(context, controller, state),
            icon: const Icon(AppIcons.add),
            label: const Text('Novo item'),
          ),
          body: state.isLoading
              ? const AppLoading()
              : state.failure != null && state.items.isEmpty
              ? Center(
                  child: Text(
                    'Erro ao carregar checklist: ${state.failure}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProgressCard(context, controller, state),
                        const SizedBox(height: 16),
                        _buildCategoryFilterChips(context, controller, state),
                        const SizedBox(height: 16),
                        if (state.filteredItems.isEmpty)
                          const AppEmptyState(
                            title: 'Nenhum item no checklist.',
                            description:
                                'Adicione itens ou selecione outro cômodo.',
                            icon: AppIcons.check,
                          )
                        else
                          ..._buildItemsList(
                            context,
                            controller,
                            state.filteredItems,
                          ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    ChecklistController controller,
    ChecklistState state,
  ) {
    final theme = Theme.of(context);
    final percent = (state.progress * 100).toStringAsFixed(0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso da casa',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.markedCount} de ${state.totalCount} itens marcados',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (state.unmarkedCount > 0)
                OutlinedButton.icon(
                  key: const Key('export_unmarked_card_button'),
                  onPressed: () => _showExportToShoppingListDialog(
                    context,
                    controller,
                    state,
                  ),
                  icon: const Icon(AppIcons.sendToList, size: 16),
                  label: Text('Criar lista (${state.unmarkedCount})'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChips(
    BuildContext context,
    ChecklistController controller,
    ChecklistState state,
  ) {
    final categories = ['Todos', ...state.roomCategories];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected =
              (cat == 'Todos' && state.selectedCategory == null) ||
              cat == state.selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (bool selected) {
                if (cat == 'Todos') {
                  controller.selectCategory(null);
                } else {
                  controller.selectCategory(cat);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildItemsList(
    BuildContext context,
    ChecklistController controller,
    List<ChecklistItem> items,
  ) {
    final theme = Theme.of(context);

    return items.map((item) {
      return Card(
        key: Key('checklist_item_${item.id}'),
        margin: const EdgeInsets.only(bottom: 8.0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: ListTile(
          leading: Checkbox(
            key: Key('checkbox_${item.id}'),
            value: item.isMarked,
            onChanged: (_) => controller.toggleItem(item.id),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              decoration: item.isMarked ? TextDecoration.lineThrough : null,
              color: item.isMarked ? theme.colorScheme.outline : null,
            ),
          ),
          subtitle: Text(
            item.roomCategory,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: Key('edit_${item.id}'),
                icon: const Icon(AppIcons.edit, size: 20),
                onPressed: () => _showEditItemDialog(context, controller, item),
              ),
              IconButton(
                key: Key('delete_${item.id}'),
                icon: const Icon(AppIcons.delete, size: 20),
                onPressed: () =>
                    _showDeleteItemDialog(context, controller, item),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showAddItemDialog(
    BuildContext context,
    ChecklistController controller,
    ChecklistState state,
  ) {
    final titleController = TextEditingController();
    final initialCategory =
        state.selectedCategory ??
        (state.roomCategories.isNotEmpty
            ? state.roomCategories.first
            : 'Cozinha');
    final categoryController = TextEditingController(text: initialCategory);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar item ao checklist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('add_item_title_input'),
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Item *',
                  hintText: 'Ex: Toalha de rosto',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('add_item_category_input'),
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Cômodo / Categoria *',
                  hintText: 'Ex: Banheiro',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('confirm_add_item_button'),
              onPressed: () {
                final title = titleController.text.trim();
                final category = categoryController.text.trim();
                if (title.isNotEmpty && category.isNotEmpty) {
                  controller.addItem(roomCategory: category, title: title);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    ChecklistController controller,
    ChecklistItem item,
  ) {
    final titleController = TextEditingController(text: item.title);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar item'),
          content: TextField(
            key: const Key('edit_item_title_input'),
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Título do item *'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('confirm_edit_item_button'),
              onPressed: () {
                final newTitle = titleController.text.trim();
                if (newTitle.isNotEmpty) {
                  controller.updateItemTitle(item.id, newTitle);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteItemDialog(
    BuildContext context,
    ChecklistController controller,
    ChecklistItem item,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir item?'),
          content: Text('Deseja remover "${item.title}" do checklist?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('confirm_delete_item_button'),
              onPressed: () {
                controller.deleteItem(item.id);
                Navigator.of(context).pop();
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _showExportToShoppingListDialog(
    BuildContext context,
    ChecklistController controller,
    ChecklistState state,
  ) {
    final count = state.selectedCategory != null
        ? state.filteredUnmarkedCount
        : state.unmarkedCount;

    final listNameController = TextEditingController(
      text: state.selectedCategory != null
          ? 'Lista da Casa - ${state.selectedCategory}'
          : 'Lista da Casa (Checklist)',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Gerar lista de compras'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Criar uma lista de compras com os $count itens pendentes do checklist.',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('shopping_list_name_input'),
                controller: listNameController,
                decoration: const InputDecoration(labelText: 'Nome da lista *'),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('confirm_export_shopping_list_button'),
              onPressed: () async {
                final name = listNameController.text.trim();
                Navigator.of(dialogContext).pop();
                final result = await controller.convertUnmarkedToShoppingList(
                  listName: name,
                  onlyFiltered: state.selectedCategory != null,
                );
                if (context.mounted) {
                  if (result.isOk) {
                    final list = result.valueOrNull!;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Lista "${list.name}" criada com ${list.items.length} itens!',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Falha ao criar lista: ${result.failureOrNull}',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Gerar lista'),
            ),
          ],
        );
      },
    );
  }
}
