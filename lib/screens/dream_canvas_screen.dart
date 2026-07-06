import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/canvas_project.dart';
import '../providers/canvas_provider.dart';
import '../providers/settings_provider.dart';
import '../services/image_gen_service.dart';
import '../widgets/gradient_mesh_background.dart';

const _canvasSize = 8000.0;
const _uuid = Uuid();

class DreamCanvasScreen extends StatefulWidget {
  final String? initialImageBase64;
  final String? initialPrompt;

  const DreamCanvasScreen({
    super.key,
    this.initialImageBase64,
    this.initialPrompt,
  });

  @override
  State<DreamCanvasScreen> createState() => _DreamCanvasScreenState();
}

enum _CanvasMode { view, select, connect, inpaint }

class _DreamCanvasScreenState extends State<DreamCanvasScreen> {
  final TransformationController _transformCtrl = TransformationController();
  _CanvasMode _mode = _CanvasMode.view;
  String? _selectedElementId;
  String? _connectSourceId;
  String? _draggingElementId;
  Offset _dragStart = Offset.zero;
  Offset _elementDragStart = Offset.zero;

  // inpainting state
  String? _inpaintElementId;
  Rect? _inpaintRect;
  Offset? _inpaintStart;

  // notes
  final _noteController = TextEditingController();

