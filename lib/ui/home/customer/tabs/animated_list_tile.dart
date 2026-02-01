import 'package:flutter/material.dart';

class AnimatedListTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;
  final String? trailing;

  const AnimatedListTile({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
    this.trailing,
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedListTile> createState() => _AnimatedListTileState();
}

class _AnimatedListTileState extends State<AnimatedListTile>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _controller.addListener(() {
      setState(() {
        _scale = _controller.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.scale(
        scale: _scale,
        child: ListTile(
          leading: Icon(widget.icon, color: widget.color),
          title: Text(
            widget.title,
            style: TextStyle(
              color: widget.color == Colors.red ? Colors.red : Colors.black87,
              fontSize: 15,
            ),
          ),
          trailing: widget.trailing != null
              ? Text(
                  widget.trailing!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: widget.color,
                  ),
                )
              : Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                ),
        ),
      ),
    );
  }
}
