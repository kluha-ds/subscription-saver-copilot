import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SaverApp());
}

class SaverApp extends StatelessWidget {
  const SaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subscription Saver Copilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2457FF)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

enum BillingCadence { monthly, annual, custom }
enum SubscriptionStatus { active, trial, canceled, paused, unknown }
enum RenewalDateCertainty { exact, inferred, unknown }
enum ActionType { keep, cancel, downgraded, snooze, undecided }

extension EnumLabel on Enum {
  String get label {
    final raw = name.replaceAll('_', ' ');
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

class ActionEvent {
  ActionEvent({required this.type, required this.timestamp, this.note = ''});

  final ActionType type;
  final DateTime timestamp;
  final String note;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
  };

  factory ActionEvent.fromJson(Map<String, dynamic> json) => ActionEvent(
    type: ActionType.values.byName(json['type'] as String),
    timestamp: DateTime.parse(json['timestamp'] as String),
    note: (json['note'] as String?) ?? '',
  );
}

class SubscriptionRecord {
  SubscriptionRecord({
    required this.id,
    required this.providerName,
    required this.status,
    required this.sourceType,
    required this.createdAt,
    required this.updatedAt,
    this.amount,
    this.currency = 'USD',
    this.billingCadence = BillingCadence.monthly,
    this.category = 'General',
    this.billingCycleAnchor,
    this.nextRenewalDate,
    this.renewalDateCertainty = RenewalDateCertainty.unknown,
    this.trialEndDate,
    this.lastPaidAmount,
    this.upcomingPriceIncreaseAmount,
    this.priceIncreaseEffectiveDate,
    this.sourceReference,
    this.confidenceScore,
    this.notes = '',
    this.lastDetectedAt,
    this.lastUserConfirmedAt,
    this.lastVerifiedAt,
    this.cancellationUrl,
    this.cancellationUrlVerifiedAt,
    this.cancellationUrlSource,
    List<ActionEvent>? actionHistory,
  }) : actionHistory = actionHistory ?? [];

  final String id;
  final String providerName;
  final String category;
  final double? amount;
  final String currency;
  final BillingCadence billingCadence;
  final DateTime? billingCycleAnchor;
  final DateTime? nextRenewalDate;
  final RenewalDateCertainty renewalDateCertainty;
  final DateTime? trialEndDate;
  final SubscriptionStatus status;
  final double? lastPaidAmount;
  final double? upcomingPriceIncreaseAmount;
  final DateTime? priceIncreaseEffectiveDate;
  final String sourceType;
  final String? sourceReference;
  final double? confidenceScore;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastDetectedAt;
  final DateTime? lastUserConfirmedAt;
  final DateTime? lastVerifiedAt;
  final String? cancellationUrl;
  final DateTime? cancellationUrlVerifiedAt;
  final String? cancellationUrlSource;
  final List<ActionEvent> actionHistory;

  bool get isIncomplete => providerName.trim().isEmpty || amount == null || nextRenewalDate == null;
  bool get isRenewalSoon {
    final upcoming = nextRenewalDate;
    if (upcoming == null || status == SubscriptionStatus.canceled) return false;
    final diff = upcoming.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 14;
  }

  double? get monthlyEquivalent {
    if (amount == null) return null;
    if (status == SubscriptionStatus.trial || status == SubscriptionStatus.paused || status == SubscriptionStatus.canceled) {
      return 0;
    }
    switch (billingCadence) {
      case BillingCadence.monthly:
        return amount;
      case BillingCadence.annual:
        return amount! / 12;
      case BillingCadence.custom:
        return amount;
    }
  }

  double? get annualEquivalent {
    if (amount == null) return null;
    if (status == SubscriptionStatus.trial || status == SubscriptionStatus.paused || status == SubscriptionStatus.canceled) {
      return 0;
    }
    switch (billingCadence) {
      case BillingCadence.monthly:
        return amount! * 12;
      case BillingCadence.annual:
        return amount;
      case BillingCadence.custom:
        return amount! * 12;
    }
  }

