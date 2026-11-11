import 'package:flutter/material.dart';

/// App icons facade.
///
/// **Regra RN-011:** nenhum arquivo em `lib/features/` importa [Icons]
/// directly. All icons go through this class.
abstract final class AppIcons {
  // ── Navigation ─────────────────────────────────────────────────────────────

  static const home = Icons.home_outlined;
  static const homeActive = Icons.home;
  static const shopping = Icons.shopping_cart_outlined;
  static const shoppingActive = Icons.shopping_cart;
  static const tasks = Icons.check_circle_outline;
  static const tasksActive = Icons.check_circle;
  static const recipes = Icons.menu_book_outlined;
  static const recipesActive = Icons.menu_book;
  static const settings = Icons.settings_outlined;
  static const settingsActive = Icons.settings;

  // ── Actions ────────────────────────────────────────────────────────────────

  static const add = Icons.add;
  static const edit = Icons.edit_outlined;
  static const delete = Icons.delete_outline;
  static const undo = Icons.undo;
  static const camera = Icons.camera_alt_outlined;
  static const filter = Icons.filter_list;
  static const search = Icons.search;
  static const close = Icons.close;
  static const back = Icons.arrow_back;
  static const chevronLeft = Icons.chevron_left;
  static const chevronRight = Icons.chevron_right;
  static const more = Icons.more_vert;

  // ── Domain ─────────────────────────────────────────────────────────────────

  static const money = Icons.attach_money;
  static const bill = Icons.receipt_long_outlined;
  static const product = Icons.inventory_2_outlined;
  static const store = Icons.store_outlined;
  static const budget = Icons.savings_outlined;
  static const notification = Icons.notifications_outlined;
  static const calendar = Icons.calendar_today_outlined;
  static const time = Icons.access_time_outlined;
  static const check = Icons.check;
  static const pending = Icons.radio_button_unchecked;
  static const late = Icons.warning_amber_outlined;
  static const info = Icons.info_outline;
  static const success = Icons.check_circle_outline;
  static const error = Icons.error_outline;
  static const warning = Icons.warning_outlined;

  // ── License / About ────────────────────────────────────────────────────────

  static const about = Icons.info_outlined;
  static const openSource = Icons.code;

  // --- Wave 2 additions ---
  // 002
  static const alias = Icons.label_outlined;
  static const merge = Icons.merge_type;
  static const archive = Icons.archive_outlined;

  // 003
  static const purchase = Icons.shopping_bag_outlined;
  static const priceHistory = Icons.show_chart_outlined;
  static const trendUp = Icons.trending_up_outlined;
  static const trendDown = Icons.trending_down_outlined;
  static const barcode = Icons.qr_code_scanner_outlined;
  static const trophy = Icons.emoji_events;

  // 004
  static const dragHandle = Icons.drag_handle;
  static const checkBox = Icons.check_box;
  static const checkBoxBlank = Icons.check_box_outline_blank;
  static const copy = Icons.content_copy;
  static const paste = Icons.content_paste;
  static const radioButtonChecked = Icons.radio_button_checked;
  static const radioButtonOff = Icons.radio_button_off;

  // 005
  static const expense = Icons.money_off_outlined;
  static const category = Icons.category_outlined;
  static const recurring = Icons.repeat;
  static const export = Icons.import_export;
  static const catHousing = Icons.house_outlined;
  static const catFood = Icons.restaurant_outlined;
  static const catTransport = Icons.directions_car_outlined;
  static const catHealth = Icons.health_and_safety_outlined;
  static const catEducation = Icons.school_outlined;
  static const catEntertainment = Icons.movie_outlined;
  static const catPersonal = Icons.person_outline;
  static const catPets = Icons.pets_outlined;
  static const catTaxes = Icons.account_balance_outlined;
  static const catOther = Icons.more_horiz_outlined;

  // 006
  static const paid = Icons.check_circle;
  static const pause = Icons.pause_circle_outline;
  static const batteryWarning = Icons.battery_alert_outlined;

  // 007
  static const task = Icons.task_alt;
  static const syncConflict = Icons.sync_problem;
  static const google = Icons.g_mobiledata;

  // 008
  static const recipe = Icons.receipt_outlined;
  static const favorite = Icons.favorite_border;
  static const servings = Icons.restaurant_menu;
  static const timer = Icons.timer_outlined;
  static const sendToList = Icons.add_shopping_cart;

  // 009
  static const ocr = Icons.document_scanner_outlined;
  static const flashOn = Icons.flash_on;
  static const flashOff = Icons.flash_off;
  static const review = Icons.fact_check_outlined;
  static const qualityWarning = Icons.warning_amber_rounded;
  static const qualityBlur = Icons.blur_on;
  static const qualityDark = Icons.dark_mode;
  static const qualityBright = Icons.light_mode;
  static const qualityFraming = Icons.crop;
  static const qualityInvalid = Icons.broken_image;
  static const gallery = Icons.photo_library_outlined;
  static const framingGuide = Icons.crop_free;

  // 010
  static const backup = Icons.backup_outlined;
  static const restore = Icons.restore;
  static const cloudBackup = Icons.cloud_upload_outlined;
  static const fileExport = Icons.file_download_outlined;
  static const fileImport = Icons.file_upload_outlined;
  static const share = Icons.share_outlined;
  static const lockBackup = Icons.lock_outlined;
  static const deleteForever = Icons.delete_forever_outlined;

  // 011
  static const stock = Icons.inventory_outlined;
  static const checklist = Icons.checklist_outlined;
  static const lowStock = Icons.running_with_errors_outlined;
  static const economy = Icons.savings_outlined;
  static const widgetIcon = Icons.widgets_outlined;
  static const room = Icons.meeting_room_outlined;

  // 011: Dashboard Customization
  static const customizeDashboard = Icons.dashboard_customize_outlined;
  static const moveUp = Icons.arrow_upward;
  static const moveDown = Icons.arrow_downward;

  // Additional facade icons
  static const favoriteActive = Icons.favorite;
  static const remove = Icons.remove;
  static const removeCircle = Icons.remove_circle_outline;
  static const addCircle = Icons.add_circle_outline;
  static const play = Icons.play_arrow;
  static const today = Icons.today;

  // 014: Task Presets
  static const taskPreset = Icons.auto_awesome_outlined;
  static const alreadyInRoutine = Icons.bookmark_added_outlined;

  // 013: Household Sharing (P2P synchronization)
  static const household = Icons.cottage_outlined;
  static const householdActive = Icons.cottage;
  static const sync = Icons.sync;
  static const syncDisabled = Icons.sync_disabled;
  static const qrCode = Icons.qr_code_2_outlined;
  static const qrScanner = Icons.qr_code_scanner;
  static const wifi = Icons.wifi;
}
