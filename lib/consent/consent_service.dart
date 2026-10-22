/// Privacy / UMP consent abstraction. Core play never waits on consent failure.
enum ConsentStatus {
  unknown,
  required,
  obtained,
  notRequired,
  unavailable,
}

abstract class ConsentService {
  Future<ConsentStatus> gatherConsent();

  /// Whether ads may be requested after consent resolution.
  bool get canRequestAds;

  /// Opens privacy options form when available (UMP).
  Future<void> showPrivacyOptions();

  /// ATT prompt hook for iOS when tracking is requested (no-op if N/A).
  Future<void> requestTrackingAuthorizationIfNeeded();
}

/// Development consent: allows ads without blocking startup.
/// Replace with UMP-backed implementation when owner wires AdMob app IDs.
class PermissiveConsentService implements ConsentService {
  ConsentStatus _status = ConsentStatus.notRequired;

  ConsentStatus get status => _status;

  @override
  bool get canRequestAds =>
      _status == ConsentStatus.obtained ||
      _status == ConsentStatus.notRequired;

  @override
  Future<ConsentStatus> gatherConsent() async {
    _status = ConsentStatus.notRequired;
    return _status;
  }

  @override
  Future<void> showPrivacyOptions() async {
    // UMP PrivacyOptionsForm.showPrivacyOptionsForm() when production consent is wired.
  }

  @override
  Future<void> requestTrackingAuthorizationIfNeeded() async {
    // app_tracking_transparency requestTrackingAuthorization() when ATT is needed.
  }
}

/// Mock for tests.
class MockConsentService implements ConsentService {
  MockConsentService({bool allowAds = true}) : _allowAds = allowAds;

  bool _allowAds;
  ConsentStatus status = ConsentStatus.notRequired;
  int privacyOptionsOpens = 0;
  int attRequests = 0;

  set allowAds(bool value) => _allowAds = value;

  @override
  bool get canRequestAds => _allowAds;

  @override
  Future<ConsentStatus> gatherConsent() async => status;

  @override
  Future<void> showPrivacyOptions() async {
    privacyOptionsOpens++;
  }

  @override
  Future<void> requestTrackingAuthorizationIfNeeded() async {
    attRequests++;
  }
}
