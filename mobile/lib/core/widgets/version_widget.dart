import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VersionWidget extends StatefulWidget {
  final bool showBuildNumber;
  final bool showFullInfo;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final Color? textColor;

  const VersionWidget({
    super.key,
    this.showBuildNumber = false,
    this.showFullInfo = false,
    this.padding,
    this.textStyle,
    this.textColor,
  });

  @override
  State<VersionWidget> createState() => _VersionWidgetState();
}

class _VersionWidgetState extends State<VersionWidget> {
  final String _version = 'v2.3.0';
  final String _buildNumber = '1';
  final bool _isInitialized = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    final textStyle =
        widget.textStyle ??
        GoogleFonts.inter(
          fontSize: 12,
          color: widget.textColor ?? colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        );

    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(8.0),
      child: widget.showFullInfo
          ? _buildFullInfo(textStyle)
          : _buildSimpleVersion(textStyle),
    );
  }

  Widget _buildSimpleVersion(TextStyle textStyle) {
    return Text(
      widget.showBuildNumber ? '$_version (Build $_buildNumber)' : _version,
      style: textStyle,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFullInfo(TextStyle textStyle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Tennis Management',
          style: textStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text('Versión $_version', style: textStyle),
        if (widget.showBuildNumber) ...[
          const SizedBox(height: 2),
          Text(
            'Build $_buildNumber',
            style: textStyle.copyWith(
              fontSize: 10,
              color: textStyle.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget compacto para mostrar solo la versión con el diseño original
class VersionBadge extends StatelessWidget {
  final bool showBuildNumber;
  final EdgeInsets? margin;

  const VersionBadge({super.key, this.showBuildNumber = false, this.margin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Tennis Management',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'v2.3.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          if (showBuildNumber) ...[
            const SizedBox(width: 4),
            Text(
              'Build 1',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
