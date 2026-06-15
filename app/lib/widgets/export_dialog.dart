import 'package:flutter/material.dart';
import '../theme/hydrop_theme.dart';

class ExportOptionsPanel extends StatefulWidget {
  final bool isSidePanel;

  const ExportOptionsPanel({super.key, this.isSidePanel = false});

  @override
  State<ExportOptionsPanel> createState() => _ExportOptionsPanelState();
}

class _ExportOptionsPanelState extends State<ExportOptionsPanel> {
  String _selectedFormat = 'PDF';
  bool _includeGrid = false;
  bool _transparentBackground = false;

  Widget _buildFormatButton(String format, HydropTheme ht) {
    bool isSelected = _selectedFormat == format;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFormat = format;
          });
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: ht.space4),
          padding: EdgeInsets.symmetric(vertical: ht.space12),
          decoration: isSelected ? ht.buttonPressed : ht.buttonDefault,
          alignment: Alignment.center,
          child: Text(
            format,
            style: TextStyle(
              color: isSelected ? ht.textPrimary : ht.textSecondary,
              fontWeight: isSelected ? ht.fontBold : ht.fontMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged, HydropTheme ht) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ht.space8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: ht.textPrimary,
              fontWeight: ht.fontMedium,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ht.primary,
            activeTrackColor: ht.primary.withOpacity(0.3),
            inactiveThumbColor: ht.background,
            inactiveTrackColor: ht.divider,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, HydropTheme ht) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Export Options",
          style: TextStyle(
            fontSize: 20,
            fontWeight: ht.fontBold,
            color: ht.textPrimary,
          ),
        ),
        SizedBox(height: ht.space24),
        
        Text(
          "Format",
          style: TextStyle(
            fontSize: 14,
            fontWeight: ht.fontBold,
            color: ht.textSecondary,
          ),
        ),
        SizedBox(height: ht.space8),
        Row(
          children: [
            _buildFormatButton('PDF', ht),
            _buildFormatButton('PNG', ht),
            _buildFormatButton('SVG', ht),
          ],
        ),
        
        SizedBox(height: ht.space24),
        Text(
          "Settings",
          style: TextStyle(
            fontSize: 14,
            fontWeight: ht.fontBold,
            color: ht.textSecondary,
          ),
        ),
        SizedBox(height: ht.space8),
        Container(
          padding: EdgeInsets.all(ht.space12),
          decoration: ht.insetSurface,
          child: Column(
            children: [
              _buildToggle("Include Background Grid", _includeGrid, (v) => setState(() => _includeGrid = v), ht),
              Divider(color: ht.divider, height: 1),
              _buildToggle("Transparent Background", _transparentBackground, (v) => setState(() => _transparentBackground = v), ht),
            ],
          ),
        ),

        SizedBox(height: ht.space32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel", style: TextStyle(color: ht.textSecondary)),
            ),
            SizedBox(width: ht.space16),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exporting $_selectedFormat...')),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: ht.space24, vertical: ht.space12),
                decoration: ht.buttonDefault.copyWith(
                  border: ht.cardBorderStyle,
                ),
                child: Text(
                  "Export",
                  style: TextStyle(
                    color: ht.textPrimary,
                    fontWeight: ht.fontBold,
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);
    
    if (widget.isSidePanel) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 350,
          height: double.infinity,
          margin: EdgeInsets.all(ht.space16),
          padding: EdgeInsets.all(ht.space24),
          decoration: ht.raisedSurface,
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(child: _buildContent(context, ht)),
          ),
        ),
      );
    } else {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 400,
          padding: EdgeInsets.all(ht.space32),
          decoration: ht.raisedSurface,
          child: Material(
            type: MaterialType.transparency,
            child: _buildContent(context, ht),
          ),
        ),
      );
    }
  }
}