  SubscriptionRecord copyWith({
    String? providerName,
    String? category,
    double? amount,
    bool clearAmount = false,
    String? currency,
    BillingCadence? billingCadence,
    DateTime? nextRenewalDate,
    bool clearNextRenewalDate = false,
    RenewalDateCertainty? renewalDateCertainty,
    DateTime? trialEndDate,
    bool clearTrialEndDate = false,
    SubscriptionStatus? status,
    String? notes,
    String? cancellationUrl,
    String? cancellationUrlSource,
    DateTime? cancellationUrlVerifiedAt,
    List<ActionEvent>? actionHistory,
  }) {
    return SubscriptionRecord(
      id: id,
      providerName: providerName ?? this.providerName,
      category: category ?? this.category,
      amount: clearAmount ? null : amount ?? this.amount,
      currency: currency ?? this.currency,
      billingCadence: billingCadence ?? this.billingCadence,
      billingCycleAnchor: billingCycleAnchor,
      nextRenewalDate: clearNextRenewalDate ? null : nextRenewalDate ?? this.nextRenewalDate,
      renewalDateCertainty: renewalDateCertainty ?? this.renewalDateCertainty,
      trialEndDate: clearTrialEndDate ? null : trialEndDate ?? this.trialEndDate,
      status: status ?? this.status,
      lastPaidAmount: lastPaidAmount,
      upcomingPriceIncreaseAmount: upcomingPriceIncreaseAmount,
      priceIncreaseEffectiveDate: priceIncreaseEffectiveDate,
      sourceType: sourceType,
      sourceReference: sourceReference,
      confidenceScore: confidenceScore,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastDetectedAt: lastDetectedAt,
      lastUserConfirmedAt: lastUserConfirmedAt,
      lastVerifiedAt: lastVerifiedAt,
      cancellationUrl: cancellationUrl ?? this.cancellationUrl,
      cancellationUrlVerifiedAt: cancellationUrlVerifiedAt ?? this.cancellationUrlVerifiedAt,
      cancellationUrlSource: cancellationUrlSource ?? this.cancellationUrlSource,
      actionHistory: actionHistory ?? this.actionHistory,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'providerName': providerName,
    'category': category,
    'amount': amount,
    'currency': currency,
    'billingCadence': billingCadence.name,
    'billingCycleAnchor': billingCycleAnchor?.toIso8601String(),
    'nextRenewalDate': nextRenewalDate?.toIso8601String(),
    'renewalDateCertainty': renewalDateCertainty.name,
    'trialEndDate': trialEndDate?.toIso8601String(),
    'status': status.name,
    'lastPaidAmount': lastPaidAmount,
    'upcomingPriceIncreaseAmount': upcomingPriceIncreaseAmount,
    'priceIncreaseEffectiveDate': priceIncreaseEffectiveDate?.toIso8601String(),
    'sourceType': sourceType,
    'sourceReference': sourceReference,
    'confidenceScore': confidenceScore,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastDetectedAt': lastDetectedAt?.toIso8601String(),
    'lastUserConfirmedAt': lastUserConfirmedAt?.toIso8601String(),
    'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
    'cancellationUrl': cancellationUrl,
    'cancellationUrlVerifiedAt': cancellationUrlVerifiedAt?.toIso8601String(),
    'cancellationUrlSource': cancellationUrlSource,
    'actionHistory': actionHistory.map((event) => event.toJson()).toList(),
  };

  factory SubscriptionRecord.fromJson(Map<String, dynamic> json) => SubscriptionRecord(
    id: json['id'] as String,
    providerName: json['providerName'] as String,
    category: (json['category'] as String?) ?? 'General',
    amount: (json['amount'] as num?)?.toDouble(),
    currency: (json['currency'] as String?) ?? 'USD',
    billingCadence: BillingCadence.values.byName((json['billingCadence'] as String?) ?? 'monthly'),
    billingCycleAnchor: _tryParse(json['billingCycleAnchor'] as String?),
    nextRenewalDate: _tryParse(json['nextRenewalDate'] as String?),
    renewalDateCertainty: RenewalDateCertainty.values.byName((json['renewalDateCertainty'] as String?) ?? 'unknown'),
    trialEndDate: _tryParse(json['trialEndDate'] as String?),
    status: SubscriptionStatus.values.byName((json['status'] as String?) ?? 'unknown'),
    lastPaidAmount: (json['lastPaidAmount'] as num?)?.toDouble(),
    upcomingPriceIncreaseAmount: (json['upcomingPriceIncreaseAmount'] as num?)?.toDouble(),
    priceIncreaseEffectiveDate: _tryParse(json['priceIncreaseEffectiveDate'] as String?),
    sourceType: (json['sourceType'] as String?) ?? 'manual',
    sourceReference: json['sourceReference'] as String?,
    confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
    notes: (json['notes'] as String?) ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    lastDetectedAt: _tryParse(json['lastDetectedAt'] as String?),
    lastUserConfirmedAt: _tryParse(json['lastUserConfirmedAt'] as String?),
    lastVerifiedAt: _tryParse(json['lastVerifiedAt'] as String?),
    cancellationUrl: json['cancellationUrl'] as String?,
    cancellationUrlVerifiedAt: _tryParse(json['cancellationUrlVerifiedAt'] as String?),
    cancellationUrlSource: json['cancellationUrlSource'] as String?,
    actionHistory: ((json['actionHistory'] as List?) ?? [])
        .map((event) => ActionEvent.fromJson(Map<String, dynamic>.from(event as Map)))
        .toList(),
  );

  static DateTime? _tryParse(String? value) => value == null || value.isEmpty ? null : DateTime.tryParse(value);
}

class AppState {
  AppState({
    required this.subscriptions,
    required this.pushEnabled,
    required this.emailFallbackEnabled,
    required this.inboxConnected,
    required this.weeklyDigestEnabled,
  });

