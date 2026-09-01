/// Country row from `GET /countries` or static fallback.
class CountryItem {
  const CountryItem({
    required this.code,
    required this.flag,
    required this.name,
  });

  final String code;
  final String flag;
  final String name;

  factory CountryItem.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();
    return CountryItem(
      code: s(json['code']).toUpperCase(),
      flag: s(json['flag']).toUpperCase(),
      name: s(json['name']),
    );
  }
}
