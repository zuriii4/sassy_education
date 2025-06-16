import 'package:flutter/material.dart';
import 'package:sassy/screens/teacher/material_steps/material_detail_screen.dart';

class MaterialUtils {
  // Get icon based on material type
  static IconData getMaterialIcon(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return Icons.question_answer;
      case 'connection':
        return Icons.sort_by_alpha;
      case 'word-jumble':
        return Icons.compare_arrows;
      case 'puzzle':
        return Icons.extension;
      default:
        return Icons.description; // Default icon
    }
  }

  // Get color based on material type
  static Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return Colors.blue;
      case 'connection':
        return Colors.green;
      case 'word-jumble':
        return Colors.purple;
      case 'puzzle':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class TemplateCard extends StatelessWidget {
  final Map<String, dynamic> template;
  final VoidCallback? onUseTemplate;
  final Function()? onRefresh;

  const TemplateCard({
    Key? key,
    required this.template,
    this.onUseTemplate,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final materialType = template['type'] ?? 'unknown';
    final typeColor = MaterialUtils.getTypeColor(materialType);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaterialDetailScreen(
              materialId: template['_id'],
            ),
          ),
        ).then((_) {
          if (onRefresh != null) onRefresh!();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      materialType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    MaterialUtils.getMaterialIcon(materialType),
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template['title'] ?? 'Bez názvu',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E2E48),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      template['description'] ?? 'Bez popisu',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            // Action buttons
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black12, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MaterialDetailScreen(
                            materialId: template['_id'],
                          ),
                        ),
                      ).then((_) {
                        if (onRefresh != null) onRefresh!();
                      });
                    },
                    icon: Icon(Icons.visibility, size: 16, color: typeColor),
                    label: const Text(
                      'Zobraziť',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                  // TextButton.icon(
                  //   onPressed: onUseTemplate,
                  //   icon: const Icon(Icons.content_copy, size: 16, color: Colors.blue),
                  //   label: const Text(
                  //     'Použiť',
                  //     style: TextStyle(fontSize: 12, color: Colors.blue),
                  //   ),
                  //   style: TextButton.styleFrom(
                  //     padding: const EdgeInsets.symmetric(horizontal: 8),
                  //     minimumSize: Size.zero,
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MaterialCard extends StatelessWidget {
  final String title;
  final String description;
  final String type;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSaveAsTemplate;

  const MaterialCard({
    Key? key,
    required this.title,
    required this.description,
    required this.type,
    this.onTap,
    this.onDelete,
    this.onSaveAsTemplate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typeColor = MaterialUtils.getTypeColor(type);
    
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      type.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    MaterialUtils.getMaterialIcon(type),
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            if (onDelete != null || onSaveAsTemplate != null)
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black12, width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onSaveAsTemplate != null)
                      IconButton(
                        icon: const Icon(Icons.bookmark_border, size: 18),
                        onPressed: onSaveAsTemplate,
                        tooltip: 'Uložiť ako šablónu',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: onDelete,
                        tooltip: 'Odstrániť',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.buttonText,
    required this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onButtonPressed,
            icon: Icon(icon),
            label: Text(
              buttonText,
              style: TextStyle(color: Colors.white),
              ),
            style: ElevatedButton.styleFrom(
              iconColor: Colors.white,
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    Key? key,
    required this.errorMessage,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Skúsiť znova'),
          ),
        ],
      ),
    );
  }
}