  final List<SubscriptionRecord> subscriptions;
  final bool pushEnabled;
  final bool emailFallbackEnabled;
  final bool inboxConnected;
  final bool weeklyDigestEnabled;

  factory AppState.initial() => AppState(
    subscriptions: demoSubscriptions,
    pushEnabled: true,
    emailFallbackEnabled: true,
    inboxConnected: false,
    weeklyDigestEnabled: true,
  );

  Map<String, dynamic> toJson() => {
    'subscriptions': subscriptions.map((item) => item.toJson()).toList(),
    'pushEnabled': pushEnabled,
    'emailFallbackEnabled': emailFallbackEnabled,
    'inboxConnected': inboxConnected,
    'weeklyDigestEnabled': weeklyDigestEnabled,
  };

  factory AppState.fromJson(Map<String, dynamic> json) => AppState(
    subscriptions: ((json['subscriptions'] as List?) ?? [])
        .map((item) => SubscriptionRecord.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    pushEnabled: json['pushEnabled'] as bool? ?? true,
    emailFallbackEnabled: json['emailFallbackEnabled'] as bool? ?? true,
    inboxConnected: json['inboxConnected'] as bool? ?? false,
    weeklyDigestEnabled: json['weeklyDigestEnabled'] as bool? ?? true,
  );
}

class AppStateStore {
  static const _key = 'subscription_saver_app_state';

  Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return AppState.initial();
    return AppState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(AppState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = AppStateStore();
  late Future<void> _loader;
  AppState _state = AppState.initial();

  @override
  void initState() {
    super.initState();
    _loader = _load();
  }

  Future<void> _load() async {
    _state = await _store.load();
  }

  Future<void> _persist() => _store.save(_state);

  Future<void> _upsertRecord([SubscriptionRecord? record]) async {
    final result = await showModalBottomSheet<SubscriptionRecord>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SubscriptionEditor(record: record),
    );
    if (result == null) return;
    setState(() {
      final index = _state.subscriptions.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _state.subscriptions.insert(0, result);
      } else {
        _state.subscriptions[index] = result;
      }
    });
    await _persist();
  }

