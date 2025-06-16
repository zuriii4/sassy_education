import 'package:flutter/material.dart';

class TaskTypeStep extends StatelessWidget {
  final Function(String) onSelectType;
  
  const TaskTypeStep({Key? key, required this.onSelectType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Vyberte typ úlohy',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF67E4A),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildTaskTypeCard(
                  context,
                  'Quiz',
                  'Vytvorte kvíz s rôznymi otázkami a odpoveďami',
                  Icons.question_answer,
                  () => onSelectType('quiz'),
                ),
                _buildTaskTypeCard(
                  context,
                  'Puzzle',
                  'Vytvorte puzzle z obrázku rozdelením na mriežku',
                  Icons.extension,
                  () => onSelectType('puzzle'),
                ),
                _buildTaskTypeCard(
                  context,
                  'Word Jumble',
                  'Vytvorte úlohu na usporiadanie slov do správneho poradia',
                  Icons.sort_by_alpha,
                  () => onSelectType('word-jumble'),
                ),
                _buildTaskTypeCard(
                  context,
                  'Connections',
                  'Vytvorte úlohu na párovanie súvisiacich položiek',
                  Icons.compare_arrows,
                  () => onSelectType('connection'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTypeCard(BuildContext context, String title, String description, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: const Color(0xFFF67E4A),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}