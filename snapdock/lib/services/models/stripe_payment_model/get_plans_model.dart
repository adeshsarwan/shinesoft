import 'dart:convert';
/// status : "success"
/// data : [{"id":"0b6b710c-99fe-4df4-b671-ff75ada39e0e","name":"Weekly Plan","description":"7 days full access","amount":"200.00","currency":"usd","plan_type":"weekly","duration_days":7,"stripe_price_id":"price_1THjwKKVD0ctOzK9chOaE0ev"},{"id":"44e88f34-042e-480e-8b7d-d1cccbbaef46","name":"Monthly Plan","description":"30 days full access","amount":"500.00","currency":"usd","plan_type":"monthly","duration_days":30,"stripe_price_id":"price_1THjwqKVD0ctOzK9XsbMilon"},{"id":"4570e0be-7daf-4314-a66b-fcdd65f1465b","name":"Yearly Plan","description":"365 days full access","amount":"2300.00","currency":"usd","plan_type":"yearly","duration_days":365,"stripe_price_id":"price_1THjx0KVD0ctOzK9X8n6dkZF"}]

GetPlansModel getPlansModelFromJson(String str) => GetPlansModel.fromJson(json.decode(str));
String getPlansModelToJson(GetPlansModel data) => json.encode(data.toJson());
class GetPlansModel {
  GetPlansModel({
      String? status, 
      List<Data>? data,}){
    _status = status;
    _data = data;
}

  GetPlansModel.fromJson(dynamic json) {
    _status = json['status'];
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(Data.fromJson(v));
      });
    }
  }
  String? _status;
  List<Data>? _data;
GetPlansModel copyWith({  String? status,
  List<Data>? data,
}) => GetPlansModel(  status: status ?? _status,
  data: data ?? _data,
);
  String? get status => _status;
  List<Data>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// id : "0b6b710c-99fe-4df4-b671-ff75ada39e0e"
/// name : "Weekly Plan"
/// description : "7 days full access"
/// amount : "200.00"
/// currency : "usd"
/// plan_type : "weekly"
/// duration_days : 7
/// stripe_price_id : "price_1THjwKKVD0ctOzK9chOaE0ev"

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());
class Data {
  Data({
      String? id, 
      String? name, 
      String? description, 
      String? amount, 
      String? currency, 
      String? planType, 
      num? durationDays, 
      String? stripePriceId,}){
    _id = id;
    _name = name;
    _description = description;
    _amount = amount;
    _currency = currency;
    _planType = planType;
    _durationDays = durationDays;
    _stripePriceId = stripePriceId;
}

  Data.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _description = json['description'];
    _amount = json['amount'];
    _currency = json['currency'];
    _planType = json['plan_type'];
    _durationDays = json['duration_days'];
    _stripePriceId = json['stripe_price_id'];
  }
  String? _id;
  String? _name;
  String? _description;
  String? _amount;
  String? _currency;
  String? _planType;
  num? _durationDays;
  String? _stripePriceId;
Data copyWith({  String? id,
  String? name,
  String? description,
  String? amount,
  String? currency,
  String? planType,
  num? durationDays,
  String? stripePriceId,
}) => Data(  id: id ?? _id,
  name: name ?? _name,
  description: description ?? _description,
  amount: amount ?? _amount,
  currency: currency ?? _currency,
  planType: planType ?? _planType,
  durationDays: durationDays ?? _durationDays,
  stripePriceId: stripePriceId ?? _stripePriceId,
);
  String? get id => _id;
  String? get name => _name;
  String? get description => _description;
  String? get amount => _amount;
  String? get currency => _currency;
  String? get planType => _planType;
  num? get durationDays => _durationDays;
  String? get stripePriceId => _stripePriceId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['description'] = _description;
    map['amount'] = _amount;
    map['currency'] = _currency;
    map['plan_type'] = _planType;
    map['duration_days'] = _durationDays;
    map['stripe_price_id'] = _stripePriceId;
    return map;
  }

}