  // connection painter
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final provider = context.read<CanvasProvider>();
    if (provider.activeProject == null) {
      provider.createProject(title: 'Dream Canvas');
    }
    if (widget.initialImageBase64 != null) {
      final el = CanvasElement(
        id: _uuid.v4(),
        x: 200,
        y: 200,
        width: 300,
        height: 300,
        type: 'image',
        imageBase64: widget.initialImageBase64,
        imagePrompt: widget.initialPrompt ?? 'Generated image',
      );
      provider.addElement(el);
    }
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final provider = context.watch<CanvasProvider>();
    final project = provider.activeProject;

    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      appBar: _buildAppBar(accent, provider),
      body: project == null
          ? _buildEmptyState(accent, provider)
          : _buildCanvas(accent, provider),
    );
  }

  PreferredSizeWidget _buildAppBar(Color accent, CanvasProvider provider) {
    final project = provider.activeProject;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded,
            color: Colors.white.withOpacity(0.6)),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () => _showRenameDialog(accent, provider),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_outlined,
                size: 18, color: accent),
            const SizedBox(width: 8),
            Text(
              project?.title ?? 'Dream Canvas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined,
                size: 14, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.add_photo_alternate_outlined,
              color: Colors.white.withOpacity(0.6)),
          onPressed: () => _showAddImageDialog(accent, provider),
          tooltip: 'Add image',
        ),
        IconButton(
          icon: Icon(Icons.note_add_outlined,
              color: Colors.white.withOpacity(0.6)),
          onPressed: () => _addNote(accent, provider),
          tooltip: 'Add note',
        ),
        PopupMenuButton<_CanvasMode>(
          icon: Icon(Icons.tune, color: Colors.white.withOpacity(0.6)),
          color: const Color(0xFF1A1A2E),
          onSelected: (m) => setState(() => _mode = m),
          itemBuilder: (_) => [
            _modeItem('View', _CanvasMode.view, Icons.pan_tool_outlined),
            _modeItem('Select', _CanvasMode.select, Icons.touch_app_outlined),
            _modeItem('Connect', _CanvasMode.connect, Icons.timeline),
            _modeItem('Inpaint', _CanvasMode.inpaint, Icons.edit_outlined),
          ],
        ),
        IconButton(
          icon: Icon(Icons.file_download_outlined,
              color: Colors.white.withOpacity(0.6)),
          onPressed: () => _exportCanvas(context),
          tooltip: 'Export',
        ),
      ],
    );
  }

  PopupMenuItem<_CanvasMode> _modeItem(
      String label, _CanvasMode mode, IconData icon) {
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: _mode == mode
                  ? const Color(0xFF7C4DFF)
                  : Colors.white.withOpacity(0.6)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: _mode == mode
                  ? const Color(0xFF7C4DFF)
                  : Colors.white.withOpacity(0.8),
              fontFamily: 'Inter',
              fontWeight: _mode == mode ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (_mode == mode) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16, color: Color(0xFF7C4DFF)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color accent, CanvasProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_customize_outlined,
              size: 64, color: accent.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No canvas yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.createProject(title: 'Dream Canvas'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Canvas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas(Color accent, CanvasProvider provider) {
    final elements = provider.activeProject!.elements;
    final sorted = List<CanvasElement>.from(elements)
      ..sort((a, b) => a.zOrder.compareTo(b.zOrder));

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformCtrl,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.1,
          maxScale: 4,
          child: GestureDetector(
            onTapUp: (d) => _onCanvasTap(d, provider, sorted),
            child: SizedBox(
              width: _canvasSize,
              height: _canvasSize,
              child: Stack(
                children: [
                  // grid background
                  CustomPaint(
                    size: const Size(_canvasSize, _canvasSize),
                    painter: _GridPainter(),
                  ),
                  // connection lines
                  CustomPaint(
                    size: const Size(_canvasSize, _canvasSize),
                    painter: _ConnectionPainter(
                      elements: elements,
                      accent: accent,
                    ),
                  ),
                  // elements
                  ...sorted.map((el) => _buildElementWidget(el, accent, provider)),
                  // inpainting overlay
                  if (_inpaintElementId != null && _inpaintRect != null)
                    Positioned(
                      left: _inpaintRect!.left,
                      top: _inpaintRect!.top,
                      child: Container(
                        width: _inpaintRect!.width,
                        height: _inpaintRect!.height,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: accent,
                            width: 2,
                          ),
                          color: accent.withOpacity(0.1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // bottom toolbar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildToolbar(accent, provider),
        ),
        // inpaint prompt bar
        if (_inpaintElementId != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: _buildInpaintBar(accent, provider),
          ),
      ],
    );
  }

  Widget _buildElementWidget(
      CanvasElement el, Color accent, CanvasProvider provider) {
    final isSelected = _selectedElementId == el.id;
    final isConnectSource = _connectSourceId == el.id;

    return Positioned(
      left: el.x,
      top: el.y,
      child: GestureDetector(
        onTap: () => _onElementTap(el, provider),
        onLongPressStart: (d) => _onElementDragStart(d, el, provider),
        onLongPressMoveUpdate: (d) => _onElementDragMove(d, provider),
        onLongPressEnd: (_) => _onElementDragEnd(provider),
        child: _mode == _CanvasMode.inpaint && el.type == 'image'
            ? GestureDetector(
                onPanStart: (d) => _onInpaintStart(d, el),
                onPanUpdate: (d) => _onInpaintUpdate(d),
                onPanEnd: (_) => _onInpaintEnd(el, provider),
                child: _buildElementContent(el, accent, isSelected, isConnectSource),
              )
            : _buildElementContent(el, accent, isSelected, isConnectSource),
      ),
    );
  }

  Widget _buildElementContent(
      CanvasElement el, Color accent, bool isSelected, bool isConnectSource) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: el.width,
      height: el.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? accent
              : isConnectSource
                  ? Colors.greenAccent
                  : Colors.white.withOpacity(0.1),
          width: isSelected || isConnectSource ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: accent.withOpacity(0.2), blurRadius: 12)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: el.type == 'image'
            ? _buildImageElement(el, accent)
            : _buildNoteElement(el, accent),
      ),
    );
  }

  Widget _buildImageElement(CanvasElement el, Color accent) {
    if (el.imageBase64 == null) {
      return _buildEmptyElement(accent, Icons.image_outlined);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          base64Decode(el.imageBase64!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildEmptyElement(accent, Icons.broken_image),
        ),
        if (el.imagePrompt != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              color: Colors.black54,
              child: Text(
                el.imagePrompt!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoteElement(CanvasElement el, Color accent) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: el.color.withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, size: 12, color: el.color.withOpacity(0.6)),
              const Spacer(),
              GestureDetector(
                onTap: () => _editNote(el),
                child: Icon(Icons.edit_outlined,
                    size: 12, color: Colors.white.withOpacity(0.3)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                el.text ?? 'Note',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                  fontFamily: 'Inter',
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyElement(Color accent, IconData icon) {
    return Container(
      color: Colors.white.withOpacity(0.03),
      child: Center(
        child: Icon(icon, size: 32, color: accent.withOpacity(0.3)),
      ),
    );
  }

  // -- Interactions --

  void _onCanvasTap(
      TapUpDetails d, CanvasProvider provider, List<CanvasElement> sorted) {
    final scale = _transformCtrl.value.getMaxScaleOnAxis();
    final inverseMatrix = Matrix4.inverted(_transformCtrl.value);
    final localPos = MatrixUtils.transformPoint(inverseMatrix, d.localPosition);

    if (_mode == _CanvasMode.connect && _connectSourceId != null) {
      final target = sorted.where((e) =>
          (e.x <= localPos.dx && localPos.dx <= e.x + e.width) &&
          (e.y <= localPos.dy && localPos.dy <= e.y + e.height)).firstOrNull;
      if (target != null && target.id != _connectSourceId) {
        provider.connectElements(_connectSourceId!, target.id);
      }
      setState(() => _connectSourceId = null);
      return;
    }

    if (_mode == _CanvasMode.select) {
      setState(() => _selectedElementId = null);
    }
  }

  void _onElementTap(CanvasElement el, CanvasProvider provider) {
    if (_mode == _CanvasMode.connect) {
      if (_connectSourceId == null) {
        setState(() => _connectSourceId = el.id);
      } else if (_connectSourceId != el.id) {
        provider.connectElements(_connectSourceId!, el.id);
        setState(() => _connectSourceId = null);
      }
      return;
    }

    if (_mode == _CanvasMode.select) {
      setState(() => _selectedElementId = el.id);
      _showElementMenu(el, provider);
      return;
    }

    setState(() => _selectedElementId = el.id);
  }

  void _onElementDragStart(
      LongPressStartDetails d, CanvasElement el, CanvasProvider provider) {
    if (_mode != _CanvasMode.view) return;
    setState(() {
      _draggingElementId = el.id;
      _dragStart = d.globalPosition;
      _elementDragStart = Offset(el.x, el.y);
    });
  }

  void _onElementDragMove(LongPressMoveUpdateDetails d, CanvasProvider provider) {
    if (_draggingElementId == null) return;
    final scale = _transformCtrl.value.getMaxScaleOnAxis();
    final dx = (d.globalPosition.dx - _dragStart.dx) / scale;
    final dy = (d.globalPosition.dy - _dragStart.dy) / scale;
    final el = provider.activeProject?.elements
        .where((e) => e.id == _draggingElementId).firstOrNull;
    if (el == null) return;
    provider.moveElement(el.id, dx, dy);
    setState(() {
      _elementDragStart = Offset(el.x, el.y);
      _dragStart = d.globalPosition;
    });
  }

  void _onElementDragEnd(CanvasProvider provider) {
    setState(() => _draggingElementId = null);
  }

  // -- Inpainting --

  void _onInpaintStart(DragStartDetails d, CanvasElement el) {
    setState(() {
      _inpaintElementId = el.id;
      _inpaintStart = d.localPosition;
      _inpaintRect = Rect.fromPoints(d.localPosition, d.localPosition);
    });
  }

  void _onInpaintUpdate(DragUpdateDetails d) {
    if (_inpaintStart == null) return;
    setState(() {
      _inpaintRect = Rect.fromPoints(_inpaintStart!, d.localPosition);
    });
  }

  void _onInpaintEnd(CanvasElement el, CanvasProvider provider) {
    // region is set, prompt bar appears below
  }

  Widget _buildInpaintBar(Color accent, CanvasProvider provider) {
    final ctrl = TextEditingController();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Describe the edit for the selected region...',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18,
                color: Colors.white.withOpacity(0.5)),
            onPressed: () => setState(() {
              _inpaintElementId = null;
              _inpaintRect = null;
              _inpaintStart = null;
            }),
          ),
          IconButton(
            icon: Icon(Icons.auto_awesome, size: 18, color: accent),
            onPressed: () async {
              final prompt = ctrl.text.trim();
              if (prompt.isEmpty) return;
              await _runInpaint(prompt, provider);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _runInpaint(String editPrompt, CanvasProvider provider) async {
    if (_inpaintElementId == null || _inpaintRect == null) return;
    final el = provider.activeProject?.elements
        .where((e) => e.id == _inpaintElementId).firstOrNull;
    if (el == null) return;

    try {
      final service = ImageGenService();
      final context = el.imagePrompt ?? 'scene';
      final fullPrompt = '$context, $editPrompt';
      final result = await service.generateImage(fullPrompt);

      final newEl = CanvasElement(
        id: _uuid.v4(),
        x: el.x + el.width + 40,
        y: el.y,
        width: el.width,
        height: el.height,
        type: 'image',
        imageBase64: result,
        imagePrompt: fullPrompt,
      );
      provider.addElement(newEl);
      provider.connectElements(el.id, newEl.id);

      setState(() {
        _inpaintElementId = null;
        _inpaintRect = null;
        _inpaintStart = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit failed: $e')),
        );
      }
    }
  }

  // -- Notes --

  void _addNote(Color accent, CanvasProvider provider) {
    _noteController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('New Note',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _noteController,
          autofocus: true,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          decoration: InputDecoration(
            hintText: 'Type your note...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF7C4DFF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              final text = _noteController.text.trim();
              if (text.isNotEmpty) {
                final el = CanvasElement(
                  id: _uuid.v4(),
                  x: 200 + (provider.activeProject?.elements.length ?? 0) * 30,
                  y: 200 + (provider.activeProject?.elements.length ?? 0) * 30,
                  width: 180,
                  height: 120,
                  type: 'note',
                  text: text,
                  colorValue: accent.value,
                );
                provider.addElement(el);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add',
                style: TextStyle(color: Color(0xFF7C4DFF))),
          ),
        ],
      ),
    );
  }

  void _editNote(CanvasElement el) {
    _noteController.text = el.text ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Note',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _noteController,
          autofocus: true,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF7C4DFF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              final text = _noteController.text.trim();
              if (text.isNotEmpty) {
                el.text = text;
                final provider = context.read<CanvasProvider>();
                provider.updateElement(el.id, el);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save',
                style: TextStyle(color: Color(0xFF7C4DFF))),
          ),
        ],
      ),
    );
  }

  // -- Element Menu --

  void _showElementMenu(CanvasElement el, CanvasProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
                color: const Color(0xFF7C4DFF).withOpacity(0.2)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              el.type == 'image' ? 'Image' : 'Note',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _menuItem(Icons.vertical_align_top, 'Bring to Front', () {
              provider.bringToFront(el.id);
              Navigator.pop(ctx);
            }),
            _menuItem(Icons.timeline, 'Connect to...', () {
              Navigator.pop(ctx);
              setState(() {
                _mode = _CanvasMode.connect;
                _connectSourceId = el.id;
              });
            }),
            if (el.connectedTo.isNotEmpty)
              _menuItem(Icons.link_off, 'Remove Connections', () {
                el.connectedTo.clear();
                provider.updateElement(el.id, el);
                Navigator.pop(ctx);
              }),
            if (el.type == 'image')
              _menuItem(Icons.edit_outlined, 'Inpaint Region', () {
                Navigator.pop(ctx);
                setState(() {
                  _mode = _CanvasMode.inpaint;
                  _inpaintElementId = el.id;
                });
              }),
            _menuItem(
                Icons.delete_outline, 'Delete', () {
              provider.removeElement(el.id);
              Navigator.pop(ctx);
            }, danger: true),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    return ListTile(
      leading: Icon(icon,
          size: 20,
          color: danger
              ? Colors.redAccent
              : Colors.white.withOpacity(0.6)),
      title: Text(
        label,
        style: TextStyle(
          color: danger ? Colors.redAccent : Colors.white.withOpacity(0.8),
          fontFamily: 'Inter',
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }

  // -- Toolbar --

  Widget _buildToolbar(Color accent, CanvasProvider provider) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toolBtn(Icons.add_photo_alternate_outlined, 'Add Image', () {
            _showAddImageDialog(accent, provider);
          }, accent),
          _toolBtn(Icons.note_add_outlined, 'Add Note', () {
            _addNote(accent, provider);
          }, accent),
          _toolBtn(
              _mode == _CanvasMode.select
                  ? Icons.touch_app
                  : Icons.touch_app_outlined,
              'Select',
              () => setState(() {
                    _mode = _CanvasMode.select;
                  }), _mode == _CanvasMode.select ? accent : Colors.white54),
          _toolBtn(
              _mode == _CanvasMode.connect ? Icons.timeline : Icons.timeline_outlined,
              'Connect',
              () => setState(() {
                    _mode = _CanvasMode.connect;
                    _connectSourceId = null;
                  }), _mode == _CanvasMode.connect ? accent : Colors.white54),
          _toolBtn(
              _mode == _CanvasMode.inpaint
                  ? Icons.edit
                  : Icons.edit_outlined,
              'Inpaint',
              () => setState(() {
                    _mode = _CanvasMode.inpaint;
                  }), _mode == _CanvasMode.inpaint ? accent : Colors.white54),
          const Spacer(),
          _toolBtn(Icons.file_download_outlined, 'Export', () {
            _exportCanvas(context);
          }, accent),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String tooltip, VoidCallback onTap, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  // -- Add Image --

  void _showAddImageDialog(Color accent, CanvasProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Generate Image',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          decoration: InputDecoration(
            hintText: 'Describe the image to generate...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF7C4DFF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              final prompt = ctrl.text.trim();
              if (prompt.isEmpty) return;
              Navigator.pop(ctx);
              await _generateAndAddImage(prompt, provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndAddImage(
      String prompt, CanvasProvider provider) async {
    try {
      final service = ImageGenService();
      final base64 = await service.generateImage(prompt);
      final count = provider.activeProject?.elements.length ?? 0;
      final el = CanvasElement(
        id: _uuid.v4(),
        x: 200.0 + (count % 5) * 320,
        y: 200.0 + (count ~/ 5) * 320,
        width: 300,
        height: 300,
        type: 'image',
        imageBase64: base64,
        imagePrompt: prompt,
      );
      provider.addElement(el);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
      }
    }
  }

  // -- Export --

  Future<void> _exportCanvas(BuildContext context) async {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Canvas export coming soon. Take a screenshot for now!')),
    );
  }

  // -- Rename --

  void _showRenameDialog(Color accent, CanvasProvider provider) {
    final project = provider.activeProject;
    if (project == null) return;
    final ctrl = TextEditingController(text: project.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rename Canvas',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF7C4DFF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                provider.renameProject(project.id, name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save',
                style: TextStyle(color: Color(0xFF7C4DFF))),
          ),
        ],
      ),
    );
  }
}

