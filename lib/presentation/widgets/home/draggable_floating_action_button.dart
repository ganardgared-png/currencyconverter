import 'package:flutter/material.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';

class DraggableFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Function(Offset) onPositionChanged;
  
  const DraggableFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.onPositionChanged,
  });

  @override
  State<DraggableFloatingActionButton> createState() =>
      _DraggableFloatingActionButtonState();
}

class _DraggableFloatingActionButtonState
    extends State<DraggableFloatingActionButton> {
  late Offset _offset;

  @override
  void initState() {
    super.initState();
    _offset = const Offset(16, 16);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onLongPressStart: (details) {
        // Start dragging
      },
      child: Draggable(
        data: _offset,
        feedback: _buildFAB(),
        childWhenDragging: Container(),
        onDraggableCanceled: (velocity, offset) {
          // Constrain to screen bounds
          double dx = offset.dx;
          double dy = offset.dy;
          
          // Clamp the position
          dx = dx.clamp(0, screenSize.width - 56);
          dy = dy.clamp(0, screenSize.height - 100);
          
          setState(() {
            _offset = Offset(dx, dy);
          });
          
          widget.onPositionChanged(_offset);
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: _buildFAB(),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}
