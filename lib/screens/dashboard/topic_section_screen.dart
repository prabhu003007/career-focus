import 'package:flutter/material.dart';

import '../../models/subject.dart';
import '../../models/topic.dart';
import '../../models/unit.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';

class TopicSectionScreen extends StatefulWidget {
  final Subject subject;
  final Unit unit;

  const TopicSectionScreen({
    super.key,
    required this.subject,
    required this.unit,
  });

  @override
  State<TopicSectionScreen> createState() =>
      _TopicSectionScreenState();
}

class _TopicSectionScreenState
    extends State<TopicSectionScreen> {
  final ApiService _api = ApiService();
  final TokenService _tokenService = TokenService();

  bool _loading = true;
  bool _selectionMode = false;
  bool _processingSelection = false;

  List<Topic> _topics = [];

  final Set<String> _selectedTopicIds = <String>{};

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  // ============================================================
  // LOAD TOPICS
  // ============================================================

  Future<void> _loadTopics() async {
    try {
      final token = await _tokenService.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        return;
      }

      final topics = await _api.getTopicsByUnit(
        token,
        widget.unit.id,
      );

      if (!mounted) return;

      setState(() {
        _topics = topics;
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

  // ============================================================
  // ADD TOPIC
  // ============================================================

  Future<Topic?> _createTopic(String name) async {
    final token = await _tokenService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication required.');
    }

    return _api.createTopic(
      token,
      subjectId: widget.subject.id,
      unitId: widget.unit.id,
      name: name,
    );
  }

  Future<void> _showAddTopicDialog() async {
    final topic = await showDialog<Topic?>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AddTopicDialog(
          onSave: _createTopic,
        );
      },
    );

    if (!mounted || topic == null) {
      return;
    }

    setState(() {
      _topics.add(topic);
    });

    _showMessage(
      'Topic added successfully.',
    );
  }

  // ============================================================
  // DELETE TOPIC
  // ============================================================

  Future<void> _showDeleteTopicConfirmation(
    Topic topic,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF101528),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: const Text(
            'Delete Topic?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Delete "${topic.name}"?',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFFB91C1C),
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
      final token =
          await _tokenService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication required.',
        );
      }

      await _api.deleteTopic(
        token,
        topic.id,
      );

      if (!mounted) return;

      setState(() {
        _topics.removeWhere(
          (item) => item.id == topic.id,
        );

        _selectedTopicIds.remove(
          topic.id,
        );
      });

      _showMessage(
        'Topic deleted successfully.',
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

  // ============================================================
  // SELECTION MODE
  // ============================================================

  void _enterSelectionMode() {
    setState(() {
      _selectionMode = true;
      _selectedTopicIds.clear();
    });
  }

  void _exitSelectionMode() {
    if (_processingSelection) {
      return;
    }

    setState(() {
      _selectionMode = false;
      _selectedTopicIds.clear();
    });
  }

  // ============================================================
  // SELECT / DESELECT TOPIC
  // ============================================================

  void _toggleTopicSelection(
    Topic topic,
  ) {
    if (_processingSelection) {
      return;
    }

    setState(() {
      if (_selectedTopicIds.contains(topic.id)) {
        _selectedTopicIds.remove(topic.id);
      } else {
        _selectedTopicIds.add(topic.id);
      }
    });
  }

  // ============================================================
  // SELECT ALL
  // ============================================================

  void _selectAllTopics() {
    if (_topics.isEmpty) {
      _showMessage(
        'There are no topics to select.',
        error: true,
      );
      return;
    }

    setState(() {
      _selectionMode = true;

      _selectedTopicIds
        ..clear()
        ..addAll(
          _topics.map(
            (topic) => topic.id,
          ),
        );
    });
  }

  // ============================================================
  // SELECTION ACTION DIALOG
  // ============================================================

  Future<void> _showSelectionActionDialog() async {
    if (_selectedTopicIds.isEmpty) {
      _showMessage(
        'Select at least one topic.',
        error: true,
      );
      return;
    }

    final action =
        await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF101528),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: const Text(
            'Update Topics',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            '${_selectedTopicIds.length} topic'
            '${_selectedTopicIds.length == 1 ? '' : 's'} selected.\n\n'
            'Choose the new completion status.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop('cancel');
              },
              child: const Text(
                'Cancel',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop('incomplete');
              },
              icon: const Icon(
                Icons.radio_button_unchecked,
              ),
              label: const Text(
                'Mark as Not Complete',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    Colors.orangeAccent,
                side: BorderSide(
                  color:
                      Colors.orangeAccent
                          .withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop('complete');
              },
              icon: const Icon(
                Icons.check_circle_outline,
              ),
              label: const Text(
                'Mark as Complete',
              ),
              style: FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF16A34A),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        action == null ||
        action == 'cancel') {
      return;
    }

    if (action == 'complete') {
      await _updateSelectedTopics(
        completed: true,
      );
    } else if (action == 'incomplete') {
      await _updateSelectedTopics(
        completed: false,
      );
    }
  }

  // ============================================================
  // UPDATE ONLY SELECTED TOPICS
  // ============================================================

  Future<void> _updateSelectedTopics({
    required bool completed,
  }) async {
    /*
     * IMPORTANT:
     *
     * Take a snapshot of ONLY the currently selected IDs.
     *
     * Select All only fills _selectedTopicIds.
     * If the user deselects topics afterward,
     * those IDs are removed from this set.
     *
     * Therefore ONLY this snapshot is updated.
     */

    final selectedIds =
        Set<String>.from(
      _selectedTopicIds,
    );

    if (selectedIds.isEmpty) {
      _showMessage(
        'Select at least one topic.',
        error: true,
      );
      return;
    }

    final selectedTopics = _topics
        .where(
          (topic) =>
              selectedIds.contains(
            topic.id,
          ),
        )
        .toList();

    if (selectedTopics.isEmpty) {
      _showMessage(
        'Selected topics could not be found.',
        error: true,
      );
      return;
    }

    setState(() {
      _processingSelection = true;
    });

    try {
      final token =
          await _tokenService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication required.',
        );
      }

      final updatedTopics = <Topic>[];

      /*
       * Only selectedTopics are sent to the backend.
       *
       * Nothing outside selectedIds is touched.
       */
      for (final topic in selectedTopics) {
        final updated =
            await _api.updateTopic(
          token,
          topic.id,
          completed: completed,
        );

        updatedTopics.add(updated);
      }

      if (!mounted) return;

      setState(() {
        for (final updated
            in updatedTopics) {
          final index =
              _topics.indexWhere(
            (topic) =>
                topic.id == updated.id,
          );

          if (index != -1) {
            _topics[index] = updated;
          }
        }

        _selectedTopicIds.clear();
        _selectionMode = false;
        _processingSelection = false;
      });

      _showMessage(
        completed
            ? '${updatedTopics.length} topic'
                '${updatedTopics.length == 1 ? '' : 's'} '
                'marked as complete.'
            : '${updatedTopics.length} topic'
                '${updatedTopics.length == 1 ? '' : 's'} '
                'marked as not complete.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _processingSelection = false;
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

  // ============================================================
  // SEARCH
  // ============================================================

  List<Topic> get _filteredTopics {
    if (_searchQuery.trim().isEmpty) {
      return _topics;
    }

    final query =
        _searchQuery.trim().toLowerCase();

    return _topics
        .where(
          (topic) => topic.name
              .toLowerCase()
              .contains(query),
        )
        .toList();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        duration:
            const Duration(seconds: 2),
        backgroundColor: error
            ? const Color(0xFF7F1D1D)
            : const Color(0xFF172554),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final completed = _topics
        .where(
          (topic) => topic.completed,
        )
        .length;

    final total = _topics.length;

    final progress = total == 0
        ? 0.0
        : completed / total;

    return Scaffold(
      backgroundColor:
          const Color(0xFF050914),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF050914),
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 21,
          ),
          onPressed: _selectionMode
              ? _exitSelectionMode
              : () =>
                  Navigator.of(context).pop(),
        ),

        title: _selectionMode
            ? Text(
                '${_selectedTopicIds.length} selected',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                ),
              )
            : Text(
                'UNIT ${widget.unit.unitNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

        actions: _selectionMode
            ? [
                IconButton(
                  tooltip:
                      'Update selected topics',
                  onPressed:
                      _processingSelection
                          ? null
                          : _showSelectionActionDialog,
                  icon: _processingSelection
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Color(0xFF34D399),
                          ),
                        )
                      : const Icon(
                          Icons.check_rounded,
                          color:
                              Color(0xFF34D399),
                          size: 27,
                        ),
                ),

                IconButton(
                  tooltip: 'Cancel',
                  onPressed:
                      _processingSelection
                          ? null
                          : _exitSelectionMode,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                  ),
                ),
              ]
            : [
                PopupMenuButton<String>(
                  color:
                      const Color(0xFF101528),
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                  onSelected: (value) {
                    if (value == 'select') {
                      _enterSelectionMode();
                    } else if (value ==
                        'select_all') {
                      _selectAllTopics();
                    } else if (value == 'add') {
                      _showAddTopicDialog();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .checklist_rounded,
                            color:
                                Color(0xFF22D3EE),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Select',
                            style: TextStyle(
                              color:
                                  Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'select_all',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .done_all_rounded,
                            color:
                                Color(0xFF34D399),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Select All',
                            style: TextStyle(
                              color:
                                  Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'add',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .add_circle_outline_rounded,
                            color:
                                Color(0xFFB8A7FF),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Add Topic',
                            style: TextStyle(
                              color:
                                  Colors.white,
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
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF8B5CF6),
              ),
            )
          : RefreshIndicator(
              color:
                  const Color(0xFF8B5CF6),
              onRefresh: _loadTopics,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  30,
                ),
                children: [
                  _buildHeader(
                    completed,
                    total,
                    progress,
                  ),

                  const SizedBox(height: 16),

                  if (_selectionMode)
                    _buildSelectionBar(),

                  if (_selectionMode)
                    const SizedBox(height: 14),

                  _buildSearch(),

                  const SizedBox(height: 16),

                  if (_filteredTopics.isEmpty)
                    _buildEmpty()
                  else
                    ...List.generate(
                      _filteredTopics.length,
                      (index) {
                        final topic =
                            _filteredTopics[index];

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child:
                              _buildTopicCard(
                            topic,
                            index,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    int completed,
    int total,
    double progress,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            const Color(0xFF0B1120),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF8B5CF6)
              .withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment:
                  Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child:
                      CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor:
                        Colors.white
                            .withValues(
                      alpha: 0.07,
                    ),
                    color:
                        const Color(0xFF8B5CF6),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.unit.name,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$completed completed • '
                  '${total - completed} remaining',
                  style:
                      const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color:
            const Color(0xFF0B1120),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white
              .withValues(alpha: 0.07),
        ),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration:
            const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white38,
          ),
          hintText:
              'Search topics...',
          hintStyle:
              TextStyle(
            color: Colors.white30,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECTION BAR
  // ============================================================

  Widget _buildSelectionBar() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFF0B1722),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              const Color(0xFF22D3EE)
                  .withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.touch_app_rounded,
            color:
                Color(0xFF22D3EE),
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _selectedTopicIds.isEmpty
                  ? 'Tap topics to select'
                  : '${_selectedTopicIds.length} selected',
              style:
                  const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          if (_selectedTopicIds.isNotEmpty)
            const Text(
              'TAP ✓ TO UPDATE',
              style: TextStyle(
                color:
                    Color(0xFF34D399),
                fontSize: 9,
                fontWeight:
                    FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // TOPIC CARD
  // ============================================================

  Widget _buildTopicCard(
    Topic topic,
    int index,
  ) {
    final completed = topic.completed;

    final selected =
        _selectedTopicIds.contains(
      topic.id,
    );

    /*
     * Completed topics always use green.
     *
     * Selection adds a cyan glow/border,
     * but does NOT remove the green
     * completed-state container.
     */

    final accent = completed
        ? const Color(0xFF34D399)
        : const Color(0xFF22D3EE);

    final containerColor = completed
        ? const Color(0xFF0B2A1B)
        : selected
            ? const Color(0xFF102A32)
            : const Color(0xFF0B1120);

    final borderColor = completed
        ? const Color(0xFF34D399)
        : selected
            ? const Color(0xFF22D3EE)
            : Colors.white.withValues(
                alpha: 0.07,
              );

    return GestureDetector(
      onTap: _selectionMode
          ? () =>
              _toggleTopicSelection(topic)
          : null,
      onLongPress: _selectionMode
          ? null
          : () =>
              _showDeleteTopicConfirmation(
            topic,
          ),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width:
                completed || selected
                    ? 1.4
                    : 1,
          ),
          boxShadow: completed
              ? [
                  BoxShadow(
                    color:
                        const Color(
                      0xFF34D399,
                    ).withValues(
                      alpha: 0.09,
                    ),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : selected
                  ? [
                      BoxShadow(
                        color:
                            const Color(
                          0xFF22D3EE,
                        ).withValues(
                          alpha: 0.10,
                        ),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 180,
              ),
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? const Color(
                        0xFF34D399,
                      ).withValues(
                        alpha: 0.15,
                      )
                    : selected
                        ? const Color(
                            0xFF22D3EE,
                          ).withValues(
                            alpha: 0.18,
                          )
                        : accent.withValues(
                            alpha: 0.10,
                          ),
                border: Border.all(
                  color: accent.withValues(
                    alpha: 0.45,
                  ),
                ),
              ),
              child: _selectionMode
                  ? Icon(
                      selected
                          ? Icons.check_rounded
                          : Icons
                              .circle_outlined,
                      color: selected
                          ? accent
                          : accent,
                      size: 21,
                    )
                  : completed
                      ? const Icon(
                          Icons.check_rounded,
                          color:
                              Color(0xFF34D399),
                          size: 20,
                        )
                      : Center(
                          child: Text(
                            '${index + 1}',
                            style:
                                TextStyle(
                              color: accent,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                        ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.name,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight:
                          completed
                              ? FontWeight.w700
                              : FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    completed
                        ? 'Completed'
                        : 'Not completed',
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            if (_selectionMode &&
                selected)
              Icon(
                Icons.check_circle_rounded,
                color: accent,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmpty() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 55,
        horizontal: 25,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFF0B1120),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white
              .withValues(alpha: 0.06),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            color:
                Color(0xFF8B5CF6),
            size: 48,
          ),
          SizedBox(height: 15),
          Text(
            'No topics found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Add topics to this unit to begin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD TOPIC DIALOG
// ============================================================

class AddTopicDialog extends StatefulWidget {
  final Future<Topic?> Function(
    String name,
  ) onSave;

  const AddTopicDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<AddTopicDialog> createState() =>
      _AddTopicDialogState();
}

class _AddTopicDialogState
    extends State<AddTopicDialog> {
  late final TextEditingController
      _controller;

  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name =
        _controller.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorText =
            'Please enter a topic name.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      final topic =
          await widget.onSave(name);

      if (!mounted) return;

      Navigator.of(context).pop(topic);
    } catch (error) {
      if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor:
          const Color(0xFF101528),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white
              .withValues(alpha: 0.08),
        ),
      ),
      title: const Text(
        'Add Topic',
        style: TextStyle(
          color: Colors.white,
          fontWeight:
              FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_saving,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration:
                InputDecoration(
              hintText:
                  'Topic name',
              hintStyle:
                  const TextStyle(
                color: Colors.white38,
              ),
              filled: true,
              fillColor:
                  const Color(0xFF080D1D),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                borderSide:
                    BorderSide.none,
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFF8B5CF6),
                ),
              ),
            ),
            onSubmitted:
                _saving
                    ? null
                    : (_) => _save(),
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
                  Navigator.of(context)
                      .pop();
                },
          child:
              const Text('Cancel'),
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
                    color:
                        Colors.white,
                  ),
                )
              : const Text(
                  'Add Topic',
                ),
        ),
      ],
    );
  }
}