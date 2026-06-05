import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/providers/auth_providers.dart';
import 'package:kloudshop/models/gcp_region.dart';

enum ProvisioningStep {
  storeSetup,
  infrastructure,
  loading,
  success,
  error,
}

enum AvailabilityStatus {
  none,
  checking,
  available,
  taken,
  invalid,
}

class ProvisioningState {
  final ProvisioningStep currentStep;
  final AvailabilityStatus availabilityStatus;
  final String tenantId;
  final String errorMessage;
  final String? selectedRegion;
  final List<String>? selectedFailoverRegions;
  final int currentLogStepIndex;
  final List<String> logs;
  final double? userLatitude;
  final double? userLongitude;

  ProvisioningState({
    required this.currentStep,
    required this.availabilityStatus,
    required this.tenantId,
    required this.errorMessage,
    this.selectedRegion,
    this.selectedFailoverRegions,
    required this.currentLogStepIndex,
    required this.logs,
    this.userLatitude,
    this.userLongitude,
  });

  factory ProvisioningState.initial() {
    return ProvisioningState(
      currentStep: ProvisioningStep.storeSetup,
      availabilityStatus: AvailabilityStatus.none,
      tenantId: '',
      errorMessage: '',
      selectedRegion: null,
      selectedFailoverRegions: null,
      currentLogStepIndex: 0,
      logs: [],
      userLatitude: null,
      userLongitude: null,
    );
  }

  ProvisioningState copyWith({
    ProvisioningStep? currentStep,
    AvailabilityStatus? availabilityStatus,
    String? tenantId,
    String? errorMessage,
    String? selectedRegion,
    List<String>? selectedFailoverRegions,
    bool clearFailoverRegions = false,
    int? currentLogStepIndex,
    List<String>? logs,
    double? userLatitude,
    double? userLongitude,
  }) {
    return ProvisioningState(
      currentStep: currentStep ?? this.currentStep,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      tenantId: tenantId ?? this.tenantId,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      selectedFailoverRegions: clearFailoverRegions
          ? null
          : (selectedFailoverRegions ?? this.selectedFailoverRegions),
      currentLogStepIndex: currentLogStepIndex ?? this.currentLogStepIndex,
      logs: logs ?? this.logs,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
    );
  }
}

final tenantProvisioningProvider =
    NotifierProvider<TenantProvisioningNotifier, ProvisioningState>(() {
      return TenantProvisioningNotifier();
    });

class TenantProvisioningNotifier extends Notifier<ProvisioningState> {
  Timer? _debounceTimer;
  Timer? _stepTimer;

  static const List<String> setupSteps = [
    'Validating database configuration',
    'Registering store URL handle: {tenantId}.kloudshop.com',
    'Spanning Cloud SQL instance ({region}) & database schema',
    'Running migrations and seeding demo data',
    'Synchronizing Firebase authentication credentials',
  ];

