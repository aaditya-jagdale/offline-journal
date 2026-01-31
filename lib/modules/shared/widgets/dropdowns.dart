import 'package:flutter/material.dart';
import 'package:jrnl/modules/shared/widgets/colors.dart';
import 'package:jrnl/modules/shared/widgets/shadows.dart';

class CustomDropDown extends StatelessWidget {
  final String? selectedValue;
  final List<String> items;
  final Function(String?)? onChanged;
  final String? hintText;
  final String? Function(String?)? validator;

  const CustomDropDown({
    super.key,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      initialValue: selectedValue,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                border: Border.all(
                  color: state.hasError ? Colors.red : AppColors.black,
                ),
                boxShadow: [CustomShadows.customShadow],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),

              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: Text(
                    hintText ?? '',
                    style: TextStyle(color: AppColors.black25),
                  ),
                  value: selectedValue,
                  isExpanded: true,
                  onChanged: (value) {
                    onChanged?.call(value);
                    state.didChange(value);
                  },
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.black,
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  items: items.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class MultiSelectDropDown extends StatefulWidget {
  final List<String> selectedItems;
  final List<String> allItems;
  final Function(List<String>)? onChanged;
  final String? hintText;
  final FormFieldValidator<List<String>>? validator;

  const MultiSelectDropDown({
    super.key,
    required this.selectedItems,
    required this.allItems,
    required this.onChanged,
    this.hintText,
    this.validator,
  });

  @override
  State<MultiSelectDropDown> createState() => _MultiSelectDropDownState();
}

class _MultiSelectDropDownState extends State<MultiSelectDropDown> {
  List<String> get availableItems => widget.allItems
      .where((item) => !widget.selectedItems.contains(item))
      .toList();

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      validator: widget.validator,
      initialValue: widget.selectedItems,
      builder: (FormFieldState<List<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: state.hasError ? Colors.red : AppColors.black,
                  ),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: Text(
                    widget.hintText ?? 'Select items',
                    style: TextStyle(color: AppColors.black.withOpacity(0.4)),
                  ),
                  value: null, // Always null to show hint
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      final newSelectedItems = List<String>.from(
                        widget.selectedItems,
                      );
                      newSelectedItems.add(value);
                      widget.onChanged?.call(newSelectedItems);
                      state.didChange(newSelectedItems);
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.primary,
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  items: availableItems.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (widget.selectedItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 8,
                  children: widget.selectedItems.map((item) {
                    return Chip(
                      label: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: Colors.black,
                      deleteIcon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                      onDeleted: () {
                        final newSelectedItems = List<String>.from(
                          widget.selectedItems,
                        );
                        newSelectedItems.remove(item);
                        widget.onChanged?.call(newSelectedItems);
                        state.didChange(newSelectedItems);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
