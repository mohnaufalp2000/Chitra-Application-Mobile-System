class ReccPress {
  final String size;
  final String pressure;

  ReccPress({required this.size, required this.pressure});

  factory ReccPress.fromJson(Map<String, dynamic> json) {
    return ReccPress(size: json['size'], pressure: json['pressure']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['size'] = this.size;
    data['pressure'] = this.pressure;
    return data;
  }
}
