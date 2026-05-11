import 'package:flutter/material.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';

class DataTableWidget extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;
  final String? title;
  
  const DataTableWidget({
    super.key,
    required this.columns,
    required this.rows,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(
                  isDark ? AppColors.darkSurface : Colors.grey[100],
                ),
                columns: columns.map((col) {
                  return DataColumn(
                    label: Text(
                      col,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                rows: rows.map((row) {
                  return DataRow(
                    cells: row.map((cell) {
                      return DataCell(
                        Text(cell),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}