  @override
  ProvisioningState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _stepTimer?.cancel();
    });
    detectUserLocation();
    return ProvisioningState.initial();
  }

  void reset() {
    _debounceTimer?.cancel();
    _stepTimer?.cancel();
    final currentLat = state.userLatitude;
    final currentLon = state.userLongitude;
    state = ProvisioningState.initial().copyWith(
      userLatitude: currentLat,
      userLongitude: currentLon,
    );
  }

  Future<void> detectUserLocation() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lat = data['latitude'] as double?;
        final lon = data['longitude'] as double?;
        if (lat != null && lon != null) {
          state = state.copyWith(
            userLatitude: lat,
            userLongitude: lon,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to detect user location: $e');
    }
  }

  List<GcpRegion> getSortedRegions() {
    final lat = state.userLatitude;
    final lon = state.userLongitude;
    final list = gcpRegions.values.toList();
    if (lat == null || lon == null) {
      list.sort((a, b) {
        final comp = a.continent.compareTo(b.continent);
        if (comp != 0) return comp;
        return a.name.compareTo(b.name);
      });
      return list;
    }
    list.sort((a, b) {
      final distA = _calculateDistance(lat, lon, a.latitude, a.longitude);
      final distB = _calculateDistance(lat, lon, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });
    return list;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  double? getDistanceToRegion(String regionId) {
    final lat = state.userLatitude;
    final lon = state.userLongitude;
    if (lat == null || lon == null) return null;
    final region = gcpRegions[regionId];
    if (region == null) return null;
    return _calculateDistance(lat, lon, region.latitude, region.longitude);
  }

  void updateTenantId(String value) {
    final cleanValue = value.toLowerCase().trim().replaceAll(' ', '-');
    
    _debounceTimer?.cancel();
    
    if (cleanValue.isEmpty) {
      state = state.copyWith(
        tenantId: cleanValue,
        availabilityStatus: AvailabilityStatus.none,
        errorMessage: '',
      );
      return;
    }

    if (cleanValue.length < 3) {
      state = state.copyWith(
        tenantId: cleanValue,
        availabilityStatus: AvailabilityStatus.invalid,
        errorMessage: 'Minimum 3 characters required',
      );
      return;
    }

    final validFormat = RegExp(r'^[a-z0-9-]+$');
    if (!validFormat.hasMatch(cleanValue)) {
      state = state.copyWith(
        tenantId: cleanValue,
        availabilityStatus: AvailabilityStatus.invalid,
        errorMessage: 'Only lowercase letters, numbers, and hyphens allowed',
      );
      return;
    }

    if (cleanValue.startsWith('-') || cleanValue.endsWith('-') || cleanValue.contains('--')) {
      state = state.copyWith(
        tenantId: cleanValue,
        availabilityStatus: AvailabilityStatus.invalid,
        errorMessage: 'Cannot start/end with a hyphen, or contain consecutive hyphens',
      );
      return;
    }

    state = state.copyWith(
      tenantId: cleanValue,
      availabilityStatus: AvailabilityStatus.checking,
      errorMessage: '',
    );

    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _checkAvailability(cleanValue);
    });
  }

  Future<void> _checkAvailability(String tenantId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final isAvailable = await apiService.checkTenantAvailability(tenantId);
      
      if (state.tenantId != tenantId) return;

      if (isAvailable) {
        state = state.copyWith(
          availabilityStatus: AvailabilityStatus.available,
          errorMessage: '',
        );
      } else {
        state = state.copyWith(
          availabilityStatus: AvailabilityStatus.taken,
          errorMessage: 'This ID is already taken. Try another one!',
        );
      }
    } catch (e) {
      if (state.tenantId != tenantId) return;
      state = state.copyWith(
        availabilityStatus: AvailabilityStatus.none,
        errorMessage: 'Unable to verify availability. Please try again.',
      );
    }
  }

  void selectRegion(String region) {
    state = state.copyWith(selectedRegion: region);
  }

  void toggleFailoverRegion(String region, bool enabled) {
    final current = List<String>.from(state.selectedFailoverRegions ?? <String>[]);
    if (enabled) {
      if (!current.contains(region)) {
        current.add(region);
      }
    } else {
      current.remove(region);
    }
    
    if (current.isEmpty) {
      state = state.copyWith(clearFailoverRegions: true);
    } else {
      state = state.copyWith(selectedFailoverRegions: current);
    }
  }

  void proceedToInfrastructure() {
    if (state.availabilityStatus == AvailabilityStatus.available) {
      state = state.copyWith(currentStep: ProvisioningStep.infrastructure);
    }
  }

  void goBackToStoreSetup() {
    state = state.copyWith(currentStep: ProvisioningStep.storeSetup);
  }

  Future<void> provisionStore() async {
    final tenantId = state.tenantId;
    final selectedReg = state.selectedRegion;
    if (tenantId.isEmpty || state.availabilityStatus != AvailabilityStatus.available) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid, available store handle',
      );
      return;
    }
    if (selectedReg == null) {
      state = state.copyWith(
        errorMessage: 'Please select a primary GCP region first',
      );
      return;
    }

    final regionName = gcpRegions[selectedReg]?.name ?? selectedReg;
    final initializedLogs = setupSteps.map((step) {
      return step
          .replaceAll('{tenantId}', tenantId)
          .replaceAll('{region}', regionName);
    }).toList();

    state = state.copyWith(
      currentStep: ProvisioningStep.loading,
      currentLogStepIndex: 0,
      logs: initializedLogs,
      errorMessage: '',
    );

    _stepTimer?.cancel();

    final apiService = ref.read(apiServiceProvider);
    final authService = ref.read(authServiceProvider);

    bool apiFinished = false;
    bool apiSuccess = false;
    String apiErrorMsg = '';

    final apiFuture = apiService.provisionTenant(tenantId).then((res) {
      apiSuccess = true;
      apiFinished = true;
    }).catchError((err) {
      apiSuccess = false;
      apiFinished = true;
      apiErrorMsg = err.toString();
    });

    int currentStep = 0;
    
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) async {
      if (state.currentStep != ProvisioningStep.loading) {
        timer.cancel();
        return;
      }

      if (currentStep < 4) {
        if (apiFinished && !apiSuccess) {
          timer.cancel();
          state = state.copyWith(
            currentStep: ProvisioningStep.error,
            errorMessage: 'Provisioning failed: $apiErrorMsg',
          );
          return;
        }
        currentStep++;
        state = state.copyWith(currentLogStepIndex: currentStep);
      } else {
        timer.cancel();
        
        try {
          if (!apiFinished) {
            await apiFuture;
          }

          if (!apiSuccess) {
            state = state.copyWith(
              currentStep: ProvisioningStep.error,
              errorMessage: 'Provisioning failed: $apiErrorMsg',
            );
            return;
          }

          int retryCount = 0;
          bool synced = false;

          while (retryCount < 12 && !synced) {
            await Future.delayed(const Duration(milliseconds: 1000));
            try {
              await authService.getIdToken(forceRefresh: true);
              final claims = await apiService.getMe(forceRefresh: true);
              if (claims?.tenantId != null) {
                synced = true;
              }
            } catch (e) {
              debugPrint('Claims sync retry $retryCount failed: $e');
            }
            retryCount++;
          }

          if (synced) {
            ref.invalidate(userClaimsProvider);

            state = state.copyWith(
              currentStep: ProvisioningStep.success,
              currentLogStepIndex: 5,
            );
          } else {
            state = state.copyWith(
              currentStep: ProvisioningStep.error,
              errorMessage: 'Claims synchronization timed out. Please try signing in again.',
            );
          }
        } catch (e) {
          state = state.copyWith(
            currentStep: ProvisioningStep.error,
            errorMessage: 'Database Setup Error: ${e.toString()}',
          );
        }
      }
    });
  }
}

