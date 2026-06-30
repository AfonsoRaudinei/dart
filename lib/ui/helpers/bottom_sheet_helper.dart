import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

Future<T?> showSoloBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isActionSheet = false,
  bool isScrollControlled = true,
  Color backgroundColor = Colors.transparent,
}) {
  if (Platform.isIOS && isActionSheet) {
    return showCupertinoModalPopup<T>(context: context, builder: builder);
  }
  return showSoloForteSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: false,
    backgroundColor: backgroundColor,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(child: builder(ctx)),
    ),
  );
}
