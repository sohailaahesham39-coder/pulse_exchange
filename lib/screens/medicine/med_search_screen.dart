import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/AppConstants.dart';
import '../../config/AppRoutes.dart';
import '../../model/MedicationModel.dart';
import '../../services/AuthService.dart';
import '../../services/MedicationRecommendationWidget.dart';
import '../../services/MedicationService.dart';
import '../../widget/common/CustomButton.dart';
import '../../widget/medication/MedCard.dart';

class MedSearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialType;

  const MedSearchScreen({
    Key? key,
    this.initialQuery,
    this.initialType,
  }) : super(key: key);

  @override
  State<MedSearchScreen> createState() => _MedSearchScreenState();
}

class _MedSearchScreenState extends State<MedSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  String? _selectedType;
  bool _nearbyOnly = false;
  double _searchRadius = 20.0;
  bool _nonExpiredOnly = true;
  String? _sortBy; // Sorting option
  String? _lastSearchQuery;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _selectedType = widget.initialType;

    // Debounced search on text change
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _searchMedications();
      });
    });

    _initializeAndLoad();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndLoad() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final medicationService = Provider.of<MedicationService>(context, listen: false);
      await medicationService.initLocation();
      await _searchMedications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing: $e')),
        );
      }
      debugPrint('Error initializing: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchMedications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _lastSearchQuery = _searchController.text.trim();
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final medicationService = Provider.of<MedicationService>(context, listen: false);

      if (!authService.isAuthenticated || authService.token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to continue')),
          );
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
        return;
      }

      await medicationService.fetchAvailableMedications(
        authService.token!,
        query: _searchController.text.isNotEmpty ? _searchController.text : null,
        type: _selectedType,
        radius: _nearbyOnly ? _searchRadius : null,
        nearbyOnly: _nearbyOnly,
        nonExpiredOnly: _nonExpiredOnly,
        sortBy: _sortBy,
      );

      if (medicationService.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(medicationService.errorMessage!)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching medications: $e')),
        );
      }
      debugPrint('Error searching medications: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterByType(String? type) {
    setState(() {
      _selectedType = type == _selectedType ? null : type;
    });
    _searchMedications();
  }

  void _toggleNearbyOnly(bool value) {
    setState(() {
      _nearbyOnly = value;
    });
    _searchMedications();
  }

  void _toggleNonExpiredOnly(bool value) {
    setState(() {
      _nonExpiredOnly = value;
    });
    _searchMedications();
  }

  void _setSortBy(String? value) {
    setState(() {
      _sortBy = value;
    });
    _searchMedications();
  }

  void _showFilterBottomSheet() {
    // Create temporary variables to hold modal state
    String? tempType = _selectedType;
    bool tempNearbyOnly = _nearbyOnly;
    double tempSearchRadius = _searchRadius;
    bool tempNonExpiredOnly = _nonExpiredOnly;
    String? tempSortBy = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Medications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Medication type
                const Text('Medication Type', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.medicationCategories.map((type) {
                    return FilterChip(
                      label: Text(type),
                      selected: tempType == type,
                      onSelected: (selected) {
                        setModalState(() {
                          tempType = selected ? type : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Location filter
                SwitchListTile(
                  title: const Text('Nearby Only'),
                  subtitle: const Text('Show medications in your area'),
                  value: tempNearbyOnly,
                  onChanged: (value) {
                    setModalState(() {
                      tempNearbyOnly = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                if (tempNearbyOnly) ...[
                  const Text('Search Radius'),
                  Slider(
                    value: tempSearchRadius,
                    min: 1.0,
                    max: 50.0,
                    divisions: 49,
                    label: '${tempSearchRadius.round()} km',
                    onChanged: (value) {
                      setModalState(() {
                        tempSearchRadius = value;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),
                // Non-expired filter
                SwitchListTile(
                  title: const Text('Non-Expired Only'),
                  subtitle: const Text('Show only medications that are not expired'),
                  value: tempNonExpiredOnly,
                  onChanged: (value) {
                    setModalState(() {
                      tempNonExpiredOnly = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                // Sort by
                const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tempSortBy,
                  hint: const Text('Select sorting'),
                  items: const [
                    DropdownMenuItem(value: 'createdAtDesc', child: Text('Newest First')),
                    DropdownMenuItem(value: 'createdAtAsc', child: Text('Oldest First')),
                    DropdownMenuItem(value: 'expiryDateAsc', child: Text('Expiring Soon')),
                    DropdownMenuItem(value: 'expiryDateDesc', child: Text('Expiring Later')),
                  ],
                  onChanged: (value) {
                    setModalState(() {
                      tempSortBy = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedType = null;
                            _nearbyOnly = false;
                            _searchRadius = 20.0;
                            _nonExpiredOnly = true;
                            _sortBy = null;
                          });
                          _searchMedications();
                        },
                        child: const Text('Clear All'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedType = tempType;
                            _nearbyOnly = tempNearbyOnly;
                            _searchRadius = tempSearchRadius;
                            _nonExpiredOnly = tempNonExpiredOnly;
                            _sortBy = tempSortBy;
                          });
                          _searchMedications();
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicationService = Provider.of<MedicationService>(context);
    final medications = medicationService.availableMedications;
    final recommendations = medicationService.recommendations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Medications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search medications...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchMedications();
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (_) => _searchMedications(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchMedications,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Active filters
          if (_selectedType != null || _nearbyOnly || !_nonExpiredOnly || _sortBy != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedType != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_selectedType!),
                          onDeleted: () {
                            setState(() {
                              _selectedType = null;
                            });
                            _searchMedications();
                          },
                        ),
                      ),
                    if (_nearbyOnly)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text('Nearby (${_searchRadius.round()} km)'),
                          onDeleted: () {
                            setState(() {
                              _nearbyOnly = false;
                            });
                            _searchMedications();
                          },
                        ),
                      ),
                    if (!_nonExpiredOnly)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: const Text('Include Expired'),
                          onDeleted: () {
                            setState(() {
                              _nonExpiredOnly = true;
                            });
                            _searchMedications();
                          },
                        ),
                      ),
                    if (_sortBy != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(
                            _sortBy == 'createdAtDesc'
                                ? 'Newest First'
                                : _sortBy == 'createdAtAsc'
                                ? 'Oldest First'
                                : _sortBy == 'expiryDateAsc'
                                ? 'Expiring Soon'
                                : 'Expiring Later',
                          ),
                          onDeleted: () {
                            setState(() {
                              _sortBy = null;
                            });
                            _searchMedications();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Recommendations section - shown only when searching
          if (recommendations.isNotEmpty && _lastSearchQuery != null && _lastSearchQuery!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: MedicationRecommendationWidget(
                recommendations: recommendations,
                originalMedicationName: _lastSearchQuery,
              ),
            ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : medications.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No medications found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try adjusting your search or filters',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Donate Medication',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.medDonate);
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.medRequest);
                    },
                    child: const Text('Request Medication'),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _searchMedications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: medications.length,
                itemBuilder: (context, index) {
                  final medication = medications[index];
                  return MedCard(
                    medication: medication,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.medDetails,
                        arguments: {'medicationId': medication.id},
                      );
                    },
                    onRequest: () => _requestMedication(medication),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.medDonate);
        },
        icon: const Icon(Icons.add),
        label: const Text('Donate'),
      ),
    );
  }

  Future<void> _requestMedication(MedicationModel medication) async {
    if (!medication.canBeRequested) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            medication.isExpired
                ? 'Cannot request expired medication'
                : medication.quantity <= 0
                ? 'No stock available'
                : 'Medication is not available for request',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Medication'),
        content: Text('Are you sure you want to request ${medication.name} (${medication.dosage})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final medicationService = Provider.of<MedicationService>(context, listen: false);

      if (!authService.isAuthenticated || authService.token == null) {
        throw Exception('User not authenticated');
      }

      final success = await medicationService.requestMedication(
        authService.token!,
        medication.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication requested successfully')),
        );
        // Navigate to dashboard
        Navigator.pushNamed(context, AppRoutes.medDashboard);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              medicationService.errorMessage ?? 'Failed to request medication',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting medication: $e')),
        );
      }
      debugPrint('Error requesting medication: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}