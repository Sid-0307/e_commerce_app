import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HSCodeModel {
  final String section;
  final String hscode;
  final String description;
  final String parent;
  final int level;

  HSCodeModel({
    required this.section,
    required this.hscode,
    required this.description,
    required this.parent,
    required this.level,
  });

  factory HSCodeModel.fromJson(Map<String, dynamic> json) {
    int level;
    if (json['level'] is int) {
      level = json['level'];
    } else if (json['level'] is String) {
      level = int.tryParse(json['level']) ?? 0;
    } else {
      level = 0;
    }

    return HSCodeModel(
      section: json['section']?.toString() ?? '',
      hscode: json['hscode']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      parent: json['parent']?.toString() ?? '',
      level: level,
    );
  }

  String get truncatedDescription {
    return description.length > 35
        ? '${description.substring(0, 35)}...'
        : description;
  }

  @override
  String toString() => '$hscode - $truncatedDescription';
}

class HSCodeSearchWidget extends StatefulWidget {
  final String? initialValue;
  final Function(HSCodeModel?) onChanged;
  final String? labelText;
  final String? hintText;

  const HSCodeSearchWidget({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.labelText,
    this.hintText,
  }) : super(key: key);

  @override
  State<HSCodeSearchWidget> createState() => _HSCodeSearchWidgetState();
}

class _HSCodeSearchWidgetState extends State<HSCodeSearchWidget> {
  late final TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();
  bool _showDropdown = false;
  List<HSCodeModel> _allHSCodes = [];
  List<HSCodeModel> _filteredHSCodes = [];
  HSCodeModel? _selectedHSCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadHSCodes();

    _searchController.addListener(_onSearchTextChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _searchController.text.isNotEmpty) {
        setState(() {
          _showDropdown = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(HSCodeSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && widget.initialValue != null) {
      _setInitialValue();
    }
  }

  void _setInitialValue() {
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty && _allHSCodes.isNotEmpty) {
      final foundHSCode = _allHSCodes.firstWhere(
            (hsCode) => hsCode.hscode == widget.initialValue,
        orElse: () => HSCodeModel(
          section: '',
          hscode: '',
          description: '',
          parent: '',
          level: 0,
        ),
      );

      if (foundHSCode.hscode.isNotEmpty) {
        setState(() {
          _selectedHSCode = foundHSCode;
          _searchController.text = '${foundHSCode.hscode} - ${foundHSCode.description}';
        });
      }
    }
  }

  Future<void> _loadHSCodes() async {
    try {
      final String response = await rootBundle.loadString('assets/hscode.json');
      final data = json.decode(response) as List;

      setState(() {
        _allHSCodes = data.map((json) => HSCodeModel.fromJson(json)).toList();
        _filteredHSCodes = _allHSCodes;
        _isLoading = false;
      });

      _setInitialValue();
    } catch (e) {
      print('Error loading HS codes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchTextChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredHSCodes = _allHSCodes;
        _showDropdown = false;
        if (_selectedHSCode != null) {
          _selectedHSCode = null;
          widget.onChanged(null);
        }
      } else {
        _filteredHSCodes = _allHSCodes
            .where((hsCode) =>
        hsCode.hscode.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            hsCode.description.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
        _showDropdown = true;

        // Check if the text exactly matches a selected HS code
        final String fullText = '${_selectedHSCode?.hscode ?? ''} - ${_selectedHSCode?.description ?? ''}';
        if (_selectedHSCode != null && _searchController.text != fullText) {
          // User has modified the text but not selected a new item
          final exactMatch = _allHSCodes.where((hsCode) =>
          '${hsCode.hscode} - ${hsCode.description}' == _searchController.text ||
              hsCode.hscode == _searchController.text);

          if (exactMatch.isNotEmpty) {
            _selectedHSCode = exactMatch.first;
            widget.onChanged(_selectedHSCode);
          } else {
            _selectedHSCode = null;
            widget.onChanged(null);
          }
        }
      }
    });
  }

  void _selectHSCode(HSCodeModel hsCode) {
    setState(() {
      _selectedHSCode = hsCode;
      _searchController.text = '${hsCode.hscode} - ${hsCode.description}';
      _showDropdown = false;
    });
    widget.onChanged(hsCode);
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedHSCode = null;
      _showDropdown = false;
    });
    widget.onChanged(null);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.labelText!,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color:Colors.white,
              ),
            ),
          ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Type to search HS Code',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: _clearSearch,
                )
                    : const Icon(Icons.search, color: Colors.grey),
              ),
              onTap: () {
                if (_searchController.text.isNotEmpty) {
                  setState(() {
                    _showDropdown = true;
                  });
                }
              },
            ),
          ),

        // Dropdown
        if (_showDropdown && _filteredHSCodes.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredHSCodes.length,
              itemBuilder: (context, index) {
                final hsCode = _filteredHSCodes[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectHSCode(hsCode),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HS Code
                          Text(
                            hsCode.hscode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Description with expanded
                          Expanded(
                            child: Text(
                              hsCode.truncatedDescription,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}