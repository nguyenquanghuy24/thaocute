import 'package:intl/intl.dart';

String formatCurrency(num value) =>
    NumberFormat('#,###', 'vi_VN').format(value);
