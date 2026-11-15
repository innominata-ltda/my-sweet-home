// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'My Sweet Home';

  @override
  String get productsTitle => 'Produtos';

  @override
  String get expensesTitle => 'Despesas';

  @override
  String get budgetTitle => 'Orçamento';

  @override
  String get billsTitle => 'Contas';

  @override
  String get tasksTitle => 'Tarefas';

  @override
  String get calendarTitle => 'Calendário';

  @override
  String get recipesTitle => 'Receitas';

  @override
  String get expenseQuickAddTitle => 'Nova Despesa';

  @override
  String get expenseQuickAddSave => 'Salvar';

  @override
  String expenseQuickAddError(Object error) {
    return 'Erro: $error';
  }

  @override
  String get recipeDraftNewTitle => 'Nova Receita';

  @override
  String get recipeDraftTitleLabel => 'Título';

  @override
  String get recipeDraftPrepLabel => 'Modo de Preparo';

  @override
  String get recipeDraftTimeLabel => 'Tempo (min)';

  @override
  String get recipeDraftServingsLabel => 'Porções';

  @override
  String get recipeDraftIngredientsLabel => 'Ingredientes';

  @override
  String get recipeDraftNewIngredientButton => 'Adicionar Ingrediente';

  @override
  String get recipeDraftFavoriteLabel => 'Favorito';

  @override
  String get recipeDraftTagsLabel => 'Tags';

  @override
  String get recipeDraftAddTagButton => 'Adicionar Tag';

  @override
  String get recipeDraftNewTagPlaceholder => 'Nova tag';

  @override
  String get recipeDraftNewIngredientPlaceholder => 'Novo Ingrediente';

  @override
  String get recipePreparationTitle => 'Modo de Preparo';

  @override
  String get recipePreparationBody => 'Preparo da Receita';

  @override
  String get recipeListEmpty =>
      'Nenhuma receita ainda. Comece pela que você mais faz.';

  @override
  String get recipeListCreate => 'Criar receita';

  @override
  String get recipeListError => 'Falha ao carregar receitas';

  @override
  String get recipeListRetry => 'Tentar de novo';

  @override
  String get recipeDetailError => 'Falha ao carregar receita';

  @override
  String get recipeDetailRetry => 'Tentar de novo';

  @override
  String get recipeDetailNoCost => 'Custo indisponível';

  @override
  String get recipeDetailCostExplain =>
      'Faltam preços para muitos ingredientes.';

  @override
  String get recipeDetailRegisterPrices => 'Registrar preços';

  @override
  String recipeDetailEstimatedCost(String amount) {
    return 'Custo estimado: $amount';
  }

  @override
  String recipeDetailCostMissing(int count) {
    return '$count ingrediente(s) sem preço';
  }

  @override
  String get recipeDetailTitle => 'Ficha da Receita';

  @override
  String get recipeListSearchHint => 'Buscar receitas';

  @override
  String get recipeListFavoriteFilter => 'Favoritos';

  @override
  String get recipeDetailIngredients => 'Ingredientes';

  @override
  String get recipeDetailPreparation => 'Modo de preparo';

  @override
  String recipeDetailTime(int time) {
    return '$time min';
  }

  @override
  String recipeDetailServings(int servings) {
    return '$servings porções';
  }

  @override
  String get taskQuickAddTitle => 'Nova Tarefa';

  @override
  String get taskQuickAddSave => 'Salvar';

  @override
  String taskQuickAddError(Object error) {
    return 'Erro: $error';
  }

  @override
  String get taskQuickAddPlaceholder => 'Título da tarefa';

  @override
  String get billsEmpty =>
      'Cadastre suas contas fixas e nunca mais pague multa.';

  @override
  String get billsCreate => 'Cadastrar conta';

  @override
  String get billsAllPaid => 'Nada a pagar este mês';

  @override
  String get billsError => 'Falha ao carregar';

  @override
  String get billsRetry => 'Tentar de novo';

  @override
  String get billsNotificationWarning => 'As notificações não estão chegando?';

  @override
  String get billsNotificationWarningExplanation =>
      'Seu celular pode estar bloqueando os avisos do My Sweet Home para economizar bateria. Você pode desligar essa economia nas configurações do aparelho para garantir que vai ser lembrado no dia do vencimento. Mesmo se a notificação falhar, os vencimentos continuam visíveis aqui na tela de contas.';

  @override
  String get billsNotificationAllow => 'Resolver';

  @override
  String get billsBatteryOptimizationDialogTitle => 'Avisos importantes';

  @override
  String get billsStatusOverdue => 'Atrasado';

  @override
  String get billsStatusPaid => 'Pago';

  @override
  String get billsStatusPending => 'Pendente';

  @override
  String billsMarkAsPaid(String billName) {
    return 'Marcar $billName como pago';
  }

  @override
  String get productSearchHint => 'Buscar produtos';

  @override
  String get productEmptyState => 'Nenhum produto encontrado.';

  @override
  String get productNew => 'Novo Produto';

  @override
  String get productName => 'Nome';

  @override
  String get productCategory => 'Categoria';

  @override
  String get productUnit => 'Unidade';

  @override
  String get productAliases => 'Apelidos e variações';

  @override
  String get productAddAlias => 'Adicionar apelido';

  @override
  String get productAliasPlaceholder => 'Novo apelido';

  @override
  String get productAliasesEmpty => 'Nenhum apelido cadastrado.';

  @override
  String get productError => 'Erro ao carregar produtos.';

  @override
  String get productDetailError => 'Erro ao carregar detalhes.';

  @override
  String get productRemoveAliasConfirm => 'Remover apelido?';

  @override
  String productRemoveAliasA11y(String alias) {
    return 'Remover apelido $alias';
  }

  @override
  String productSuggestionTitle(String productName) {
    return 'Isso é o mesmo que $productName?';
  }

  @override
  String productSuggestionYes(String alias, String productName) {
    return 'Sim, $alias é o mesmo que $productName';
  }

  @override
  String get productSuggestionNo => 'Não, são coisas diferentes';

  @override
  String get productSave => 'Salvar';

  @override
  String get productCancel => 'Cancelar';

  @override
  String get expensesEmpty => 'Nenhuma despesa este mês.';

  @override
  String get expensesError => 'Erro ao carregar o resumo de despesas.';

  @override
  String get expensesRetry => 'Tentar novamente';

  @override
  String get expensesChartAltText =>
      'Gráfico circular mostrando o uso do orçamento.';

  @override
  String expensesTotal(String amount) {
    return 'Realizado: $amount';
  }

  @override
  String expensesBudgetSet(String amount) {
    return 'Orçamento: $amount';
  }

  @override
  String expensesRemaining(String amount) {
    return 'Restante: $amount';
  }

  @override
  String expensesOverBudget(String amount) {
    return 'Estourou: $amount';
  }

  @override
  String get billHistoryTitle => 'Histórico de pagamentos';

  @override
  String get expenseDeleted => 'Despesa excluída';

  @override
  String get billHistoryEmpty => 'Nenhum pagamento registrado para esta conta.';

  @override
  String get billHistoryError => 'Falha ao carregar o histórico.';

  @override
  String get billHistoryRetry => 'Tentar de novo';

  @override
  String billHistoryDueOn(String date) {
    return 'Vencimento: $date';
  }

  @override
  String billHistoryPaidOn(String date) {
    return 'Pago em: $date';
  }

  @override
  String get expensesEmptyCallToAction =>
      'Nenhuma despesa este mês. Que tal lançar a primeira?';

  @override
  String get expensesLaunchFirst => 'lançar despesa';

  @override
  String get expensesNoBudgetInvite => 'convite para definir orçamento';

  @override
  String get expensesSetBudget => 'definir orçamento';

  @override
  String get expensesForecastNoHistory =>
      'Ainda não há histórico suficiente para prever o fechamento do mês.';

  @override
  String get expensesForecastExplanation =>
      'A previsão considera seus gastos atuais, contas fixas pendentes e a média de gastos dos últimos meses.';

  @override
  String get expensesForecastTitle => 'Previsão de fechamento';

  @override
  String expensesForecastAmount(String amount) {
    return 'Previsão: $amount';
  }

  @override
  String expensesChartCategoryAlt(
    String category,
    String amount,
    String percent,
  ) {
    return '$category: $amount ($percent%)';
  }

  @override
  String get expensesByCategoryTitle => 'Despesas por categoria';

  @override
  String get billsNotificationPermissionDeniedWarning =>
      'Sem permissão, você não será avisado antes do vencimento e pode pagar multa.';

  @override
  String get billsNotificationPermissionDeniedSettings => 'Ir para Ajustes';

  @override
  String get billsNotificationPermissionDeniedDismiss => 'Entendi';

  @override
  String get shoppingListsTitle => 'Listas de compras';

  @override
  String get shoppingListEmpty => 'Lista vazia. Adicione o que falta em casa.';

  @override
  String get shoppingListAllDone => 'Tudo comprado 🎉';

  @override
  String get shoppingListRegisterPurchase => 'registrar a compra';

  @override
  String shoppingListMarkAsBought(String item) {
    return 'Marcar $item como comprado';
  }

  @override
  String shoppingListUnmarkAsBought(String item) {
    return 'Desmarcar $item como comprado';
  }

  @override
  String get shoppingListAddItemLabel => 'Adicionar item';

  @override
  String get shoppingListAddItemHint => 'Ex: 2kg de arroz';

  @override
  String get shoppingListUndo => 'Desfazer';

  @override
  String shoppingListEstimateWithUnknowns(String total, int count) {
    return '$total + $count itens sem preço';
  }

  @override
  String shoppingListEstimateWithOneUnknown(String total) {
    return '$total + 1 item sem preço';
  }

  @override
  String shoppingListEstimateExact(String total) {
    return 'Estimativa: $total';
  }

  @override
  String shoppingListItemQuantity(String quantity, String unit) {
    return 'Qtd: $quantity $unit';
  }

  @override
  String get shoppingListError => 'Falha ao carregar lista de compras';

  @override
  String get shoppingListRetry => 'Tentar de novo';

  @override
  String get purchasesTitle => 'Compras';

  @override
  String get purchaseNew => 'Nova Compra';

  @override
  String get pricesTitle => 'Histórico de Preços';

  @override
  String get pricesEmpty =>
      'Ainda sem preços. Registre uma compra para começar.';

  @override
  String get pricesFewData => 'poucas observações para concluir';

  @override
  String get pricesLoadError => 'falha ao carregar histórico';

  @override
  String get pricesRetry => 'tentar de novo';

  @override
  String get pricesRankingTitle => 'Ranking por estabelecimento';

  @override
  String get storeTitle => 'Estabelecimento';

  @override
  String cheapestStore(String store) {
    return 'Mais barato no $store';
  }

  @override
  String get notEnoughData => 'pouca informação';

  @override
  String priceAverage(String amount) {
    return 'Costuma custar $amount';
  }

  @override
  String priceAverageObservations(int count) {
    return 'baseado em $count observações';
  }

  @override
  String get priceVariationAlert => 'Alerta de variação';

  @override
  String priceVariationUp(String percent) {
    return 'Alta de $percent% sobre a média de 30 dias';
  }

  @override
  String priceVariationDown(String percent) {
    return 'Baixa de $percent% sobre a média de 30 dias';
  }

  @override
  String purchaseTotalMismatch(String amount) {
    return 'Divergência de $amount. O sistema não ajusta automaticamente.';
  }

  @override
  String get purchaseInvalidCnpj => 'CNPJ inválido. Digite um CNPJ válido.';

  @override
  String purchaseChartA11y(
    String amount,
    String minAmount,
    String store,
    String date,
  ) {
    return '$amount em média nos últimos 30 dias, menor valor $minAmount no $store em $date';
  }

  @override
  String get ocrTitle => 'Leitor de Nota Fiscal';

  @override
  String get ocrCameraPermissionDenied => 'Permissão de câmera negada';

  @override
  String get ocrCameraPermissionSettings => 'Ir para Ajustes';

  @override
  String get ocrFlashOn => 'Ligar flash';

  @override
  String get ocrFlashOff => 'Desligar flash';

  @override
  String get ocrReviewTitle => 'Revisão';

  @override
  String get ocrReviewSave => 'Salvar';

  @override
  String get ocrReviewAdd => 'Adicionar';

  @override
  String get ocrReviewDelete => 'Apagar';

  @override
  String get ocrTotalMismatch => 'Soma dos itens difere do total';

  @override
  String get ocrItemLowConfidence => 'Confira este item';

  @override
  String get ocrGalleryOption => 'Galeria';

  @override
  String get purchaseDate => 'Data da Compra';

  @override
  String get purchaseItemsSection => 'Itens';

  @override
  String get purchaseAddItem => 'Adicionar Item';

  @override
  String get purchaseNoStores =>
      'Nenhum estabelecimento cadastrado. (Adicione um na tela de lojas)';

  @override
  String purchaseLoadStoresError(String error) {
    return 'Erro ao carregar lojas: $error';
  }

  @override
  String get purchaseProductLabel => 'Produto';

  @override
  String get purchaseLoadProductsError => 'Erro ao carregar produtos';

  @override
  String get purchaseQuantityLabel => 'Quantidade';

  @override
  String get purchaseTotalPriceLabel => 'Preço Total';

  @override
  String get purchaseDiscountLabel => 'Desconto Total';

  @override
  String get purchaseDeclaredTotalLabel => 'Total Declarado (Cupom)';

  @override
  String purchaseItemsSum(String amount) {
    return 'Soma dos Itens: $amount';
  }

  @override
  String get purchaseFormError => 'Preencha todos os campos corretamente';

  @override
  String get priceTrendUp => 'Alta de preço no período';

  @override
  String get priceTrendDown => 'Baixa de preço no período';

  @override
  String get priceHistoryTitle => 'Histórico de preços';

  @override
  String get checklistTitle => 'Checklist da casa';

  @override
  String get checklistEmpty => 'Nenhum item no checklist.';

  @override
  String get checklistCategoryAll => 'Todos os cômodos';

  @override
  String get checklistSendToShoppingList => 'Enviar para lista de compras';

  @override
  String get stockTitle => 'Estoque doméstico';

  @override
  String get stockEmpty => 'Nenhum produto no estoque.';

  @override
  String get stockLowAlert => 'Está acabando';

  @override
  String get stockEstimateNotice => 'Estimativa de consumo';

  @override
  String get searchGlobalTitle => 'Busca';

  @override
  String get searchGlobalHint => 'Buscar em todo o app...';

  @override
  String get searchGlobalNoResults => 'Nenhum resultado encontrado.';

  @override
  String get economyTitle => 'Modo Economia';

  @override
  String get economyMetaTitle => 'Meta de economia';

  @override
  String get economyProgressLabel => 'Progresso da meta';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get backupTitle => 'Backup e Exportação';

  @override
  String get backupExportSection => 'Exportar Dados';

  @override
  String get backupImportSection => 'Importar Dados';

  @override
  String get backupClearAllSection => 'Apagar Tudo';

  @override
  String get backupCloudSection => 'Backup em Nuvem';

  @override
  String get mascotDefaultName => 'Momo';

  @override
  String get mascotCustomizeTitle => 'Personalizar Mascote';

  @override
  String get mascotCustomizeSave => 'Salvar e aplicar';

  @override
  String get mascotCustomizeCancel => 'Cancelar';

  @override
  String get mascotCustomizeRetry => 'Tentar de novo';

  @override
  String get mascotCustomizeNameLabel => 'Nome da mascote';

  @override
  String get mascotCustomizeNameHint => 'Ex: Momo';

  @override
  String get mascotCustomizePreview => 'Pré-visualização';

  @override
  String get mascotCustomizeAnimalSection => 'Animal';

  @override
  String get mascotCustomizePaletteSection => 'Paleta de cores';

  @override
  String get mascotCustomizeAccessorySection => 'Acessório';

  @override
  String get mascotAnimalCat => 'Gato';

  @override
  String get mascotAnimalDog => 'Cachorro';

  @override
  String get mascotAnimalBunny => 'Coelho';

  @override
  String get mascotPaletteRose => 'Rose';

  @override
  String get mascotPaletteLavender => 'Lavender';

  @override
  String get mascotPaletteMint => 'Mint';

  @override
  String get mascotAccessoryNone => 'Nenhum';

  @override
  String get mascotAccessoryBow => 'Lacinho';

  @override
  String get mascotAccessoryCollar => 'Coleira';

  @override
  String get mascotAccessoryScarf => 'Lenço';

  @override
  String get mascotSaveSuccess => 'Personalização salva com carinho!';

  @override
  String get mascotSaveError =>
      'Erro ao salvar a personalização. Tente de novo.';

  @override
  String get settingsMascotOption => 'Personalizar Momo';

  @override
  String get settingsMascotSubtitle =>
      'Escolha o animal, cores e acessórios da sua companheira';

  @override
  String get settingsTutorialOption => 'Ver tutorial com a Momo';

  @override
  String get settingsTutorialSubtitle =>
      'Relembre o funcionamento do app com a mascote';

  @override
  String get onboardingSkip => 'Pular introdução';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingStart => 'Começar';

  @override
  String get onboardingStep1Title => 'Oi! Eu sou a Momo 💕';

  @override
  String get onboardingStep1Description =>
      'Estou aqui para cuidar do seu cantinho com você e tornar tudo mais leve!';

  @override
  String get onboardingStep2Title => 'Aqui a gente cuida do dinheirinho juntas';

  @override
  String get onboardingStep2Description =>
      'Acompanhe seus gastos, registre comprinhas e mantenha o orçamento sem sustos no fim do mês.';

  @override
  String get onboardingStep3Title => 'E também das comprinhas!';

  @override
  String get onboardingStep3Description =>
      'Monte sua listinha de compras no mercado e escaneie a nota fiscal num piscar de olhos.';

  @override
  String get onboardingStep4Title => 'Não esquece das tarefinhas do dia';

  @override
  String get onboardingStep4Description =>
      'Organize tarefas de limpeza, cuidados com a casa e rotinas para manter seu lar acolhedor.';

  @override
  String get onboardingStep5Title =>
      'Eu te aviso quando algo precisa de atenção';

  @override
  String get onboardingStep5Description =>
      'Fique tranquila com os lembretes de contas a vencer para nunca mais pagar juros ou multas.';

  @override
  String get onboardingStep6Title =>
      'Pode personalizar meu visual quando quiser!';

  @override
  String get onboardingStep6Description =>
      'Você pode trocar meu animalzinho, colocar acessórios e escolher as cores que mais combinam com você.';

  @override
  String get onboardingCustomizePrompt => 'Quer personalizar meu visual agora?';

  @override
  String get onboardingCustomizeButton => 'Personalizar agora';

  @override
  String get dashboardMonthBalanceTitle => 'Seu dinheirinho este mês';

  @override
  String get dashboardDueBillsTitle => 'Contas que precisam de carinho';

  @override
  String get dashboardTodayTasksTitle => 'Tarefinhas do dia';

  @override
  String get momoGreeting => 'Oi! Eu sou a Momo 💕';

  @override
  String get momoShoppingAllBought =>
      'Tudo comprado! Quer que eu anote essa comprinha?';

  @override
  String get momoDayOff => 'Hoje pode ser um dia de folga ☕';

  @override
  String get momoEmptyExpenses =>
      'Momo está pensativa — nenhuma despesa registrada ainda';

  @override
  String get momoEmptyShoppingList =>
      'Momo pronta para as compras — nenhuma listinha criada ainda';

  @override
  String get momoEmptyShoppingListCompleted =>
      'Momo está feliz porque você completou a lista';

  @override
  String get momoEmptyTasks => 'Momo relaxada — nenhuma tarefinha para hoje';

  @override
  String get celebrationShoppingCompletedTitle => 'Parabéns!';

  @override
  String get celebrationShoppingCompletedMessage =>
      'Tudo comprado! Sua lista está completa 💕';

  @override
  String get celebrationTasksCompletedTitle => 'Tudo pronto!';

  @override
  String get celebrationTasksCompletedMessage =>
      'Você concluiu todas as tarefinhas do dia! Descanse bastante 💕';

  @override
  String get mascotSemanticsNeutral => 'Momo está presente acompanhando você';

  @override
  String get mascotSemanticsHappy => 'Momo está feliz';

  @override
  String get mascotSemanticsWorried => 'Momo está preocupada com as continhas';

  @override
  String get mascotSemanticsSleepy => 'Momo está com soninho';

  @override
  String get mascotSemanticsPointing =>
      'Momo está apontando uma dica importante';

  @override
  String get mascotSemanticsWaving =>
      'Momo está acenando com carinho para você';

  @override
  String get mascotSemanticsThinking => 'Momo está pensativa';

  @override
  String get mascotSemanticsRelaxed => 'Momo está relaxada e tranquila';

  @override
  String get mascotSemanticsShopping => 'Momo está pronta para as compras';

  @override
  String get mascotSemanticsBudget => 'Momo está de olho no orçamento do mês';

  @override
  String get mascotSemanticsPlaceholder => 'Ilustração da mascote Momo';

  @override
  String get taskPresetsTitle => 'Sugestões para a casa';

  @override
  String get taskPresetsSubtitle =>
      'Ideias de tarefas comuns com frequências recomendadas';

  @override
  String get taskPresetsSearchHint => 'Buscar sugestões...';

  @override
  String taskPresetsEmptySearch(String query) {
    return 'Nenhuma sugestão encontrada para \"$query\"';
  }

  @override
  String get taskPresetsCustomTaskCta => 'Criar tarefa personalizada';

  @override
  String get taskPresetsAreaKitchen => 'Cozinha';

  @override
  String get taskPresetsAreaBathroom => 'Banheiro';

  @override
  String get taskPresetsAreaBedroom => 'Quarto';

  @override
  String get taskPresetsAreaLaundry => 'Roupas';

  @override
  String get taskPresetsAreaGeneralCleaning => 'Limpeza geral';

  @override
  String get taskPresetsAreaShopping => 'Compras';

  @override
  String get taskPresetsAlreadyInRoutine => 'Já na sua rotina';

  @override
  String get taskPresetsDuplicateTitle => 'Tarefa já existe na rotina';

  @override
  String get taskPresetsDuplicateMessage =>
      'Você já tem uma tarefa ativa para esta predefinição. Deseja adicionar outra mesmo assim?';

  @override
  String get taskPresetsDuplicateConfirm => 'Adicionar mesmo assim';

  @override
  String get taskPresetsDuplicateCancel => 'Cancelar';

  @override
  String taskPresetsAddSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarefas',
      one: '1 tarefa',
    );
    return 'Adicionar $_temp0';
  }

  @override
  String taskPresetsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionadas',
      one: '1 selecionada',
    );
    return '$_temp0';
  }

  @override
  String get taskPresetsBatchTitle => 'Datas de início';

  @override
  String get taskPresetsBatchConfirm => 'Confirmar rotina';

  @override
  String get taskPresetsBatchUndo => 'Desfazer';

  @override
  String taskPresetsBatchSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarefas adicionadas!',
      one: '1 tarefa adicionada!',
    );
    return '$_temp0';
  }

  @override
  String taskPresetsBatchStartDateLabel(String task) {
    return 'Início de $task';
  }

  @override
  String get taskPresetsEmptyStatePrompt =>
      'Que tal ver sugestões para a rotina da sua casa?';

  @override
  String get taskPresetsEmptyStateButton => 'Ver sugestões para a casa';

  @override
  String get onboardingRoutineTitle => 'Monte sua rotina da casa';

  @override
  String get onboardingRoutineDescription =>
      'Escolha tarefas comuns para começar sua rotina sem complicação. Você pode mudar tudo depois!';

  @override
  String get onboardingRoutineSkip => 'Pular este passo';

  @override
  String get householdTitle => 'Casa compartilhada';

  @override
  String get householdSubtitle => 'Sincronize tarefas e finanças em rede local';

  @override
  String get householdEmptyTitle => 'Compartilhe a sua casa';

  @override
  String get householdEmptyDescription =>
      'Sincronize com quem mora com você sem intermediários, sem criar conta e com segurança de ponta a ponta na rede local.';

  @override
  String get householdCreateButton => 'Criar casa';

  @override
  String get householdJoinButton => 'Entrar numa casa';

  @override
  String get householdSyncNowButton => 'Sincronizar agora';

  @override
  String get householdGenerateBundleButton => 'Gerar pacote';

  @override
  String get householdInviteButton => 'Convidar aparelho';

  @override
  String get householdOnlyThisDevice => 'Mudanças só neste aparelho';

  @override
  String get householdAllSynced => 'Tudo sincronizado';

  @override
  String get householdSyncing => 'Sincronizando...';

  @override
  String householdLastSync(String time) {
    return 'Última sincronização: $time';
  }

  @override
  String get householdMembersTitle => 'Aparelhos na casa';

  @override
  String get householdAreasTitle => 'Áreas compartilhadas';

  @override
  String get householdAreaHome => 'Casa (Tarefas, Estoque, Receitas)';

  @override
  String get householdAreaFinance => 'Finanças (Despesas, Contas, Preços)';

  @override
  String get householdPairingTitle => 'Conectar aparelho';

  @override
  String get householdPairingScanPrompt =>
      'Aponte a câmera para o QR code no outro aparelho';

  @override
  String get householdPairingShowPrompt =>
      'Mostre este QR code no aparelho que deseja conectar';

  @override
  String householdPairingCodeLabel(String code) {
    return 'Código de confirmação: $code';
  }

  @override
  String get householdLeaveButton => 'Sair da casa';

  @override
  String get householdLeaveKeepData => 'Manter uma cópia local';

  @override
  String get householdLeaveWipeData => 'Apagar dados compartilhados';

  @override
  String get householdRemoveMemberTitle => 'Remover aparelho';

  @override
  String get householdRemoveMemberConfirm => 'Remover';

  @override
  String get householdRemoveMemberWarning =>
      'O aparelho removido perderá o acesso e as futuras alterações não serão mais sincronizadas com ele.';

  @override
  String get householdErrorIncompatibleProtocol =>
      'Aparelho usa versão incompatível do protocolo de sincronização.';

  @override
  String get householdErrorInviteExpired =>
      'O convite expirou. Gere um novo convite para parear.';

  @override
  String get householdErrorNoNetwork =>
      'Nenhum aparelho encontrado na rede local. Verifique se ambos estão no mesmo Wi-Fi.';

  @override
  String get customizeDashboardTitle => 'Personalizar início';

  @override
  String get customizeDashboardAction => 'Personalizar início';

  @override
  String get customizeDashboardAddCards => 'Adicionar ao painel';

  @override
  String get customizeDashboardEmptyTitle => 'Nenhum item visível no painel';

  @override
  String get customizeDashboardEmptyAction => 'Adicionar itens ao painel';

  @override
  String get customizeDashboardRestoreDefault => 'Restaurar padrão';

  @override
  String get customizeDashboardMoveUp => 'Mover para cima';

  @override
  String get customizeDashboardMoveDown => 'Mover para baixo';

  @override
  String get customizeDashboardHide => 'Ocultar';

  @override
  String get customizeDashboardAdd => 'Adicionar';

  @override
  String get dashboardCardMascotGreeting => 'Saudação da Momo';

  @override
  String get dashboardCardMonthBalance => 'Saldo do Mês';

  @override
  String get dashboardCardDueBills => 'Contas a Vencer';

  @override
  String get dashboardCardTodayTasks => 'Tarefas de Hoje';

  @override
  String get dashboardCardShoppingList => 'Lista de Compras';

  @override
  String get dashboardCardStockAlert => 'Estoque Doméstico';

  @override
  String get dashboardCardFirstHomeChecklist => 'Checklist da Primeira Casa';

  @override
  String get dashboardCardEconomyGoal => 'Modo Economia';

  @override
  String get dashboardCardFavoriteRecipes => 'Receitas Favoritas';

  @override
  String get settingsRetentionNotificationsTitle => 'Lembretes gentis da Momo';

  @override
  String get settingsRetentionNotificationsSubtitle =>
      'Avisar em intervalos espaçados se você ficar dias sem abrir o app';

  @override
  String get retentionNotificationTitle => 'A Momo sentiu sua falta!';

  @override
  String retentionNotificationBody(int days) {
    return 'Faz $days dias que não organizamos a casa juntos. Que tal conferir suas tarefas e contas?';
  }

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonDone => 'Concluído';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get navHome => 'Início';

  @override
  String get navShopping => 'Compras';

  @override
  String get navTasks => 'Tarefas';

  @override
  String get navBills => 'Contas';

  @override
  String get navExpenses => 'Despesas';

  @override
  String get navScanReceipt => 'Escanear Nota Fiscal';

  @override
  String get pageNotFound => 'Página não encontrada';

  @override
  String get dashboardSearchTooltip => 'Busca global';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get dashboardEmptyDescription =>
      'Personalize seu painel inicial adicionando os módulos que desejar.';

  @override
  String mascotGreetingNamed(String name) {
    return 'Oi! Eu sou a $name 💕';
  }

  @override
  String get mascotGreetingSubtitleDefault =>
      'Estou aqui para cuidar do seu cantinho com você!';

  @override
  String get mascotGreetingSubtitleOverBudget =>
      'Atenção com as continhas este mês! Mas estamos juntas nisso 💕';

  @override
  String get mascotGreetingSubtitleNearBudget =>
      'Quase no limite do orçamento! Vamos cuidar com carinho dos gastos 💕';

  @override
  String mascotGreetingSemantics(String name, String title, String subtitle) {
    return 'Mascote $name: $title. $subtitle';
  }

  @override
  String get recoveryResetConfirmTitle => 'Recomeçar do zero?';

  @override
  String get recoveryResetConfirmBody =>
      'Todos os dados locais existentes serão permanentemente apagados.';

  @override
  String get recoveryResetFinalTitle => 'Confirmação definitiva';

  @override
  String get recoveryResetFinalBody =>
      'Esta ação é irreversível. Tem certeza absoluta que deseja apagar todos os dados e recomeçar?';

  @override
  String get recoveryResetFinalConfirm => 'Confirmar e apagar';

  @override
  String get recoveryKeyUnavailableAppBar => 'Chave do banco inacessível';

  @override
  String get recoverySecurityFailureAppBar => 'Falha na segurança do banco';

  @override
  String get recoveryKeyUnavailableTitle => 'Chave de segurança inacessível';

  @override
  String get recoveryConversionFailedTitle => 'Conversão de segurança falhou';

  @override
  String get recoveryKeyUnavailableBody =>
      'Não foi possível acessar a chave de segurança no dispositivo. Para proteger seus dados, nenhum banco vazio foi criado.\n\nVocê pode restaurar um backup anterior ou recomeçar do zero.';

  @override
  String get recoveryConversionFailedBody =>
      'A conversão do banco existente para o formato cifrado falhou, mas seus dados continuam intactos no banco original.\n\nRecomendamos exportar um backup antes de prosseguir.';

  @override
  String get recoveryImportBackup => 'Importar backup';

  @override
  String get recoveryStartFromScratch => 'Recomeçar do zero';

  @override
  String get recoveryExportBackup => 'Exportar backup';

  @override
  String get recoveryContinuePlaintextSemantics =>
      'Continuar no formato original';

  @override
  String get celebrationDefaultTitle => 'Parabéns!';

  @override
  String get celebrationDefaultMessage => 'Você concluiu tudo com sucesso! 💕';

  @override
  String get celebrationMascotSemantics =>
      'Momo alegre celebrando sua conquista';

  @override
  String get mascotNameFieldSemantics => 'Campo para alterar o nome da mascote';

  @override
  String mascotNameBlankHelper(String name) {
    return 'Se deixar em branco, usaremos \"$name\" 💕';
  }

  @override
  String mascotPreviewSemantics(String name, String palette) {
    return 'Pré-visualização da mascote $name na paleta $palette';
  }

  @override
  String get splashInitError =>
      'Ops! Ocorreu uma instabilidade na inicialização.';

  @override
  String get onboardingOpenSourceBadge =>
      'Código aberto, sem anúncios e com dados salvos apenas no seu aparelho';

  @override
  String get onboardingFirstHomeTitle => 'Está montando sua casa nova?';

  @override
  String get onboardingFirstHomeDescription =>
      'Se você acabou de se mudar ou está organizando seu cantinho pela primeira vez, posso ativar um checklist especial com itens essenciais no seu início!';

  @override
  String get onboardingFirstHomeEnable =>
      'Sim, ativar checklist da primeira casa';

  @override
  String get onboardingFirstHomeSkip => 'Já tenho tudo / Pular';

  @override
  String onboardingPageIndicatorSemantics(int current, int total) {
    return 'Página $current de $total';
  }

  @override
  String get aboutTitle => 'Sobre o My Sweet Home';

  @override
  String get aboutVersionLabel => 'Versão ';

  @override
  String get aboutUpToDate => 'Você já está na versão mais recente.';

  @override
  String get aboutUpdateCheckFailed =>
      'Não foi possível verificar atualizações no momento.';

  @override
  String get aboutLicensesTitle => 'Licenças de código aberto';

  @override
  String get aboutLicensesSubtitle => 'Licenças de pacotes e dependências';

  @override
  String get aboutAttributionsTitle => 'Atribuições';

  @override
  String get aboutAttributionsSubtitle => 'Atribuições de ativos e terceiros';

  @override
  String get aboutGithubTitle => 'Código-fonte no GitHub';

  @override
  String get aboutGithubCopied =>
      'Link do GitHub copiado para a área de transferência.';

  @override
  String get aboutDocsTitle => 'Documentação e privacidade';

  @override
  String get aboutDocsCopied =>
      'Link da documentação copiado para a área de transferência.';

  @override
  String get aboutCheckUpdatesTitle => 'Verificar atualizações';

  @override
  String get aboutCheckUpdatesSubtitle =>
      'Buscar novas versões na loja de aplicativos';

  @override
  String get aboutCheckUpdatesPlayStoreOnly =>
      'Disponível apenas para instalações feitas pela Google Play';

  @override
  String aboutAttributionsError(String error) {
    return 'Erro ao carregar atribuições: $error';
  }

  @override
  String get settingsSectionAppearance => 'Aparência e Experiência';

  @override
  String get settingsMascotShortSubtitle => 'Animal, paleta de cor e acessório';

  @override
  String get settingsVisualEffectsTitle => 'Efeitos visuais e partículas';

  @override
  String get settingsVisualEffectsSubtitle =>
      'Partículas, confetes e animações contínuas';

  @override
  String get settingsLanguageTitle => 'Idioma do aplicativo';

  @override
  String get settingsLanguageSystem => 'Automático (sistema)';

  @override
  String get settingsLanguageSystemSubtitle =>
      'Segue o idioma configurado no aparelho';

  @override
  String get settingsOcrFormatTitle => 'Modelo de nota fiscal (OCR)';

  @override
  String get settingsOcrFormatAuto => 'Automático (melhor modelo)';

  @override
  String get settingsOcrFormatAutoSubtitle =>
      'Seleciona automaticamente o formato com maior pontuação';

  @override
  String get settingsSectionModules => 'Sua Casa e Módulos';

  @override
  String get settingsRecipesSubtitle => 'Livro de receitas e ingredientes';

  @override
  String get settingsStockTitle => 'Estoque';

  @override
  String get settingsStockSubtitle => 'Despensa e itens essenciais';

  @override
  String get settingsEconomySubtitle => 'Dicas e metas de economia';

  @override
  String get settingsChecklistTitle => 'Checklist da 1ª Casa';

  @override
  String get settingsChecklistSubtitle => 'Itens essenciais para a casa nova';

  @override
  String get settingsSuggestionsTitle => 'Sugestões de Manutenção';

  @override
  String get settingsSuggestionsSubtitle =>
      'Catálogo de tarefas sugeridas para o lar';

  @override
  String get settingsProductsTitle => 'Produtos e Sinônimos';

  @override
  String get settingsProductsSubtitle => 'Gerenciar catálogo de produtos';

  @override
  String get settingsSectionPrivacy => 'Privacidade, Segurança e Dados';

  @override
  String get settingsDeleteReceiptPhotoTitle =>
      'Apagar foto do cupom após leitura';

  @override
  String get settingsDeleteReceiptPhotoSubtitle =>
      'Excluir arquivo de imagem após processamento do OCR';

  @override
  String get settingsBackupSubtitle => 'Exportar, importar e gerenciar dados';

  @override
  String get settingsSectionHelp => 'Ajuda e Sobre';

  @override
  String get settingsAboutTitle => 'Sobre';

  @override
  String get settingsAboutSubtitle => 'Informações sobre o aplicativo';

  @override
  String get backupMenuExportTitle => 'Exportar Backup';

  @override
  String get backupMenuExportSubtitle =>
      'Gere um arquivo criptografado com seus dados';

  @override
  String get backupMenuImportTitle => 'Importar Backup';

  @override
  String get backupMenuImportSubtitle =>
      'Restaurar ou mesclar dados de um arquivo de backup';

  @override
  String get backupMenuWipeSubtitle =>
      'Excluir permanentemente todos os dados armazenados';

  @override
  String get backupExportShareText => 'Backup criptografado My Sweet Home';

  @override
  String get backupExportEncryptedTitle => 'Exportar Dados Criptografados';

  @override
  String get backupExportEncryptedSubtitle =>
      'Gere um arquivo de backup seguro de todos os seus dados e fotos para salvar localmente ou compartilhar.';

  @override
  String backupExportError(String error) {
    return 'Erro ao gerar backup: $error';
  }

  @override
  String get backupExportSuccess => 'Backup gerado e exportado com sucesso!';

  @override
  String get backupExportCreateButton => 'Criar e Exportar Backup';

  @override
  String get backupStageCollecting => 'Coletando dados do aplicativo...';

  @override
  String get backupStageEncrypting =>
      'Criptografando com AES-256 e Argon2id...';

  @override
  String get backupStageWriting => 'Finalizando arquivo de backup...';

  @override
  String get backupStageDone => 'Concluído!';

  @override
  String get backupEncryptedTitle => 'Backup Criptografado';

  @override
  String get backupWarningTitle => 'Aviso Importante (RN-234)';

  @override
  String get backupWarningLostPassword =>
      'Se você perder a senha, o backup é perdido.';

  @override
  String get backupWarningNoRecovery =>
      'O aplicativo não salva sua senha nem consegue ler o backup sem ela. Não há opção de recuperação.';

  @override
  String get backupPasswordLabel => 'Senha do Backup *';

  @override
  String get backupPasswordRequired =>
      'Informe uma senha para proteger o backup';

  @override
  String get backupPasswordMinLength =>
      'A senha deve ter pelo menos 4 caracteres';

  @override
  String get backupConfirmPasswordLabel => 'Confirmar Senha *';

  @override
  String get backupPasswordsMismatch => 'As senhas não coincidem';

  @override
  String get backupIncludePhotosTitle => 'Incluir fotos no backup (RN-237)';

  @override
  String backupIncludePhotosWithSize(String size) {
    return 'Fotos de cupons e receitas (Tamanho estimado: $size)';
  }

  @override
  String get backupIncludePhotosDefault =>
      'Fotos de cupons e receitas ficam fora do backup por padrão';

  @override
  String get backupExportEncryptedButton => 'Exportar Criptografado';

  @override
  String get backupRestoreEncryptedTitle => 'Restaurar Backup Criptografado';

  @override
  String get backupRestoreEncryptedBody =>
      'Este arquivo de backup está protegido por senha. Informe a senha definida durante a exportação para continuar.';

  @override
  String get backupRestorePasswordRequired => 'Digite a senha do backup';

  @override
  String get backupRestoreEncryptedButton => 'Descriptografar e Restaurar';

  @override
  String get backupImportProcessing => 'Processando backup...';

  @override
  String get backupImportReplacedTitle => 'Backup restaurado com sucesso!';

  @override
  String get backupImportMergedTitle => 'Dados mesclados com sucesso!';

  @override
  String get backupImportReplacedBody =>
      'Os dados do aplicativo foram totalmente substituídos pelos do backup.';

  @override
  String get backupImportMergedBody =>
      'Os registros do backup foram mesclados aos dados existentes.';

  @override
  String get backupImportFailedTitle => 'Falha na importação';

  @override
  String get backupPreviewTitle => 'Pré-visualização do Backup';

  @override
  String backupPreviewAffectedRecords(int count) {
    return '$count registros afetados';
  }

  @override
  String backupPreviewSchemaVersion(int version) {
    return 'Versão do schema: v$version';
  }

  @override
  String backupPreviewExportedAt(String date) {
    return 'Data da exportação: $date';
  }

  @override
  String get backupImportModeTitle => 'Escolha a forma de importação:';

  @override
  String get backupImportModeReplace => 'Substituir tudo';

  @override
  String get backupImportModeMerge => 'Mesclar';

  @override
  String get backupImportConfirmReplace => 'Substituir e restaurar backup';

  @override
  String get backupImportConfirmMerge => 'Mesclar dados do backup';

  @override
  String get backupImportNoFile =>
      'Nenhum backup selecionado para pré-visualização.';

  @override
  String get backupImportSelectFile => 'Selecionar arquivo de backup';

  @override
  String get backupImportPasswordField => 'Senha do backup';

  @override
  String get backupImportRestoreButton => 'Restaurar';

  @override
  String get wipeConfirmFirstTitle => 'Confirmar exclusão de dados';

  @override
  String get wipeConfirmFirstBody =>
      'Você tem certeza de que deseja apagar todos os dados do aplicativo? Esta é a primeira confirmação.';

  @override
  String get wipeConfirmSecondTitle => 'Confirmação Final';

  @override
  String get wipeConfirmSecondBody =>
      'ESTA AÇÃO É DEFINITIVA E IRREVERSÍVEL. Todos os seus registros, fotos, tarefas, despesas e configurações serão apagados sem resíduo.';

  @override
  String get wipeConfirmSecondButton => 'Apagar tudo permanentemente';

  @override
  String get wipeLoading => 'Apagando todos os dados...';

  @override
  String get wipeSuccessTitle =>
      'Todos os dados foram apagados permanentemente.';

  @override
  String get wipeSuccessBody =>
      'O banco de dados, arquivos e configurações foram limpos sem deixar resíduos.';

  @override
  String get wipeWarningTitle => 'Atenção: Ação Irreversível';

  @override
  String get wipeWarningBody =>
      'Ao apagar tudo, todos os registros cadastrados (produtos, despesas, contas fixas, tarefas, receitas, compras e estoque), fotos de cupons e preferências do aplicativo serão apagados permanentemente.';

  @override
  String get wipeWarningTokens =>
      'Nenhum token ou arquivo temporário permanecerá no dispositivo.';

  @override
  String get wipeDeleteAllButton => 'Apagar todos os dados';

  @override
  String get monthJanuary => 'Janeiro';

  @override
  String get monthFebruary => 'Fevereiro';

  @override
  String get monthMarch => 'Março';

  @override
  String get monthApril => 'Abril';

  @override
  String get monthMay => 'Maio';

  @override
  String get monthJune => 'Junho';

  @override
  String get monthJuly => 'Julho';

  @override
  String get monthAugust => 'Agosto';

  @override
  String get monthSeptember => 'Setembro';

  @override
  String get monthOctober => 'Outubro';

  @override
  String get monthNovember => 'Novembro';

  @override
  String get monthDecember => 'Dezembro';

  @override
  String monthYearFormat(String month, String year) {
    return '$month de $year';
  }

  @override
  String get commonPreviousMonth => 'Mês anterior';

  @override
  String get commonNextMonth => 'Próximo mês';

  @override
  String get commonInvalidValue => 'Valor inválido';

  @override
  String get commonEnterAmount => 'Informe o valor';

  @override
  String get commonNotesOptional => 'Observações (opcional)';

  @override
  String get commonRepeatDaily => 'Diariamente';

  @override
  String get commonRepeatWeekly => 'Semanalmente';

  @override
  String get commonRepeatMonthly => 'Mensalmente';

  @override
  String get commonRepeatCustomDays => 'A cada X dias';

  @override
  String get commonDaysCountLabel => 'Quantidade de dias *';

  @override
  String billsUnpayTooltip(String title) {
    return 'Desmarcar pagamento de $title';
  }

  @override
  String get billsOptionsTooltip => 'Opções da conta';

  @override
  String get billsDeleteConfirmTitle => 'Excluir conta?';

  @override
  String billsDeleteConfirmBody(String title) {
    return 'Tem certeza de que deseja excluir a conta \"$title\"?';
  }

  @override
  String get billsMarkUnpaid => 'Marcar como não pago';

  @override
  String get billsPauseAction => 'Pausar conta';

  @override
  String get billsDeleteAction => 'Excluir conta';

  @override
  String billsCreateSuccess(String title) {
    return 'Conta \"$title\" cadastrada com sucesso!';
  }

  @override
  String billsCreateError(String error) {
    return 'Erro ao cadastrar conta: $error';
  }

  @override
  String billsPaidSuccess(String title) {
    return 'Conta \"$title\" marcada como paga!';
  }

  @override
  String billsUnpaidSuccess(String title) {
    return 'Conta \"$title\" marcada como não paga!';
  }

  @override
  String billsPausedSuccess(String title) {
    return 'Conta \"$title\" pausada com sucesso!';
  }

  @override
  String billsDeletedSuccess(String title) {
    return 'Conta \"$title\" excluída com sucesso!';
  }

  @override
  String billsDeleteError(String error) {
    return 'Erro ao excluir conta: $error';
  }

  @override
  String get billsNewDialogTitle => 'Nova Conta a Vencer';

  @override
  String get billsTitleFieldLabel => 'Título * (ex: Aluguel, Luz, Internet)';

  @override
  String get billsTitleRequired => 'Informe o título';

  @override
  String get billsAmountFieldLabel => 'Valor em R\$ * (ex: 150.00)';

  @override
  String get billsDueDayFieldLabel => 'Dia do Vencimento * (1 a 31)';

  @override
  String get billsDueDayInvalid => 'Informe um dia entre 1 e 31';

  @override
  String get billsFrequencyLabel => 'Frequência da Conta';

  @override
  String get billsFrequencyMonthly => 'Mensal';

  @override
  String get billsFrequencyBiweekly => 'Quinzenal';

  @override
  String get billsFrequencyWeekly => 'Semanal';

  @override
  String get billsFrequencyAnnual => 'Anual';

  @override
  String get billsCategoryLabel => 'Categoria *';

  @override
  String get billsSaveButton => 'Salvar Conta';

  @override
  String expensesExportError(String error) {
    return 'Erro ao exportar despesas: $error';
  }

  @override
  String get expensesMonthBudgetTooltip => 'Orçamento do mês';

  @override
  String get expensesPurchasesReceiptsTooltip => 'Compras e Notas Fiscais';

  @override
  String get expensesExportTooltip => 'Exportar despesas';

  @override
  String get expensesExportCsv => 'Exportar CSV';

  @override
  String get expensesExportPdf => 'Exportar PDF';

  @override
  String get expensesDeleteConfirmTitle => 'Excluir despesa?';

  @override
  String get expensesDeleteConfirmBody =>
      'Tem certeza de que deseja excluir esta despesa?';

  @override
  String get expensesViewPurchaseTooltip => 'Ver Compra / Nota';

  @override
  String get expensesViewBillTooltip => 'Ver Conta';

  @override
  String get expensesEditBudget => 'Editar Orçamento';

  @override
  String get expensesEditTitle => 'Editar Despesa';

  @override
  String get expensesDeleteTooltip => 'Excluir despesa';

  @override
  String get expensesAmountLabel => 'Valor *';

  @override
  String get expensesNameDescriptionLabel => 'Nome / Descrição';

  @override
  String get expensesNameDescriptionHint =>
      'ex.: Supermercado, Aluguel, Farmácia';

  @override
  String get expensesNotesHint => 'Detalhes adicionais...';

  @override
  String get expensesRepeatExpense => 'Repetir despesa';

  @override
  String get expensesRepeatFrequency => 'Frequência de repetição';

  @override
  String get expensesCustomDaysHint => 'ex.: 4';

  @override
  String get expensesCustomDaysRequired =>
      'Informe a quantidade de dias (entre 1 e 365)';

  @override
  String get expensesCustomDaysInvalid =>
      'Informe um número de dias válido entre 1 e 365';

  @override
  String budgetCategoryDialogTitle(String category) {
    return 'Orçamento para $category';
  }

  @override
  String get budgetCategoryLimitLabel => 'Limite em R\$ * (ex: 500,00)';

  @override
  String budgetTotalDialogTitle(String month) {
    return 'Orçamento Total de $month';
  }

  @override
  String get budgetBaseIncomeLabel => 'Receita base recorrente *';

  @override
  String get budgetBaseIncomeHint => 'ex: 3000,00';

  @override
  String get budgetIncomeRequired => 'Informe ao menos uma receita';

  @override
  String get budgetExtraIncomeLabel => 'Receitas adicionais avulsas no mês';

  @override
  String get budgetExtraIncomeHint => 'ex: 500,00';

  @override
  String get budgetTotalSumLabel => 'Soma total do orçamento:';

  @override
  String get budgetMonthTotalCardTitle => 'Orçamento Total do Mês';

  @override
  String get budgetEditIncomeTooltip => 'Editar receita e orçamento';

  @override
  String get budgetNoCategories => 'Nenhuma categoria cadastrada.';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get checklistGenerateShoppingList => 'Gerar lista de compras';

  @override
  String get checklistNewItem => 'Novo item';

  @override
  String checklistLoadError(String error) {
    return 'Erro ao carregar checklist: $error';
  }

  @override
  String get checklistEmptyDescription =>
      'Adicione itens ou selecione outro cômodo.';

  @override
  String get checklistProgressTitle => 'Progresso da casa';

  @override
  String checklistMarkedCount(int marked, int total) {
    return '$marked de $total itens marcados';
  }

  @override
  String checklistCreateListCount(int count) {
    return 'Criar lista ($count)';
  }

  @override
  String get checklistAddItemTitle => 'Adicionar item ao checklist';

  @override
  String get checklistItemLabel => 'Item *';

  @override
  String get checklistItemHint => 'Ex: Toalha de rosto';

  @override
  String get checklistRoomLabel => 'Cômodo / Categoria *';

  @override
  String get checklistRoomHint => 'Ex: Banheiro';

  @override
  String get checklistEditItemTitle => 'Editar item';

  @override
  String get checklistItemTitleLabel => 'Título do item *';

  @override
  String get checklistDeleteItemTitle => 'Excluir item?';

  @override
  String checklistDeleteItemBody(String title) {
    return 'Deseja remover \"$title\" do checklist?';
  }

  @override
  String checklistDefaultListNameCategory(String category) {
    return 'Lista da Casa - $category';
  }

  @override
  String get checklistDefaultListName => 'Lista da Casa (Checklist)';

  @override
  String checklistExportBody(int count) {
    return 'Criar uma lista de compras com os $count itens pendentes do checklist.';
  }

  @override
  String get checklistListNameLabel => 'Nome da lista *';

  @override
  String checklistListCreated(String name, int count) {
    return 'Lista \"$name\" criada com $count itens!';
  }

  @override
  String checklistListCreateError(String error) {
    return 'Falha ao criar lista: $error';
  }

  @override
  String get checklistGenerateListButton => 'Gerar lista';

  @override
  String checklistCardSemantics(String title, String percent) {
    return '$title, $percent% concluído, toque para ver detalhes';
  }

  @override
  String customizeVisibleCardsCount(int count) {
    return 'Cards exibidos ($count)';
  }

  @override
  String get customizeReorderHint =>
      'Arraste para reordenar ou utilize os botões acessíveis.';

  @override
  String get customizeNoVisibleCards => 'Nenhum card visível no momento.';

  @override
  String get customizeAvailableModulesHint =>
      'Módulos disponíveis para inclusão na sua tela inicial.';

  @override
  String get customizeAllCardsVisible =>
      'Todos os cards já estão visíveis no painel.';

  @override
  String customizeDragSemantics(String title) {
    return 'Arrastar $title para reordenar';
  }

  @override
  String customizeMoveUpSemantics(String title) {
    return 'Mover $title para cima';
  }

  @override
  String customizeMoveDownSemantics(String title) {
    return 'Mover $title para baixo';
  }

  @override
  String customizeHideSemantics(String title) {
    return 'Ocultar $title';
  }

  @override
  String customizeAddSemantics(String title) {
    return 'Adicionar $title ao painel';
  }

  @override
  String get dueBillsWidgetSemantics => 'Widget de contas a vencer';

  @override
  String get dueBillsDefaultTitle => 'Contas a vencer';

  @override
  String get dueBillsEmptyTitle => 'Nenhuma conta a vencer';

  @override
  String get dueBillsEmptyDescription =>
      'Todas as suas contas deste mês estão em dia.';

  @override
  String get dueBillsVariableAmount => 'Variável';

  @override
  String dueBillsItemSemanticsHidden(String title, String dueLabel) {
    return '$title, $dueLabel, valor oculto';
  }

  @override
  String dueBillsItemSemanticsVisible(
    String title,
    String dueLabel,
    String amount,
  ) {
    return '$title, $dueLabel, valor $amount';
  }

  @override
  String get dueBillsViewAll => 'Ver todas as contas';

  @override
  String get economySetGoalTitle => 'Definir Meta de Economia';

  @override
  String get economySetGoalFieldLabel => 'Meta de Economia do Mês';

  @override
  String get economySaveGoalButton => 'Salvar Meta';

  @override
  String economyLoadError(String error) {
    return 'Erro ao carregar dados: $error';
  }

  @override
  String economyMonthGoalTitle(String month) {
    return 'Meta do Mês ($month)';
  }

  @override
  String get economySetGoalFallback => 'Definir meta de economia';

  @override
  String economyCardSemantics(String title, String goalText) {
    return '$title, $goalText, toque para ver detalhes';
  }

  @override
  String get searchGlobalScreenTitle => 'Busca Global';

  @override
  String get searchGlobalLabel => 'Buscar em todo o app';

  @override
  String get searchGlobalInputHint => 'Digite produtos, despesas, tarefas...';

  @override
  String get searchGlobalEmptyTitle => 'Busca no app';

  @override
  String get searchGlobalEmptyDescription =>
      'Busque por produtos, despesas, tarefas, receitas e listas.';

  @override
  String get searchGlobalNoResultsTitle => 'Nenhum resultado';

  @override
  String searchGlobalNoResultsForQuery(String query) {
    return 'Não encontramos nada para \"$query\". Tente outro termo.';
  }

  @override
  String monthBalanceLoadError(String error) {
    return 'Erro ao carregar saldo do mês: $error';
  }

  @override
  String get monthBalanceNotSet => 'Não definido';

  @override
  String get monthBalanceSemanticsHidden =>
      'Widget de saldo do mês, valor oculto';

  @override
  String monthBalanceSemanticsVisible(String actual, String budget) {
    return 'Widget de saldo do mês, gasto $actual de $budget';
  }

  @override
  String get monthBalanceDefaultTitle => 'Saldo do mês';

  @override
  String get monthBalanceSpentLabel => 'Gasto no mês';

  @override
  String monthBalanceBudgetedLabel(String budget) {
    return 'Orçado: $budget';
  }

  @override
  String get monthBalanceViewDetails => 'Ver resumo financeiro';

  @override
  String recipesCardSemantics(String title, int count) {
    return '$title, $count receitas favoritas, toque para ver detalhes';
  }

  @override
  String get shoppingWidgetSemantics => 'Widget de listas de compras';

  @override
  String get shoppingWidgetEmptyTitle => 'Nenhuma lista de compras';

  @override
  String get shoppingWidgetEmptyDescription =>
      'Crie uma lista para acompanhar suas compras.';

  @override
  String get shoppingWidgetOnePending => '1 item pendente';

  @override
  String shoppingWidgetPendingOfTotal(int pending, int total) {
    return '$pending de $total itens pendentes';
  }

  @override
  String get shoppingWidgetViewAll => 'Ver todas as listas';

  @override
  String stockCardSemantics(String title) {
    return '$title, toque para ver detalhes';
  }

  @override
  String get stockCardEmpty => 'Nenhum produto monitorado no estoque.';

  @override
  String stockCardCount(int count) {
    return '$count produto(s) no estoque doméstico';
  }

  @override
  String get stockRegisterTitle => 'Registrar no Estoque';

  @override
  String get stockProductNameLabel => 'Nome do Produto *';

  @override
  String get stockProductNameHint => 'Ex: Arroz Tipo 1';

  @override
  String get stockApproxQuantityLabel => 'Quantidade aproximada *';

  @override
  String get stockApproxQuantityHint => 'Ex: 4';

  @override
  String get stockAddProductButton => 'Adicionar produto';

  @override
  String stockLoadError(String error) {
    return 'Erro ao carregar estoque: $error';
  }

  @override
  String get stockEmptyTitle => 'Estoque vazio';

  @override
  String get stockEmptyDescription =>
      'Nenhum produto registrado no estoque doméstico.';

  @override
  String stockNoEstimate(int count) {
    return 'Sem estimativa de consumo (compras no histórico: $count, mínimo: 3)';
  }

  @override
  String stockAvgInterval(String days) {
    return 'Intervalo médio de compra: $days dias';
  }

  @override
  String stockEstimatedRemaining(int days) {
    return 'Estimativa restante: ~$days dias';
  }

  @override
  String get todayTasksWidgetSemantics => 'Widget de tarefas do dia';

  @override
  String get todayTasksDefaultTitle => 'Tarefas de hoje';

  @override
  String get todayTasksEmptyTitle => 'Nenhuma tarefa para hoje';

  @override
  String get todayTasksEmptyDescription =>
      'Você não tem tarefas agendadas para hoje.';

  @override
  String get todayTasksDoneStatus => 'concluída';

  @override
  String get todayTasksPendingStatus => 'pendente';

  @override
  String get todayTasksAllDoneMessage =>
      'Todas as tarefas de hoje foram concluídas! 🎉';

  @override
  String get todayTasksViewAll => 'Ver todas as tarefas';

  @override
  String get commonAll => 'Todos';

  @override
  String get economyNoGoalSet => 'Nenhuma meta definida';

  @override
  String get economyChangeGoalButton => 'Alterar Meta';

  @override
  String get economyGoalProgressTitle => 'Progresso da Meta';

  @override
  String get economyContextualTipsTitle => 'Dicas Contextuais';

  @override
  String stockProductFallback(String id) {
    return 'Produto: $id';
  }

  @override
  String stockReportedQuantity(String quantity, String unit) {
    return 'Quantidade informada: $quantity $unit';
  }

  @override
  String dueBillsWidgetLoadError(String error) {
    return 'Erro ao carregar contas a vencer: $error';
  }

  @override
  String get shoppingListCompletedCelebration =>
      'Você completou a lista de compras! 💕';

  @override
  String get shoppingListRegisterPurchaseTitle => 'Registrar compra';

  @override
  String get shoppingListManageLists => 'Gerenciar listas';

  @override
  String get shoppingListClearPurchased => 'Limpar comprados';

  @override
  String shoppingListItemsMarkedCount(int marked, int total) {
    return '$marked de $total itens marcados';
  }

  @override
  String get shoppingListEmptyDescription =>
      'Adicione itens para não esquecer nada no mercado.';

  @override
  String get shoppingShortcutPurchases => 'Compras';

  @override
  String get shoppingShortcutPrices => 'Preços';

  @override
  String get shoppingShortcutStock => 'Estoque';

  @override
  String get shoppingQuantitySemantics => 'Quantidade';

  @override
  String get shoppingQuantityShortLabel => 'Qtd';

  @override
  String get shoppingUnitSemantics => 'Unidade de medida';

  @override
  String get shoppingUnitUnShort => 'Un';

  @override
  String get shoppingErrorSaveChange => 'Falha ao salvar alteração';

  @override
  String get shoppingErrorAddItem => 'Falha ao adicionar item';

  @override
  String get shoppingErrorRemoveItem => 'Falha ao remover item';

  @override
  String get shoppingErrorClearCompleted => 'Falha ao limpar itens concluídos';

  @override
  String get shoppingTileRegisterSingle => 'Registrar compra deste item';

  @override
  String get shoppingTileRemoveItem => 'Remover item';

  @override
  String get shoppingSheetsMyListsTitle => 'Minhas Listas de Compras';

  @override
  String get shoppingSheetsNewList => 'Nova Lista';

  @override
  String get shoppingSheetsNoLists => 'Nenhuma lista encontrada.';

  @override
  String shoppingSheetsArchivedCount(int count) {
    return 'Arquivada • $count itens';
  }

  @override
  String shoppingSheetsItemsCount(int count) {
    return '$count itens';
  }

  @override
  String get shoppingSheetsListOptions => 'Opções da lista';

  @override
  String get shoppingSheetsDuplicate => 'Duplicar';

  @override
  String get shoppingSheetsRename => 'Renomear';

  @override
  String get shoppingSheetsDuplicateSuccess => 'Lista duplicada com sucesso.';

  @override
  String get shoppingSheetsDuplicateError => 'Falha ao duplicar lista.';

  @override
  String get shoppingSheetsRenameTitle => 'Renomear Lista';

  @override
  String get shoppingSheetsListNameLabel => 'Nome da lista *';

  @override
  String get shoppingSheetsArchivedSuccess => 'Lista arquivada com sucesso.';

  @override
  String get shoppingSheetsUnarchivedSuccess =>
      'Lista desarquivada com sucesso.';

  @override
  String get shoppingSheetsCreateTitle => 'Nova Lista de Compras';

  @override
  String get shoppingSheetsCreateHint => 'ex.: Feira, Farmácia, Churrasco';

  @override
  String get shoppingSheetsCreateButton => 'Criar';

  @override
  String taskPresetsAreaSemantics(String area) {
    return 'área $area';
  }

  @override
  String get calendarTabDay => 'Dia';

  @override
  String get calendarTabWeek => 'Semana';

  @override
  String get calendarTabMonth => 'Mês';

  @override
  String get calendarMaintenanceSuggestions => 'Sugestões de manutenção';

  @override
  String get calendarSyncGoogle => 'Sincronizar com Google';

  @override
  String get calendarSyncStarting => 'Iniciando sincronização...';

  @override
  String get calendarSyncDone => 'Sincronização concluída!';

  @override
  String get calendarTodayTooltip => 'Hoje';

  @override
  String get calendarShowingToday => 'Exibindo hoje';

  @override
  String get calendarNewTask => 'Nova tarefa';

  @override
  String get calendarEditTaskTitle => 'Editar Tarefa';

  @override
  String get calendarTaskTitleLabel => 'Título *';

  @override
  String calendarDayBillsCount(int count) {
    return '$count conta(s)';
  }

  @override
  String calendarBillsDueToday(int count) {
    return 'Contas a vencer hoje ($count):';
  }

  @override
  String get calendarBillPaidStatus => '(Paga)';

  @override
  String get calendarBillPendingStatus => '(Pendente)';

  @override
  String get calendarDeleteTaskTitle => 'Excluir tarefa?';

  @override
  String calendarDeleteTaskConfirm(String title) {
    return 'Tem certeza de que deseja excluir \"$title\"?';
  }

  @override
  String get commonEdit => 'Editar';

  @override
  String get taskAllDayLabel => 'Dia inteiro';

  @override
  String get taskRepeatLabel => 'Repetição';

  @override
  String get taskRepeatNone => 'Sem repetição';

  @override
  String get calendarEditTaskAction => 'Editar tarefa';

  @override
  String get calendarDeleteTaskAction => 'Excluir tarefa';

  @override
  String get priceSearchProductLabel => 'Pesquisar produto';

  @override
  String get priceSearchProductHint => 'Digite para buscar um produto...';

  @override
  String get priceClearSearchTooltip => 'Limpar busca';

  @override
  String get purchaseSaveTooltip => 'Salvar compra';

  @override
  String get purchaseNewProductTooltip => 'Novo produto';

  @override
  String get purchaseRemoveItemTooltip => 'Remover item';

  @override
  String get purchasesHistoryTitle => 'Compras e Notas Fiscais';

  @override
  String get purchasesPriceHistoryTooltip => 'Histórico de Preços';

  @override
  String purchasesLoadError(String error) {
    return 'Erro ao carregar compras: $error';
  }

  @override
  String get purchasesEmptyTitle => 'Nenhuma compra registrada';

  @override
  String get purchasesRegisterButton => 'Registrar Compra';

  @override
  String get purchasesDeleteTooltip => 'Excluir compra';

  @override
  String get purchasesNewTooltip => 'Nova Compra';

  @override
  String get purchasesDeleteDialogTitle => 'Excluir compra?';

  @override
  String get purchasesDeleteDialogBody =>
      'Esta compra e seus pontos de preço serão excluídos.';

  @override
  String get purchasesDeleteSuccess => 'Compra excluída com sucesso';

  @override
  String get purchasesDeleteError => 'Erro ao excluir compra';

  @override
  String get purchasesTotalLabel => 'Total';

  @override
  String get purchasesDiscountLabel => 'Desconto';

  @override
  String purchasesItemsCount(int count) {
    return 'Itens ($count)';
  }

  @override
  String get purchasesNoDetailedItems => 'Nenhum item detalhado nesta compra.';

  @override
  String get purchasesProductFallback => 'Produto';

  @override
  String get purchasesItemPriceHistoryTooltip => 'Histórico de preço';

  @override
  String priceChartSemantics(String price, String store, String date) {
    return '$price em $store no $date';
  }

  @override
  String get productTrackPricesTooltip => 'Acompanhar preços';

  @override
  String get productMergeTooltip => 'Unir com outro produto';

  @override
  String get productTrackPriceHistoryButton => 'Acompanhar histórico de preços';

  @override
  String productPreferredNameSet(String alias) {
    return '\"$alias\" definido como nome padrão de exibição.';
  }

  @override
  String productSeparateAliasDescription(String alias) {
    return 'Você pode separar \"$alias\" como um produto independente (com seu próprio histórico de preços) ou apenas remover o apelido.';
  }

  @override
  String get productSeparateAliasAction => 'Separar como outro produto';

  @override
  String get productNoMergeCandidates =>
      'Nenhum outro produto disponível para união.';

  @override
  String get productMergeSearchLabel => 'Buscar produto destino';

  @override
  String get productMergeNoneFound => 'Nenhum produto encontrado.';

  @override
  String get productMergeConfirmTitle => 'Confirmar união';

  @override
  String productMergeConfirmBody(String source, String target) {
    return 'Deseja unir \"$source\" com \"$target\"?\n\nTodas as compras, itens, preços e sinônimos serão transferidos para \"$target\" e este produto será arquivado.';
  }

  @override
  String get productMergeConfirmButton => 'Unir produtos';

  @override
  String productMergeSuccess(String target) {
    return 'Produto unido com \"$target\".';
  }

  @override
  String get productNewDialogTitle => 'Novo Produto';

  @override
  String get productCanonicalNameRequiredLabel => 'Nome Canônico *';

  @override
  String get productCanonicalNameError => 'Informe o nome';

  @override
  String get productDefaultUnitRequiredLabel => 'Unidade Padrão *';

  @override
  String get productAliasesLabel => 'Apelidos / Sinônimos';

  @override
  String get productAliasesHint => 'Separados por vírgula (opcional)';

  @override
  String get productCreateError => 'Erro ao criar produto';

  @override
  String get recipeListServiceUnavailable => 'Serviço de listas não disponível';

  @override
  String get recipeNoActiveShoppingLists =>
      'Nenhuma lista de compras ativa encontrada.';

  @override
  String get recipeSelectShoppingListTitle => 'Selecione a lista de compras';

  @override
  String get recipeIngredientsSentSuccess =>
      'Ingredientes enviados para a lista de compras!';

  @override
  String recipeIngredientsSentError(String error) {
    return 'Falha ao enviar ingredientes: $error';
  }

  @override
  String get recipeDecreaseServingsTooltip => 'Diminuir porções';

  @override
  String get recipeIncreaseServingsTooltip => 'Aumentar porções';

  @override
  String get recipeSendIngredientsButton =>
      'Enviar ingredientes para lista de compras';

  @override
  String get recipeDraftTitleRequiredError => 'O título é obrigatório.';

  @override
  String get recipeDraftIngredientsRequiredError =>
      'Adicione pelo menos um ingrediente.';

  @override
  String recipeDraftSaveError(String error) {
    return 'Falha ao salvar receita: $error';
  }

  @override
  String get recipePasteTitle => 'Colar receita';

  @override
  String get recipePasteHint =>
      'Cole a receita aqui (título, ingredientes, modo de preparo)...';

  @override
  String get recipeImportButton => 'Importar';

  @override
  String get recipeIngredientNameLabel => 'Nome do ingrediente';

  @override
  String get recipeIngredientNameHint => 'Ex: 2 xícaras de farinha';

  @override
  String get recipeTagNameLabel => 'Nome da tag';

  @override
  String get recipeTagNameHint => 'Ex: Sobremesa, Rápido, Vegano';

  @override
  String get recipeSaveTooltip => 'Salvar receita';

  @override
  String recipeRemoveIngredientSemantics(String name) {
    return 'Remover ingrediente $name';
  }

  @override
  String get recipeRemoveIngredientTooltip => 'Remover ingrediente';

  @override
  String get recipeAddPhotoButton => 'Adicionar foto';

  @override
  String get recipePhotoAttached => 'Foto anexada à receita.';

  @override
  String recipeSpinDecrease(String label) {
    return 'Diminuir $label';
  }

  @override
  String recipeSpinIncrease(String label) {
    return 'Aumentar $label';
  }

  @override
  String recipeListTimeAndServings(int minutes, int servings) {
    return '$minutes min • $servings porções';
  }

  @override
  String get recipeUnfavoriteTooltip => 'Desmarcar favorito';

  @override
  String get recipeFavoriteTooltip => 'Marcar como favorito';

  @override
  String get recipeRepoUnavailable => 'Repositório de receitas não disponível';

  @override
  String get recipeNotFound => 'Receita não encontrada';

  @override
  String get recipeNoInstructions => 'Sem instruções cadastradas.';

  @override
  String get ocrScanReceiptTitle => 'Escanear nota fiscal';

  @override
  String get ocrDisableFlashTooltip => 'Desativar flash';

  @override
  String get ocrEnableFlashTooltip => 'Ativar flash';

  @override
  String get ocrBenchmarkTooltip => 'Benchmark de Precisão OCR';

  @override
  String get ocrGalleryTooltip => 'Escolher foto da galeria';

  @override
  String get ocrGalleryLabel => 'Galeria';

  @override
  String get ocrTakePhotoSemantics => 'Tirar foto da nota fiscal';

  @override
  String get ocrManualEntryTooltip => 'Lançar manualmente';

  @override
  String get ocrReceiptSavedSuccess => 'Nota Fiscal salva com sucesso!';

  @override
  String ocrReceiptSaveError(String error) {
    return 'Erro ao salvar nota: $error';
  }

  @override
  String get ocrRecognizeError => 'Falha ao reconhecer nota fiscal.';

  @override
  String get ocrTotalDivergenceTitle => 'Divergência no total';

  @override
  String ocrTotalDivergenceBody(
    String itemsSum,
    String total,
    String divergence,
  ) {
    return 'A soma dos itens selecionados ($itemsSum) difere do total lido ($total).\n\nDivergência de $divergence. Deseja salvar assim mesmo?';
  }

  @override
  String get ocrWriteOffTitle => 'Baixar itens da lista de compras';

  @override
  String ocrWriteOffSingleConfirm(String listName) {
    return 'Deseja dar baixa nos itens desta compra na lista de compras \"$listName\"?';
  }

  @override
  String get commonNo => 'Não';

  @override
  String get ocrWriteOffYes => 'Sim, dar baixa';

  @override
  String get ocrWriteOffSelectPrompt =>
      'Selecione a lista de compras para dar baixa nos itens comprados:';

  @override
  String get ocrSaveWithoutWriteOff => 'Salvar sem baixa';

  @override
  String get ocrWriteOffButton => 'Dar baixa';

  @override
  String ocrCouponItemsHeader(int selected, int total) {
    return 'Itens do cupom ($selected/$total)';
  }

  @override
  String get ocrAddItemButton => 'Adicionar item';

  @override
  String get ocrNoItemsPlaceholder => 'Nenhum item. Toque em Adicionar item.';

  @override
  String get ocrCloudConsentBody =>
      'A leitura no aparelho teve baixa precisão. Como você permitiu o OCR na nuvem nas configurações, deseja tentar melhorar a leitura enviando esta nota para o serviço em nuvem nesta operação?';

  @override
  String get ocrRetakePhotoButton => 'Tirar outra foto';

  @override
  String get ocrContinueWithoutCloud => 'Continuar sem nuvem';

  @override
  String get ocrUseCloudOcr => 'Usar OCR na nuvem';

  @override
  String get ocrLowPrecisionTitle => 'Leitura com baixa precisão';

  @override
  String get ocrLowPrecisionBody =>
      'A leitura da nota fiscal no aparelho teve baixa precisão. Recomendamos tirar uma nova foto com melhor iluminação e enquadramento.';

  @override
  String get ocrContinueWithData => 'Continuar com estes dados';

  @override
  String ocrFramingGuideSemantics(String instruction) {
    return 'Guia de enquadramento de nota fiscal. $instruction';
  }

  @override
  String get ocrFramingDefaultInstruction =>
      'Posicione a nota fiscal na vertical dentro do guia';

  @override
  String get ocrTotalFailureTitle => 'Não foi possível ler a nota';

  @override
  String ocrAttachedPhoto(String path) {
    return 'Foto anexada: $path';
  }

  @override
  String get ocrQualityContinueAnyway => 'Continuar mesmo assim';

  @override
  String get ocrQualityBlur =>
      'Imagem desfocada. Tente segurar a câmera com firmeza.';

  @override
  String get ocrQualityTooDark =>
      'Iluminação muito baixa. Ligue o flash ou ilumine a nota.';

  @override
  String get ocrQualityTooBright =>
      'Excesso de iluminação ou reflexo brilhante na imagem.';

  @override
  String get ocrQualityBadFraming =>
      'Enquadramento ruim ou foto muito pequena.';

  @override
  String get ocrQualityInvalidImage =>
      'Não foi possível decodificar os dados da imagem.';

  @override
  String get ocrStoreUnknown => 'Estabelecimento não identificado';

  @override
  String get ocrEditStoreTooltip => 'Editar estabelecimento';

  @override
  String ocrCnpjLabel(String cnpj) {
    return 'CNPJ: $cnpj';
  }

  @override
  String get ocrNotInformed => 'Não informado';

  @override
  String get ocrCnpjUnconfirmed => 'CNPJ não confirmado';

  @override
  String get ocrTotalDivergenceCardTitle => 'Divergência no valor total';

  @override
  String ocrTotalDivergenceCardBody(
    String absDiv,
    String itemsSum,
    String total,
  ) {
    return 'Divergência de $absDiv. O sistema não ajusta automaticamente.\nSoma dos itens: $itemsSum | Total lido: $total';
  }

  @override
  String ocrLowConfidenceBanner(int count) {
    return 'Há $count item(ns) com baixa confiança lidos do cupom. Verifique e marque os corretos.';
  }

  @override
  String get ocrReceiptTotalsTitle => 'Totais da Nota';

  @override
  String get ocrEditTotalsTooltip => 'Editar totais';

  @override
  String get ocrSubtotalLabel => 'Subtotal:';

  @override
  String get ocrDiscountLabel => 'Desconto:';

  @override
  String get ocrOriginExactAlias => 'exato (apelido)';

  @override
  String get ocrOriginSeed => 'semente';

  @override
  String ocrOriginFuzzy(int percent) {
    return 'aproximado ($percent%)';
  }

  @override
  String get ocrOriginUnknown => 'não identificado';

  @override
  String get ocrItemSelectedStatus => 'selecionado';

  @override
  String get ocrItemUnselectedStatus => 'desmarcado';

  @override
  String get ocrItemLowConfidenceHint => ', baixa confiança, confira este item';

  @override
  String ocrItemDetectedAs(String raw) {
    return 'detectado como $raw';
  }

  @override
  String ocrItemUncheckHint(String title) {
    return 'Desmarcar $title';
  }

  @override
  String ocrItemLinkOrigin(String origin) {
    return 'Vínculo: $origin';
  }

  @override
  String get ocrEditItemTooltip => 'Editar item';

  @override
  String get ocrDeleteItemTooltip => 'Apagar item';

  @override
  String get ocrEditHeaderTitle => 'Editar cabeçalho';

  @override
  String get ocrStoreRequiredLabel => 'Estabelecimento *';

  @override
  String get ocrStoreHint => 'Nome do supermercado ou loja';

  @override
  String get ocrStoreError => 'Informe o nome do estabelecimento';

  @override
  String get ocrCnpjOptionalLabel => 'CNPJ (opcional)';

  @override
  String get ocrDateTimeRequiredLabel => 'Data/Hora (dd/MM/yyyy HH:mm) *';

  @override
  String get ocrDateTimeRequiredError => 'Informe a data da compra';

  @override
  String get ocrDateTimeInvalidError =>
      'Formato inválido (ex: 21/09/2026 14:30)';

  @override
  String get ocrNfceKeyOptionalLabel => 'Chave da NFC-e (opcional)';

  @override
  String get ocrNfceKeyHint => '44 dígitos da nota fiscal';

  @override
  String get ocrSubtotalInputLabel => 'Subtotal (R\$)';

  @override
  String get ocrDiscountInputLabel => 'Desconto (R\$)';

  @override
  String get ocrReadTotalInputLabel => 'Total lido (R\$)';

  @override
  String get ocrRegisterNewProductTitle => 'Cadastrar novo produto';

  @override
  String get ocrCanonicalNameRequiredLabel => 'Nome canônico *';

  @override
  String get ocrCanonicalNameHint => 'Ex: Leite Integral 1L';

  @override
  String get ocrCanonicalNameRequiredError => 'Informe o nome canônico';

  @override
  String get ocrCategoryRequiredLabel => 'Categoria *';

  @override
  String get ocrCategoryHint => 'Ex: Alimentos, Limpeza, etc.';

  @override
  String get ocrCategoryRequiredError => 'Informe a categoria';

  @override
  String get ocrDefaultUnitRequiredLabel => 'Unidade padrão *';

  @override
  String get ocrAliasesOptionalLabel => 'Sinônimos / Apelidos (opcional)';

  @override
  String get ocrAliasesHint => 'Separados por vírgula';

  @override
  String get ocrLinkProductTitle => 'Vincular produto';

  @override
  String get ocrProductNameSearchLabel => 'Nome do produto';

  @override
  String get ocrProductNameSearchHint => 'Digite o nome do produto';

  @override
  String ocrRegisterNamedAsNew(String name) {
    return 'Cadastrar \"$name\" como novo produto';
  }

  @override
  String get ocrSuggestedProductsLabel => 'Produtos sugeridos:';

  @override
  String ocrProductMetaRow(String category, String unit) {
    return 'Categoria: $category | Unidade: $unit';
  }

  @override
  String get ocrNoExistingProductFound =>
      'Nenhum produto existente encontrado com esse nome.';

  @override
  String get ocrNoneLinked => 'Nenhum';

  @override
  String get ocrItemDescriptionLabel => 'Descrição lida / Nome *';

  @override
  String get ocrItemDescriptionError => 'Informe o nome ou descrição';

  @override
  String get ocrQuantityRequiredLabel => 'Quantidade *';

  @override
  String get ocrQuantityRequiredError => 'Informe a qtd';

  @override
  String get ocrQuantityInvalidError => 'Qtd inválida';

  @override
  String get ocrUnitRequiredLabel => 'Unidade *';

  @override
  String get ocrUnitPriceRequiredLabel => 'Preço unitário (R\$) *';

  @override
  String get ocrTotalPriceRequiredLabel => 'Preço total (R\$) *';

  @override
  String get ocrIncludeItemInPurchase => 'Incluir item na compra';

  @override
  String get ocrLinkedProductLabel => 'Produto vinculado:';

  @override
  String get ocrChangeOrLinkButton => 'Trocar / Vincular';

  @override
  String get ocrRegisterProductButton => 'Cadastrar produto';

  @override
  String get ocrUnlinkTooltip => 'Remover vínculo';

  @override
  String get ocrUnnamedItemFallback => 'Item sem nome';

  @override
  String get ocrTotalReadColonLabel => 'Total lido do cupom:';

  @override
  String get ocrSelectedItemsSumColonLabel => 'Soma dos itens selecionados:';

  @override
  String ocrItemSelectHint(String title) {
    return 'Selecionar $title';
  }

  @override
  String householdSyncFailure(String error) {
    return 'Falha na sincronização: $error';
  }

  @override
  String householdSyncAppliedSuffix(int count) {
    return ' ($count alterações aplicadas).';
  }

  @override
  String householdSyncSentSuffix(int count) {
    return ' ($count alterações enviadas).';
  }

  @override
  String householdSyncCompleted(int sent, int applied) {
    return 'Sincronização concluída: $sent alterações enviadas, $applied aplicadas.';
  }

  @override
  String get householdCloudSyncNoChanges =>
      'Sincronização em nuvem concluída. Nenhuma alteração pendente.';

  @override
  String householdSyncUnexpectedError(String error) {
    return 'Erro inesperado na sincronização: $error';
  }

  @override
  String get householdHowSyncWorksTooltip => 'Como funciona a sincronização';

  @override
  String get householdImportBundleButton => 'Importar pacote';

  @override
  String get householdCloudSyncTitle =>
      'Permitir sincronização remota da casa (nuvem)';

  @override
  String get householdCloudSyncSubtitle =>
      'Sincronizar fora do Wi-Fi doméstico com criptografia de ponta a ponta';

  @override
  String get householdCalendarLocalTitle => 'Sincronizar agenda neste aparelho';

  @override
  String get householdCalendarLocalSubtitle =>
      'Evita duplicação sincronizando tarefas do Google Calendar só aqui';

  @override
  String householdMembersLoadError(String error) {
    return 'Erro ao carregar membros: $error';
  }

  @override
  String get householdThisDevice => 'Este aparelho';

  @override
  String householdLastSeen(String time) {
    return 'Visto por último: $time';
  }

  @override
  String get householdNeverSynced => 'Nunca sincronizou';

  @override
  String get householdRemoveMemberTooltip => 'Remover membro';

  @override
  String get householdDefaultDeviceName => 'Meu celular';

  @override
  String get householdJoinDialogTitle => 'Entrar em uma casa';

  @override
  String get householdScanQrButton => 'Ler QR Code com a câmera';

  @override
  String get householdInviteCodeLabel => 'Código ou link de convite';

  @override
  String get householdInviteCodeHint =>
      'Cole o link mshsync:// ou escaneie o QR Code';

  @override
  String get householdPasteCodeTooltip => 'Colar código';

  @override
  String get householdDeviceNameLabel => 'Nome deste aparelho';

  @override
  String get householdInvalidInviteError =>
      'Código de convite inválido. Verifique o link ou QR Code.';

  @override
  String get householdHostDeviceFallback => 'Aparelho Anfitrião';

  @override
  String get householdInviteGenerateError =>
      'Não foi possível gerar o convite de pareamento.';

  @override
  String get householdInviteDialogTitle => 'Convidar dispositivo';

  @override
  String get householdInviteDialogPrompt =>
      'Escaneie este QR Code no outro aparelho ou envie o link abaixo:';

  @override
  String get householdCopyLinkButton => 'Copiar link';

  @override
  String get householdInviteLinkCopied => 'Link de convite copiado!';

  @override
  String get householdSasCodeLabel => 'Código de autenticação SAS (6 dígitos):';

  @override
  String householdRemoveMemberDialogTitle(String name) {
    return 'Remover \"$name\"?';
  }

  @override
  String get householdRemoveMemberDialogBody =>
      'Ao remover o aparelho, a chave da casa será rotacionada e ele não poderá mais sincronizar novos dados.';

  @override
  String get householdDefaultHouseName => 'Minha Casa';

  @override
  String get householdDefaultDeviceNameAlt => 'Meu Aparelho';

  @override
  String get householdEmptyHouseNameError =>
      'O nome da casa não pode ser vazio.';

  @override
  String get householdEmptyDeviceNameError =>
      'O nome do aparelho não pode ser vazio.';

  @override
  String householdUnexpectedErrorWithDetail(String error) {
    return 'Erro inesperado: $error';
  }

  @override
  String get householdHouseNameLabel => 'Nome da casa';

  @override
  String get householdCreatingProgress => 'Criando casa e preparando dados...';

  @override
  String get householdCreateShortButton => 'Criar';

  @override
  String get householdErrorUnknown => 'Erro desconhecido.';

  @override
  String get householdErrorStorageDetail =>
      'Não foi possível salvar ou carregar os dados. Tente novamente.';

  @override
  String get householdErrorStorageAccess =>
      'Não foi possível acessar o armazenamento.';

  @override
  String get householdErrorNoInternet => 'Sem conexão com a internet.';

  @override
  String get householdErrorNetwork => 'Falha de comunicação na rede.';

  @override
  String householdErrorPermissionRequired(String permission) {
}
