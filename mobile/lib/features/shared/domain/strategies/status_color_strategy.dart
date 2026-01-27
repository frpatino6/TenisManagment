import 'package:flutter/material.dart';

abstract class StatusColorStrategy {
  Color getColor(String status);
  String getLabel(String status);
  IconData getIcon(String status);
}
