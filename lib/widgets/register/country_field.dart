import 'package:flutter/material.dart';

class RegisterCountryField extends StatefulWidget {
  final String label;
  final IconData icon;
  final Function(String, String) onCountrySelected;

  const RegisterCountryField({
    Key? key,
    required this.label,
    required this.icon,
    required this.onCountrySelected,
  }) : super(key: key);

  @override
  _RegisterCountryFieldState createState() => _RegisterCountryFieldState();
}

class _RegisterCountryFieldState extends State<RegisterCountryField> {
  String? selectedCountryCode;
  String? selectedCountryName;
  bool isCustomInput = false;
  final TextEditingController customCountryController = TextEditingController();

  // ✅ 내부에서 국가 리스트 관리
  final Map<String, String> countryMap = {
    "KR": "South Korea",
    "US": "United States",
    "JP": "Japan",
    "CN": "China",
    "FR": "France",
    "DE": "Germany",
    "IT": "Italy",
    "BR": "Brazil",
    "GB": "United Kingdom",
    "IN": "India",
    "OTHER": "Other (Enter Manually)", // ✅ 직접 입력 옵션
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white, // ✅ 배경 흰색 적용
            shape: BoxShape.circle, // ✅ 원형 유지
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: TextStyle(color: Colors.grey, fontSize: 14), // ✅ LabelText 연한 회색 & 작은 폰트
              filled: true, // ✅ 배경 흰색 적용
              fillColor: Colors.white,
              prefixIcon: Icon(widget.icon, color: Colors.black, size: 20), // ✅ 아이콘 추가
              floatingLabelBehavior: FloatingLabelBehavior.never, // ✅ Label이 아이콘 위로 안 가게 함
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black), // ✅ 기본 상태에서 검은색 밑줄
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2.0), // ✅ 포커스 시 두꺼운 검은색 밑줄
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10), // ✅ 간격 줄이기
            ),
            value: selectedCountryCode,
            dropdownColor: Colors.white, // ✅ 드롭다운 전체 배경을 흰색으로 설정
            menuMaxHeight: 200, // ✅ 선택 리스트 팝업 윈도우의 최대 높이를 200px로 제한
            items: countryMap.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: IntrinsicWidth(
                  child: Text(entry.value, style: TextStyle(fontSize: 14, height: 1.2))
              ));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCountryCode = value;
                selectedCountryName = countryMap[value];
                isCustomInput = (value == "OTHER");
              });
              if (!isCustomInput) {
                widget.onCountrySelected(selectedCountryCode!, selectedCountryName!);
              }
            },
          ),
        ),
        // ✅ "기타(Other)" 선택 시 직접 입력 필드 활성화
        if (isCustomInput) SizedBox(height: 12),
        if (isCustomInput)
          TextField(
            style: TextStyle(height: 1.2), // ✅ 텍스트 높이 조절
            controller: customCountryController,
            decoration: InputDecoration(
              labelText: "직접 입력",
              labelStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2.0),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            ),
            onChanged: (value) {
              widget.onCountrySelected("CUSTOM", value); // ✅ 직접 입력한 국가 저장
            },
          ),
      ],
    );
  }
}
