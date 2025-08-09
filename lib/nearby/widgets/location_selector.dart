import 'package:flutter/material.dart';

class LocationSelector extends StatefulWidget {
  final String region;

  const LocationSelector({
    super.key,
    required this.region
  });
  
  @override
  _LocationSelectorState createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  // ✅ 이제 이 변수는 초기값으로 widget.region을 사용합니다.
  late String selectedRegion;

  List<String> regions = [
    '서울시', '부산시', '대구시', '인천시', '광주시', '대전시', '울산시', '세종시',
    '경기도', '강원도', '충청북도', '충청남도', '전라북도', '전라남도', '경상북도', '경상남도', '제주도'
  ];
  
  @override
  void initState() {
    super.initState();
    // ✅ initState에서 전달받은 region으로 초기화
    selectedRegion = widget.region;
  }

  // ✅ 부모 위젯의 region 값이 변경되면 이 메서드가 호출됩니다.
  @override
  void didUpdateWidget(covariant LocationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ 현재 위젯의 region과 이전 위젯의 region이 다를 때만 업데이트
    if (widget.region != oldWidget.region) {
      if (mounted) {
        setState(() {
          selectedRegion = widget.region;
        });
      }
    }
  }

  void _selectRegion(String region) {
    if (mounted) {
      setState(() {
        selectedRegion = region; // ✅ 전달받은 지역 이름만 사용
      });
    }
    Navigator.pop(context); // 모달 닫기
  }

  void _showRegionSelector() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('지역을 선택하세요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: regions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(regions[index]),
                      onTap: () => _selectRegion(regions[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return  Row(
          children: [
            Text(
              // ✅ selectedRegion 변수 사용
              '대한민국, $selectedRegion',
              style: TextStyle(
                fontSize: 14,
                color: Color.fromRGBO(124, 124, 124, 1),
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: _showRegionSelector,
              child: SizedBox(
                width: 20,
                height: 20,
                child: Image.asset(
                  'assets/navi.png',
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.location_on, size: 20, color: Colors.grey),
                ),
              ),
            ),
          ],
        );
  }
}