import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

String formatDate(DateTime? time) {
  return time == null ? '' : DateFormat('MMMM dd, yyyy').format(time);
}

String formatDateHelp(DateTime time) {
  return DateFormat('d/M/yyyy').format(time);
}

String? dateTimeToString(DateTime? date) {
  return date?.toIso8601String();
}

DateTime? parseDateTime(String? date) {
  if (date == null) return null;
  return DateTime.tryParse(date);
}

Duration? parseDuration(String? duration) {
  if (duration == null) return null;
  final parts = duration.split(':');
  if (parts.length != 2) return null;
  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  return Duration(hours: hours, minutes: minutes);
}

String? durationToString(Duration? duration) {
  if (duration == null) return null;
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '$hours:$minutes';
}

//! For upload File
Future<File?> pickDocument() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'], // Specify allowed file extensions
  );

  if (result != null) {
    return File(result.files.single.path!);
  } else {
    return null; // User canceled the picker
  }
}