  Future<void> _trackAction(SubscriptionRecord record, ActionType type) async {
    final noteController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark ${type.label.toLowerCase()}'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Optional note'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    final updated = record.copyWith(
      status: type == ActionType.cancel ? SubscriptionStatus.canceled : record.status,
      actionHistory: [
        ActionEvent(type: type, timestamp: DateTime.now(), note: noteController.text.trim()),
        ...record.actionHistory,
      ],
    );
    setState(() {
      final index = _state.subscriptions.indexWhere((item) => item.id == record.id);
      _state.subscriptions[index] = updated;
    });
    await _persist();
  }

  Future<void> _toggleSetting(String key, bool value) async {
    setState(() {
      _state = AppState(
        subscriptions: _state.subscriptions,
        pushEnabled: key == 'push' ? value : _state.pushEnabled,
        emailFallbackEnabled: key == 'email' ? value : _state.emailFallbackEnabled,
        inboxConnected: key == 'inbox' ? value : _state.inboxConnected,
        weeklyDigestEnabled: key == 'digest' ? value : _state.weeklyDigestEnabled,
      );
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final upcoming = [..._state.subscriptions]
          ..sort((a, b) => (a.nextRenewalDate ?? DateTime(2100)).compareTo(b.nextRenewalDate ?? DateTime(2100)));
        final monthlySpend = _state.subscriptions
            .map((item) => item.monthlyEquivalent)
            .whereType<double>()
            .fold<double>(0, (a, b) => a + b);
        final annualSpend = _state.subscriptions
            .map((item) => item.annualEquivalent)
            .whereType<double>()
            .fold<double>(0, (a, b) => a + b);
        final incomplete = _state.subscriptions.where((item) => item.isIncomplete).length;
        final nextChargeSavings = _state.subscriptions
            .expand((item) => item.actionHistory.map((event) => (item, event)))
            .where((pair) => pair.$2.type == ActionType.cancel && pair.$1.amount != null)
            .fold<double>(0, (sum, pair) => sum + pair.$1.amount!);
        final monthlySavings = _state.subscriptions
            .where((item) => item.actionHistory.any((event) => event.type == ActionType.cancel))
            .map((item) => item.monthlyEquivalent ?? 0)
            .fold<double>(0, (a, b) => a + b);
        final trialSaves = _state.subscriptions
            .where((item) => item.status == SubscriptionStatus.canceled && item.actionHistory.any((event) => event.type == ActionType.cancel))
            .length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Subscription Saver Copilot'),
            actions: [
              IconButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (context) => SettingsSheet(
                      pushEnabled: _state.pushEnabled,
                      emailFallbackEnabled: _state.emailFallbackEnabled,
                      inboxConnected: _state.inboxConnected,
                      weeklyDigestEnabled: _state.weeklyDigestEnabled,
                      onToggle: _toggleSetting,
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _upsertRecord,
            icon: const Icon(Icons.add),
            label: const Text('Add subscription'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Track subscriptions and get reminded before they renew.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  MetricCard(title: 'Monthly spend', value: money(monthlySpend)),
                  MetricCard(title: 'Annual spend', value: money(annualSpend)),
                  MetricCard(title: 'Upcoming renewals', value: '${upcoming.where((item) => item.nextRenewalDate != null && item.status != SubscriptionStatus.canceled).length}'),
                  MetricCard(title: 'Incomplete records', value: '$incomplete'),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly digest / review queue', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DigestRow(icon: Icons.notifications_active_outlined, text: _state.pushEnabled ? 'Push reminders enabled' : 'Push denied, use fallback paths'),
                      DigestRow(icon: Icons.email_outlined, text: _state.emailFallbackEnabled ? 'Email fallback ready' : 'Email fallback off'),
                      DigestRow(icon: Icons.checklist_outlined, text: '$incomplete incomplete records need review'),
                      DigestRow(icon: Icons.search_outlined, text: _state.inboxConnected ? 'Gmail beta connected for candidate review' : 'Manual-only mode active, inbox beta not connected'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Savings tracker', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Avoided next charges: ${money(nextChargeSavings)}'),
                      Text('Normalized monthly savings: ${money(monthlySavings)}'),
                      Text('Trial-end saves: $trialSaves'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Subscriptions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._state.subscriptions.map(
                (record) => SubscriptionCard(
                  record: record,
                  onEdit: () => _upsertRecord(record),
                  onAction: (type) => _trackAction(record, type),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onAction,
  });

  final SubscriptionRecord record;
  final VoidCallback onEdit;
  final ValueChanged<ActionType> onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(record.providerName.isEmpty ? 'Unnamed subscription' : record.providerName, style: Theme.of(context).textTheme.titleMedium),
                ),
                FilledButton.tonal(onPressed: onEdit, child: const Text('Edit')),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(text: record.status.label),
                StatusChip(text: record.billingCadence.label),
                if (record.isRenewalSoon) const StatusChip(text: 'Renewal soon'),
                if (record.isIncomplete) const StatusChip(text: 'Incomplete'),
                if (record.upcomingPriceIncreaseAmount != null) const StatusChip(text: 'Price increase'),
                if (record.sourceType == 'inbox_beta') const StatusChip(text: 'Inbox beta'),
              ],
            ),
            const SizedBox(height: 12),
            Text('Next renewal: ${record.nextRenewalDate == null ? 'Unknown' : shortDate(record.nextRenewalDate!)} (${record.renewalDateCertainty.label.toLowerCase()})'),
            if (record.trialEndDate != null) Text('Trial end: ${shortDate(record.trialEndDate!)}'),
            Text('Spend: ${record.amount == null ? 'Missing amount' : '${money(record.amount!)} / ${record.billingCadence.label.toLowerCase()}'}'),
            Text('Category: ${record.category}'),
            if (record.cancellationUrl != null) Text('Cancellation guide: ${record.cancellationUrl}'),
            if (record.notes.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(record.notes),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(label: const Text('Keep'), onPressed: () => onAction(ActionType.keep)),
                ActionChip(label: const Text('Cancel'), onPressed: () => onAction(ActionType.cancel)),
                ActionChip(label: const Text('Downgrade'), onPressed: () => onAction(ActionType.downgraded)),
                ActionChip(label: const Text('Snooze'), onPressed: () => onAction(ActionType.snooze)),
                ActionChip(label: const Text('Undecided'), onPressed: () => onAction(ActionType.undecided)),
              ],
            ),
            if (record.actionHistory.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Recent actions', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              ...record.actionHistory.take(3).map(
                (event) => Text('${event.type.label} • ${shortDateTime(event.timestamp)}${event.note.isEmpty ? '' : ' • ${event.note}'}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SubscriptionEditor extends StatefulWidget {
  const SubscriptionEditor({super.key, this.record});

  final SubscriptionRecord? record;

  @override
  State<SubscriptionEditor> createState() => _SubscriptionEditorState();
}

class _SubscriptionEditorState extends State<SubscriptionEditor> {
  late final TextEditingController providerController;
  late final TextEditingController amountController;
  late final TextEditingController categoryController;
  late final TextEditingController notesController;
  late final TextEditingController cancellationController;
  SubscriptionStatus status = SubscriptionStatus.active;
  BillingCadence billingCadence = BillingCadence.monthly;
  RenewalDateCertainty certainty = RenewalDateCertainty.exact;
  DateTime? renewalDate;
  DateTime? trialEndDate;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    providerController = TextEditingController(text: record?.providerName ?? '');
    amountController = TextEditingController(text: record?.amount?.toString() ?? '');
    categoryController = TextEditingController(text: record?.category ?? 'General');
    notesController = TextEditingController(text: record?.notes ?? '');
    cancellationController = TextEditingController(text: record?.cancellationUrl ?? '');
    status = record?.status ?? SubscriptionStatus.active;
    billingCadence = record?.billingCadence ?? BillingCadence.monthly;
    certainty = record?.renewalDateCertainty ?? RenewalDateCertainty.exact;
    renewalDate = record?.nextRenewalDate;
    trialEndDate = record?.trialEndDate;
  }

  @override
  void dispose() {
    providerController.dispose();
    amountController.dispose();
    categoryController.dispose();
    notesController.dispose();
    cancellationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isRenewal) async {
    final initial = (isRenewal ? renewalDate : trialEndDate) ?? DateTime.now().add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDate: initial,
    );
    if (picked == null) return;
    setState(() {
      if (isRenewal) {
        renewalDate = picked;
      } else {
        trialEndDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, insets + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.record == null ? 'Add subscription' : 'Edit subscription', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(controller: providerController, decoration: const InputDecoration(labelText: 'Provider name')),
            const SizedBox(height: 12),
            TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (optional)')),
            const SizedBox(height: 12),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              initialValue: billingCadence,
              items: BillingCadence.values.map((item) => DropdownMenuItem(value: item, child: Text(item.label))).toList(),
              onChanged: (value) => setState(() => billingCadence = value!),
              decoration: const InputDecoration(labelText: 'Billing cadence'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              initialValue: status,
              items: SubscriptionStatus.values.map((item) => DropdownMenuItem(value: item, child: Text(item.label))).toList(),
              onChanged: (value) => setState(() => status = value!),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              initialValue: certainty,
              items: RenewalDateCertainty.values.map((item) => DropdownMenuItem(value: item, child: Text(item.label))).toList(),
              onChanged: (value) => setState(() => certainty = value!),
              decoration: const InputDecoration(labelText: 'Renewal date certainty'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Next renewal: ${renewalDate == null ? 'Unknown' : shortDate(renewalDate!)}')),
                TextButton(onPressed: () => _pickDate(true), child: const Text('Pick')),
                if (renewalDate != null) TextButton(onPressed: () => setState(() => renewalDate = null), child: const Text('Clear')),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Trial end: ${trialEndDate == null ? 'None' : shortDate(trialEndDate!)}')),
                TextButton(onPressed: () => _pickDate(false), child: const Text('Pick')),
                if (trialEndDate != null) TextButton(onPressed: () => setState(() => trialEndDate = null), child: const Text('Clear')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: cancellationController, decoration: const InputDecoration(labelText: 'Cancellation URL (optional)')),
            const SizedBox(height: 12),
            TextField(controller: notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                final now = DateTime.now();
                Navigator.pop(
                  context,
                  SubscriptionRecord(
                    id: widget.record?.id ?? now.microsecondsSinceEpoch.toString(),
                    providerName: providerController.text.trim(),
                    category: categoryController.text.trim().isEmpty ? 'General' : categoryController.text.trim(),
                    amount: amount,
                    currency: 'USD',
                    billingCadence: billingCadence,
                    nextRenewalDate: renewalDate,
                    renewalDateCertainty: certainty,
                    trialEndDate: trialEndDate,
                    status: status,
                    notes: notesController.text.trim(),
                    sourceType: widget.record?.sourceType ?? 'manual',
                    createdAt: widget.record?.createdAt ?? now,
                    updatedAt: now,
                    cancellationUrl: cancellationController.text.trim().isEmpty ? null : cancellationController.text.trim(),
                    cancellationUrlSource: cancellationController.text.trim().isEmpty ? null : 'manual curation',
                    cancellationUrlVerifiedAt: cancellationController.text.trim().isEmpty ? null : now,
                    actionHistory: widget.record?.actionHistory ?? [],
                  ),
                );
              },
              child: const Text('Save subscription'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    super.key,
    required this.pushEnabled,
    required this.emailFallbackEnabled,
    required this.inboxConnected,
    required this.weeklyDigestEnabled,
    required this.onToggle,
  });

  final bool pushEnabled;
  final bool emailFallbackEnabled;
  final bool inboxConnected;
  final bool weeklyDigestEnabled;
  final Future<void> Function(String key, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            value: pushEnabled,
            onChanged: (value) => onToggle('push', value),
            title: const Text('Push reminders'),
            subtitle: const Text('Trial: 3 days, 1 day, and day of. Annual: 14 days, 3 days, and day of.'),
          ),
          SwitchListTile(
            value: emailFallbackEnabled,
            onChanged: (value) => onToggle('email', value),
            title: const Text('Email fallback'),
            subtitle: const Text('Use email when push is denied or fails.'),
          ),
          SwitchListTile(
            value: weeklyDigestEnabled,
            onChanged: (value) => onToggle('digest', value),
            title: const Text('Weekly digest'),
            subtitle: const Text('Summarize upcoming renewals and incomplete records.'),
          ),
          SwitchListTile(
            value: inboxConnected,
            onChanged: (value) => onToggle('inbox', value),
            title: const Text('Gmail beta consent'),
            subtitle: const Text('Candidates only, no auto-created active subscriptions.'),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Trust mode: manual tracking works fully without inbox access. Imported data can be deleted independently from confirmed subscriptions.'),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(text));
  }
}

class DigestRow extends StatelessWidget {
  const DigestRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

String money(double value) => '\$${value.toStringAsFixed(2)}';
String shortDate(DateTime value) => '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String shortDateTime(DateTime value) => '${shortDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

final demoSubscriptions = [
  SubscriptionRecord(
    id: '1',
    providerName: 'Netflix',
    category: 'Entertainment',
    amount: 15.49,
    currency: 'USD',
    billingCadence: BillingCadence.monthly,
    nextRenewalDate: DateTime.now().add(const Duration(days: 3)),
    renewalDateCertainty: RenewalDateCertainty.exact,
    status: SubscriptionStatus.active,
    notes: 'Verified cancellation route stored with last-checked timestamp.',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    sourceType: 'manual',
    cancellationUrl: 'https://www.netflix.com/cancelplan',
    cancellationUrlSource: 'Provider help center',
    cancellationUrlVerifiedAt: DateTime.now(),
  ),
  SubscriptionRecord(
    id: '2',
    providerName: 'Duolingo',
    category: 'Education',
    amount: 84.0,
    currency: 'USD',
    billingCadence: BillingCadence.annual,
    nextRenewalDate: DateTime.now().add(const Duration(days: 20)),
    renewalDateCertainty: RenewalDateCertainty.exact,
    status: SubscriptionStatus.active,
    notes: 'Annual plan, normalized into monthly estimate.',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    sourceType: 'manual',
  ),
  SubscriptionRecord(
    id: '3',
    providerName: 'Calm trial',
    category: 'Wellness',
    amount: 69.99,
    currency: 'USD',
    billingCadence: BillingCadence.annual,
    nextRenewalDate: DateTime.now().add(const Duration(days: 5)),
    trialEndDate: DateTime.now().add(const Duration(days: 5)),
    renewalDateCertainty: RenewalDateCertainty.inferred,
    status: SubscriptionStatus.trial,
    notes: 'Trial contributes \$0 until paid period begins.',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    sourceType: 'inbox_beta',
    sourceReference: 'gmail:msg-001',
    confidenceScore: 0.82,
    lastDetectedAt: DateTime.now(),
  ),
  SubscriptionRecord(
    id: '4',
    providerName: 'Adobe Creative Cloud',
    category: 'Productivity',
    currency: 'USD',
    billingCadence: BillingCadence.monthly,
    renewalDateCertainty: RenewalDateCertainty.unknown,
    status: SubscriptionStatus.unknown,
    notes: 'Partial manual record saved for later review.',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    sourceType: 'manual',
  ),
];
