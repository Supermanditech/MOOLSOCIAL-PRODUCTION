import 'package:flutter/foundation.dart';

import 'shared_models.dart';
import 'shared_services.dart';

class SharedIntentResult {
  const SharedIntentResult({
    required this.title,
    required this.detail,
    required this.action,
    required this.route,
  });

  final String title;
  final String detail;
  final String action;
  final String route;
}

class SharedSession extends ChangeNotifier {
  SharedSession({ReviewSharedGateway? gateway})
    : gateway = gateway ?? ReviewSharedGateway();

  final ReviewSharedGateway gateway;

  bool busy = false;
  bool online = true;
  bool authorized = true;
  bool cameraAllowed = true;
  bool microphoneAllowed = true;
  bool subscriptionActive = false;
  String? errorMessage;
  String? noticeMessage;
  String input = '';
  SharedIntentResult? inputResult;
  String pauseDuration = '1 hour';
  final Map<int, String> filters = <int, String>{};
  final Map<int, String> searches = <int, String>{};
  final Map<String, bool> _controlValues = <String, bool>{};
  final Set<String> _completedActions = <String>{};

  String filterFor(SharedScreenSpec spec) =>
      filters[spec.screen] ?? spec.filters.first;

  String searchFor(int screen) => searches[screen] ?? '';

  void clearMessages() {
    errorMessage = null;
    noticeMessage = null;
  }

  void dismissMessages() {
    clearMessages();
    notifyListeners();
  }

  void setOnline(bool value) {
    online = value;
    clearMessages();
    notifyListeners();
  }

  void setAuthorized(bool value) {
    authorized = value;
    clearMessages();
    notifyListeners();
  }

  void setFilter(int screen, String value) {
    filters[screen] = value;
    clearMessages();
    notifyListeners();
  }

  void setSearch(int screen, String value) {
    searches[screen] = value;
    clearMessages();
    notifyListeners();
  }

  void resetDiscovery(SharedScreenSpec spec) {
    filters[spec.screen] = spec.filters.first;
    searches[spec.screen] = '';
    clearMessages();
    notifyListeners();
  }

  List<SharedItem> visibleItems(SharedScreenSpec spec) {
    final selected = filterFor(spec);
    final query = searchFor(spec.screen).trim().toLowerCase();
    return spec.items
        .where((item) {
          final categoryMatch =
              selected == spec.filters.first || item.category == selected;
          final searchMatch =
              query.isEmpty ||
              '${item.title} ${item.summary} ${item.meta} ${item.category}'
                  .toLowerCase()
                  .contains(query);
          return categoryMatch && searchMatch;
        })
        .toList(growable: false);
  }

  String actionId(int screen, String itemId, String action) =>
      'SHARED-$screen-${itemId.toUpperCase()}-${action.toUpperCase()}';

  bool actionComplete(String id) => _completedActions.contains(id);

  bool controlValue(SharedItem item, SharedControl control) {
    return _controlValues.putIfAbsent(
      '${item.id}:${control.id}',
      () => control.initialValue,
    );
  }

  bool toggleControl(SharedItem item, SharedControl control, bool value) {
    if (control.locked) {
      errorMessage =
          control.lockedMessage ?? 'This protection cannot be changed here.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (control.subscriptionRequired && value && !subscriptionActive) {
      errorMessage =
          'Choose and activate a monthly plan before enabling Mool Agent.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    _controlValues['${item.id}:${control.id}'] = value;
    _completedActions.remove(actionId(165, item.id, 'primary'));
    clearMessages();
    notifyListeners();
    return true;
  }

  void setPauseDuration(String value) {
    pauseDuration = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> execute({
    required String id,
    required String outcome,
    String? confirmation,
    bool confirmed = false,
  }) async {
    if (_completedActions.contains(id)) {
      errorMessage = null;
      noticeMessage = 'Action already complete. No duplicate was created.';
      notifyListeners();
      return true;
    }
    if (confirmation != null && !confirmed) {
      errorMessage = 'Review and confirm the effect of this action first.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (!online) {
      errorMessage =
          'You are offline. Nothing changed. Reconnect and retry the same action.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (!authorized) {
      errorMessage =
          'Your current role cannot complete this action. Nothing changed.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      await gateway.execute(id);
      _completedActions.add(id);
      noticeMessage = outcome.replaceAll(
        'the selected end time',
        pauseDuration,
      );
      errorMessage = null;
      return true;
    } on SharedGatewayException catch (error) {
      errorMessage = error.message;
      noticeMessage = null;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void updateInput(String value) {
    input = value;
    inputResult = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> resolveInput() async {
    final normalized = input.trim().toLowerCase();
    if (normalized.length < 3) {
      errorMessage = 'Type at least 3 characters, or choose Scan or Voice.';
      noticeMessage = null;
      inputResult = null;
      notifyListeners();
      return false;
    }
    final result = switch (normalized) {
      final value when value.contains('atta') || value.contains('grocery') =>
        const SharedIntentResult(
          title: 'Atta under ₹300 delivered today',
          detail:
              'Compare final price, pack, delivery and refund before adding.',
          action: 'See matching atta',
          route: '/app/buy/grocery',
        ),
      final value when value.contains('cab') || value.contains('airport') =>
        const SharedIntentResult(
          title: 'Book a cab to Jodhpur Airport',
          detail:
              'Confirm pickup, arrival estimate and fare before requesting.',
          action: 'Set pickup',
          route: '/app/ride/book?type=cab',
        ),
      final value when value.contains('order') => const SharedIntentResult(
        title: 'Today’s retailer orders',
        detail: 'Open the authorized Mahadev Fresh Mart order queue.',
        action: 'Open orders',
        route: '/app/retailer',
      ),
      final value when value.contains('work') || value.contains('job') =>
        const SharedIntentResult(
          title: 'Paid work near you',
          detail: 'Review funding, output, proof and payout before applying.',
          action: 'See opportunities',
          route: '/app/earn',
        ),
      _ => null,
    };
    if (result == null) {
      errorMessage =
          'No exact action matched. Add a product, service, place or workspace name.';
      noticeMessage = null;
      inputResult = null;
      notifyListeners();
      return false;
    }
    final resultId = switch (result.route) {
      '/app/buy/grocery' => 'BUY',
      '/app/ride/book?type=cab' => 'RIDE',
      '/app/retailer' => 'RETAILER',
      '/app/earn' => 'EARN',
      _ => 'ACTION',
    };
    final success = await execute(
      id: 'SHARED-159-ASK-$resultId',
      outcome: 'Exact action found. Review it before continuing.',
    );
    if (success) inputResult = result;
    notifyListeners();
    return success;
  }

  void useSuggestedInput(String value) {
    input = value;
    inputResult = null;
    clearMessages();
    notifyListeners();
  }

  bool startScanner() {
    clearMessages();
    if (!cameraAllowed) {
      errorMessage =
          'Camera access is off. Allow it in device settings or enter the code.';
      notifyListeners();
      return false;
    }
    noticeMessage =
        'Scanner opened for a product, shop, bill or payment QR. Nothing is paid automatically.';
    notifyListeners();
    return true;
  }

  bool startVoice() {
    clearMessages();
    if (!microphoneAllowed) {
      errorMessage =
          'Microphone access is off. Allow it in device settings or type instead.';
      notifyListeners();
      return false;
    }
    input = 'atta under ₹300 delivered today';
    noticeMessage = 'Voice captured. Review the words before searching.';
    notifyListeners();
    return true;
  }

  void completeLocal(String message) {
    errorMessage = null;
    noticeMessage = message;
    notifyListeners();
  }
}
