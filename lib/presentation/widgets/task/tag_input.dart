import 'package:flutter/material.dart';

class TagInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  const TagInput({super.key, required this.tags, required this.onChanged});

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.tags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _controller.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _controller.clear();
      widget.onChanged(_tags);
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    widget.onChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Теги', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ..._tags.map((tag) => Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeTag(tag),
                  visualDensity: VisualDensity.compact,
                )),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '+ тег',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
