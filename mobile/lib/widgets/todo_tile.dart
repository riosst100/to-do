import 'package:flutter/material.dart';

import '../date_utils.dart';
import '../models.dart';

// Deskripsi lebih panjang dari ini dipotong sampai diketuk "Selengkapnya"
const _collapseChars = 180;
const _collapseLines = 3;

class TodoTile extends StatefulWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.showDate = true,
    this.showCategory = true,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showDate;
  final bool showCategory;

  @override
  State<TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends State<TodoTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final description = todo.description ?? '';
    final isLong = description.length > _collapseChars || '\n'.allMatches(description).length >= _collapseLines;

    return InkWell(
      onTap: widget.onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: todo.isCompleted,
              onChanged: (_) => widget.onToggle(),
              semanticLabel: 'Tandai "${todo.title}" selesai',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                        color: todo.isCompleted ? muted : null,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: isLong && !_expanded ? _collapseLines : null,
                        overflow: isLong && !_expanded ? TextOverflow.ellipsis : null,
                        style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.4),
                      ),
                      if (isLong)
                        GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              _expanded ? 'Ringkas' : 'Selengkapnya',
                              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ),
                        ),
                    ],
                    if (widget.showCategory || widget.showDate) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (widget.showCategory)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              CircleAvatar(radius: 4, backgroundColor: todo.category.colorValue),
                              const SizedBox(width: 4),
                              Text(todo.category.name, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                            ]),
                          if (widget.showDate)
                            Text(formatDate(todo.dueDate), style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: muted,
              tooltip: 'Hapus',
              onPressed: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
