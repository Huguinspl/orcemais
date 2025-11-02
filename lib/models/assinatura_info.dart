import 'package:cloud_firestore/cloud_firestore.dart';

class AssinaturaInfo {
  final String? url;
  final DateTime? data;

  AssinaturaInfo({this.url, this.data});

  factory AssinaturaInfo.fromMap(Map<String, dynamic> map) => AssinaturaInfo(
    url: map['url'],
    data:
        map['data'] != null
            ? (map['data'] is Timestamp
                ? (map['data'] as Timestamp).toDate()
                : DateTime.tryParse(map['data'].toString()))
            : null,
  );

  Map<String, dynamic> toMap() => {'url': url, 'data': data?.toIso8601String()};
}
