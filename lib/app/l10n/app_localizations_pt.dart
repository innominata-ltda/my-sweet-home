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
}