// -- Painters --

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7C4DFF).withOpacity(0.04)
      ..strokeWidth = 0.5;

    const spacing = 80.0;
    for (var x = 0.0; x < _canvasSize; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, _canvasSize), paint);
    }
    for (var y = 0.0; y < _canvasSize; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(_canvasSize, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConnectionPainter extends CustomPainter {
  final List<CanvasElement> elements;
  final Color accent;

  _ConnectionPainter({required this.elements, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final el in elements) {
      for (final connId in el.connectedTo) {
        final target = elements.where((e) => e.id == connId).firstOrNull;
        if (target == null) continue;

        final from = Offset(el.x + el.width / 2, el.y + el.height / 2);
        final to = Offset(target.x + target.width / 2, target.y + target.height / 2);

        paint.color = accent.withOpacity(0.3);
        canvas.drawLine(from, to, paint);

        // arrow
        final angle = (to - from).direction;
        final arrowLen = 10.0;
        final arrowAngle = 0.5;
        canvas.drawPath(
          Path()
            ..moveTo(to.dx, to.dy)
            ..lineTo(
              to.dx - arrowLen * cos(angle - arrowAngle),
              to.dy - arrowLen * sin(angle - arrowAngle),
            )
            ..moveTo(to.dx, to.dy)
            ..lineTo(
              to.dx - arrowLen * cos(angle + arrowAngle),
              to.dy - arrowLen * sin(angle + arrowAngle),
            ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) =>
      oldDelegate.elements != elements;
}
