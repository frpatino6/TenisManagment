import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/version_service.dart';

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
  final VersionService _versionService = VersionService.instance;
  String _version = 'Cargando...';
  String _buildNumber = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVersion();
  }

  Future<void> _initializeVersion() async {
    try {
      await _versionService.initialize();
      if (mounted) {
        setState(() {
          _version = _versionService.displayVersion;
          _buildNumber = _versionService.buildNumber;
          _isInitialized = true;
        });
      }
    } catch (e) {
      // Fallback si hay error
      if (mounted) {
        setState(() {
          _version = 'v1.2.1';
          _buildNumber = '13';
          _isInitialized = true;
        });
      }
    }
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
          _versionService.appName,
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

/// Widget compacto para mostrar solo la versión
class VersionBadge extends StatelessWidget {
  final bool showBuildNumber;
  final EdgeInsets? margin;

  const VersionBadge({super.key, this.showBuildNumber = false, this.margin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: margin ?? const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: VersionWidget(
        showBuildNumber: showBuildNumber,
        textColor: colorScheme.onSurfaceVariant,
        textStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
