import 'package:intl/intl.dart';

class Formatters {
  static final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  static final date = DateFormat('dd/MM/yyyy');

  static String money(double v) => currency.format(v);
  static String dateStr(DateTime d) => date.format(d);
}