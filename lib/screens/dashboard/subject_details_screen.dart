import 'package:flutter/material.dart';

import '../../models/subject.dart';
import '../../models/unit.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';
import 'topic_section_screen.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final Subject subject;

  const SubjectDetailsScreen({
    super.key,
    required this.subject,
  });

  @override
  State<SubjectDetailsScreen> createState() =>
      _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState
    extends State<SubjectDetailsScreen> {
  final ApiService _api = ApiService();
  final TokenService _tokenService = TokenService();

  bool _loading = true;

  List<Unit> _units = [];

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    try {
      final token = await _tokenService.getToken();

      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        return;
      }

      final units = await _api.getUnitsBySubject(
        token,
        widget.subject.id,
      );

      if (!mounted) return;

      setState(() {
        _units = units;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        error: true,
      );
    }
  }

  Future<Unit?> _saveUnit({
    required int unitNumber,
    required String name,
    Unit? existingUnit,
  }) async {
    final token = await _tokenService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Authentication required.');
    }

    if (existingUnit == null) {
      return _api.createUnit(
        token,
        subjectId: widget.subject.id,
        unitNumber: unitNumber,
        name: name,
      );
    }

    return _api.updateUnit(
      token,
      existingUnit.id,
      unitNumber: unitNumber,
      name: name,
    );
  }

  Future<void> _showUnitDialog({
    Unit? unit,
  }) async {
    final result = await showDialog<Unit?>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return UnitDialog(
          unit: unit,
          onSave: ({
            required int unitNumber,
            required String name,
          }) {
            return _saveUnit(
              unitNumber: unitNumber,
              name: name,
              existingUnit: unit,
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      if (unit == null) {
        _units.add(result);
      } else {
        final index = _units.indexWhere(
          (item) => item.id == result.id,
        );

        if (index != -1) {
          _units[index] = result;
        }
      }

      _units.sort(
        (a, b) => a.unitNumber.compareTo(
          b.unitNumber,
        ),
      );
    });

    _showMessage(
      unit == null
          ? 'Unit added successfully.'
          : 'Unit updated successfully.',
    );
  }

  Future<void> _deleteUnit(
    Unit unit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101528),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Delete Unit?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Delete Unit ${unit.unitNumber} '
            '"${unit.name}"?\n\n'
            'All topics inside this unit '
            'will also be deleted.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final token = await _tokenService.getToken();

      if (token == null || token.trim().isEmpty) {
        throw Exception('Authentication required.');
      }

      await _api.deleteUnit(
        token,
        unit.id,
      );

      if (!mounted) return;

      setState(() {
        _units.removeWhere(
          (item) => item.id == unit.id,
        );
      });

      _showMessage(
        'Unit deleted successfully.',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        error: true,
      );
    }
  }

  void _openUnit(Unit unit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TopicSectionScreen(
          subject: widget.subject,
          unit: unit,
        ),
      ),
    );
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error
            ? const Color(0xFF7F1D1D)
            : const Color(0xFF172554),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050914),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 21,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Units',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            color: const Color(0xFF101528),
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'add') {
                _showUnitDialog();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'add',
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: Color(0xFFB8A7FF),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Add Unit',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B5CF6),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF8B5CF6),
              backgroundColor: const Color(0xFF101528),
              onRefresh: _loadUnits,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  30,
                ),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  if (_units.isEmpty)
                    _buildEmpty()
                  else
                    ...List.generate(
                      _units.length,
                      (index) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _buildUnitCard(
                            _units[index],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF10182B),
            Color(0xFF0A1020),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF8B5CF6)
              .withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B5CF6)
                  .withValues(alpha: 0.12),
              border: Border.all(
                color: const Color(0xFF8B5CF6)
                    .withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFFB8A7FF),
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subject.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.subject.code
                    .trim()
                    .isNotEmpty)
                  Text(
                    widget.subject.code,
                    style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                const SizedBox(height: 5),
                Text(
                  '${_units.length} '
                  '${_units.length == 1 ? 'UNIT' : 'UNITS'}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(Unit unit) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openUnit(unit),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1120),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF22D3EE)
                .withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22D3EE)
                    .withValues(alpha: 0.08),
                border: Border.all(
                  color: const Color(0xFF22D3EE)
                      .withValues(alpha: 0.32),
                ),
              ),
              child: Center(
                child: Text(
                  '${unit.unitNumber}',
                  style: const TextStyle(
                    color: Color(0xFF22D3EE),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNIT ${unit.unitNumber}',
                    style: const TextStyle(
                      color: Color(0xFF22D3EE),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unit.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Open topics',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: const Color(0xFF101528),
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white38,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _showUnitDialog(
                    unit: unit,
                  );
                } else if (value == 'delete') {
                  _deleteUnit(unit);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: Color(0xFFB8A7FF),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Edit Unit',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFF87171),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Delete Unit',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 50,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 14),
          const Text(
            'No units yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create units to organize this subject into chapters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _showUnitDialog,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'Add Unit',
            ),
            style: FilledButton.styleFrom(
              backgroundColor:
                  const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// UNIT DIALOG
// ============================================================

class UnitDialog extends StatefulWidget {
  final Unit? unit;

  final Future<Unit?> Function({
    required int unitNumber,
    required String name,
  }) onSave;

  const UnitDialog({
    super.key,
    required this.unit,
    required this.onSave,
  });

  @override
  State<UnitDialog> createState() =>
      _UnitDialogState();
}

class _UnitDialogState extends State<UnitDialog> {
  late final TextEditingController
      _numberController;

  late final TextEditingController
      _nameController;

  bool _saving = false;

  String? _errorText;

  @override
  void initState() {
    super.initState();

    _numberController =
        TextEditingController(
      text: widget.unit?.unitNumber.toString() ?? '',
    );

    _nameController =
        TextEditingController(
      text: widget.unit?.name ?? '',
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    final numberText =
        _numberController.text.trim();

    final name =
        _nameController.text.trim();

    final number =
        int.tryParse(numberText);

    if (number == null || number < 1) {
      setState(() {
        _errorText =
            'Enter a valid unit number.';
      });

      return;
    }

    if (name.isEmpty) {
      setState(() {
        _errorText =
            'Enter a unit name.';
      });

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      final result = await widget.onSave(
        unitNumber: number,
        name: name,
      );

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _saving = false;
          _errorText =
              'Unable to save the unit.';
        });

        return;
      }

      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _errorText = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  InputDecoration _inputDecoration(
    String hint,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.white38,
      ),
      filled: true,
      fillColor: const Color(0xFF080D1D),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color: Color(0xFF8B5CF6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor:
          const Color(0xFF101528),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(24),
        side: BorderSide(
          color:
              Colors.white.withValues(
            alpha: 0.08,
          ),
        ),
      ),
      title: Text(
        widget.unit == null
            ? 'Add Unit'
            : 'Edit Unit',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _numberController,
            enabled: !_saving,
            keyboardType:
                TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration:
                _inputDecoration(
              'Unit Number',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            enabled: !_saving,
            autofocus:
                widget.unit != null,
            textInputAction:
                TextInputAction.done,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration:
                _inputDecoration(
              'Unit Name',
            ),
            onSubmitted:
                _saving ? null : (_) => _save(),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                _errorText!,
                style:
                    const TextStyle(
                  color:
                      Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text(
            'Cancel',
          ),
        ),
        FilledButton(
          onPressed:
              _saving ? null : _save,
          style:
              FilledButton.styleFrom(
            backgroundColor:
                const Color(0xFF8B5CF6),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.unit == null
                      ? 'Add Unit'
                      : 'Save',
                ),
        ),
      ],
    );
  }
}