import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../MedicationService.dart';


class MapboxLocationPicker extends StatefulWidget {
  final Point? initialLocation;
  final Function(Point) onLocationSelected;
  final bool readOnly;
  final List<Point>? additionalPoints;
  final String? searchHint;

  const MapboxLocationPicker({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
    this.readOnly = false,
    this.additionalPoints,
    this.searchHint,
  }) : super(key: key);

  @override
  State<MapboxLocationPicker> createState() => _MapboxLocationPickerState();
}

class _MapboxLocationPickerState extends State<MapboxLocationPicker> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  Point? _selectedLocation;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchError = '';
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _pointAnnotationManager?.deleteAll();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        if (!widget.readOnly) _buildSearchBar(),
        // Mapbox map
        SizedBox(
          height: 400,
          child: Stack(
            children: [
              MapWidget(
                cameraOptions: CameraOptions(
                  center: _selectedLocation ?? Point(coordinates: Position(31.2357, 30.0444)),
                  zoom: 13.0,
                ),
                onMapCreated: _onMapCreated,




              ),
              // Center PIN if not read-only
              if (!widget.readOnly)
                const Center(
                  child: Icon(Icons.location_pin, color: Colors.red, size: 36),
                ),
              // Location button
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        // Confirmation button
        if (!widget.readOnly)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _selectedLocation != null ? () => widget.onLocationSelected(_selectedLocation!) : null,
              style: ElevatedButton.styleFrom(

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Location'),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: widget.searchHint ?? 'Search for a location',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchResults = [];
                    _searchError = '';
                  });
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: _performSearch,
          ),
          if (_searchError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_searchError, style: const TextStyle(color: Colors.red)),
            ),
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length > 5 ? 5 : _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) => ListTile(
                  title: Text(_searchResults[index]['placeName'] ?? 'Unknown location'),
                  subtitle: Text(_searchResults[index]['address'] ?? ''),
                  onTap: () => _selectSearchResult(_searchResults[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded() async {
    await _addMarkers();
  }

  Future<void> _addMarkers() async {
    if (_mapboxMap == null) return;

    try {
      _pointAnnotationManager?.deleteAll();
      _pointAnnotationManager = await _mapboxMap!.annotations.createPointAnnotationManager();

      if (_selectedLocation != null) {
        await _addMarker(_selectedLocation!, 'selected-location');
        await _mapboxMap!.flyTo(
          CameraOptions(center: _selectedLocation!, zoom: 15.0),
          MapAnimationOptions(duration: 2000),
        );
      }

      if (widget.additionalPoints != null) {
        for (var i = 0; i < widget.additionalPoints!.length; i++) {
          await _addMarker(widget.additionalPoints![i], 'additional-point-$i');
        }
      }
    } catch (e) {
      debugPrint('Error adding markers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add markers: $e')),
        );
      }
    }
  }

  Future<void> _addMarker(Point point, String id) async {
    final options = PointAnnotationOptions(
      geometry: point,
      iconSize: 1.0,
      iconImage: 'marker-icon',
    );
    await _pointAnnotationManager?.create(options);
  }

  void _selectLocation(Point point) {
    setState(() {
      _selectedLocation = point;
    });
    _addMarkers();
  }

  Future<void> _getCurrentLocation() async {
    final medicationService = Provider.of<MedicationService>(context, listen: false);
    final location = medicationService.currentLocation;

    if (location != null && location.latitude != null && location.longitude != null) {
      final point = Point(coordinates: Position(location.longitude!, location.latitude!));
      _selectLocation(point);
      await _mapboxMap?.flyTo(
        CameraOptions(center: point, zoom: 15.0),
        MapAnimationOptions(duration: 2000),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get current location')),
        );
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = '';
      _searchResults = [];
    });

    try {
      // Simulated search results
      await Future.delayed(const Duration(seconds: 1));
      final queryLower = query.toLowerCase();

      if (queryLower.contains('cairo')) {
        _searchResults = [
          {
            'placeName': 'Cairo, Egypt',
            'address': 'Cairo Governorate, Egypt',
            'coordinates': {'lng': 31.2357, 'lat': 30.0444},
          },
          {
            'placeName': 'Cairo International Airport',
            'address': 'Cairo, Egypt',
            'coordinates': {'lng': 31.4036, 'lat': 30.1211},
          },
        ];
      } else if (queryLower.contains('alex')) {
        _searchResults = [
          {
            'placeName': 'Alexandria, Egypt',
            'address': 'Alexandria Governorate, Egypt',
            'coordinates': {'lng': 29.9187, 'lat': 31.2001},
          },
        ];
      } else if (queryLower.contains('giza')) {
        _searchResults = [
          {
            'placeName': 'Giza, Egypt',
            'address': 'Giza Governorate, Egypt',
            'coordinates': {'lng': 31.1348, 'lat': 29.9767},
          },
          {
            'placeName': 'Giza Pyramids',
            'address': 'Al Haram, Giza Governorate, Egypt',
            'coordinates': {'lng': 31.1342, 'lat': 29.9792},
          },
        ];
      } else {
        _searchError = 'No results found for "$query"';
      }
    } catch (e) {
      setState(() {
        _searchError = 'Error searching for locations: $e';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    setState(() {
      _searchResults = [];
      _searchController.text = result['placeName'] ?? '';
    });

    final coordinates = result['coordinates'];
    if (coordinates != null) {
      final point = Point(
        coordinates: Position(coordinates['lng'] as double, coordinates['lat'] as double),
      );
      _selectLocation(point);
      _mapboxMap?.flyTo(
        CameraOptions(center: point, zoom: 15.0),
        MapAnimationOptions(duration: 2000),
      );
    }
  }
}