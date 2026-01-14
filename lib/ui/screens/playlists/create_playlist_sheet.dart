import 'package:flutter/material.dart';

class CreatePlaylistSheet extends StatefulWidget {
  const CreatePlaylistSheet({
    super.key,
    required this.onCreate,
  });

  final ValueChanged<String> onCreate;

  @override
  State<CreatePlaylistSheet> createState() => _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends State<CreatePlaylistSheet> {
  final TextEditingController _controller = TextEditingController();
  String _title = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTitleChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTitleChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleTitleChanged() {
    setState(() {
      _title = _controller.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final canCreate = _title.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '새 플레이리스트 만들기',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Playlist name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: canCreate
                    ? () {
                        widget.onCreate(_title);
                        Navigator.of(context).pop();
                      }
                    : null,
                child: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}