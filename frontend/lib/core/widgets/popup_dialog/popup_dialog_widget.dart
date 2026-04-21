import 'package:first_try/core/utils/app_color.dart';
import 'package:first_try/core/utils/app_style.dart';
import 'package:flutter/material.dart';

class PopupDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  bool contentIsText;
  final String? contentText;
  final FontWeight? fontWeightTitle;
  final String primaryActionText;
  final void Function()? onPrimaryAction;
  final String? secondaryActionText;
  final void Function()? onSecondaryAction;
  final Color? backgroundColor;
  final Color? disableBackgroundColor;
  final Color? titleColor;
  final Color? contentTextColor;
  final Color? backgroundSecondaryButtonColor;
  final Color? textSecondaryButtonColor;
  final Color? backgroundPrimaryButtonColor;
  final Color? textPrimaryButtonColor;

  PopupDialog(
      {super.key,
      required this.title,
      this.content,
      required this.primaryActionText,
      required this.onPrimaryAction,
      this.secondaryActionText,
      this.disableBackgroundColor,
      this.contentText,
      this.onSecondaryAction,
      this.contentIsText = false,
      this.backgroundColor,
      this.titleColor,
      this.fontWeightTitle,
      this.contentTextColor,
      this.backgroundPrimaryButtonColor,
      this.backgroundSecondaryButtonColor,
      this.textPrimaryButtonColor,
      this.textSecondaryButtonColor});

  @override
  Widget build(BuildContext context, dynamic themeExtension) {
  

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: backgroundColor ??
          ColorManager.backgroundColor, // Background color
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                title,
                style: getSubTiltle(
                  fontWeight: fontWeightTitle,
                  color: titleColor ??
                      
                      ColorManager.textHeadTwo,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Content
              contentIsText
                  ? Text(
                      contentText ?? ' NO CONTENT',
                      style: getParagraph(
                        color: contentTextColor ??
                           
                            ColorManager.textParagraphs,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : Expanded(child: SingleChildScrollView(child: content!)),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (secondaryActionText != null && onSecondaryAction != null)
                    _buildButton(
                      disableBackgroundColor:
                          disableBackgroundColor ?? Colors.grey,
                      context: context,
                      label: secondaryActionText!,
                      onPressed: onSecondaryAction!,
                      backgroundColor: backgroundSecondaryButtonColor ??
                          themeExtension?.backgroundColor2 ??
                          ColorManager.secondGray,
                      textColor: textSecondaryButtonColor ??
                          themeExtension?.textColor ??
                          ColorManager.blackColor,
                    ),
                  const SizedBox(
                    width: 12,
                  ),
                  _buildButton(
                    disableBackgroundColor:
                        disableBackgroundColor ?? Colors.grey,
                    context: context,
                    label: primaryActionText,
                    onPressed: onPrimaryAction,
                    backgroundColor: backgroundPrimaryButtonColor ??
                        themeExtension?.secondaryColor ??
                        ColorManager.primaryColor,
                    textColor:
                        textPrimaryButtonColor ?? ColorManager.blackColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required void Function()? onPressed,
    required Color backgroundColor,
    required Color disableBackgroundColor,
    required Color textColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: disableBackgroundColor,
        elevation: 0,
        minimumSize: const Size(100, 40),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: getCustomTextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
