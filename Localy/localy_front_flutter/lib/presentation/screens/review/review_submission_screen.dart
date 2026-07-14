// 파일 위치: lib/presentation/screens/review/review_submission_screen.dart
import 'dart:io'; // File 클래스 사용을 위해
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // image_picker 패키지
import 'package:localy_front_flutter/data/models/review_models.dart'; // ReviewRequest DTO
import 'package:localy_front_flutter/presentation/providers/review_provider.dart'; // ReviewProvider
import 'package:provider/provider.dart';

class ReviewSubmissionScreen extends StatefulWidget {
  static const String routeName = '/submit-review';
  final int storeId;
  final String storeName; // 가게 이름을 받아와서 화면 상단에 표시

  const ReviewSubmissionScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<ReviewSubmissionScreen> createState() => _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState extends State<ReviewSubmissionScreen> {
  final _formKey = GlobalKey<FormState>(); // 폼 상태 관리를 위한 글로벌 키
  final _commentController = TextEditingController(); // 리뷰 내용 입력 컨트롤러
  int _rating = 0; // 사용자가 선택한 별점 (0: 선택 안 함, 1~5점)
  File? _imageFile; // 사용자가 선택한 이미지 파일
  final ImagePicker _picker = ImagePicker(); // 이미지 선택을 위한 ImagePicker 인스턴스

  // 이미지 선택 (갤러리 또는 카메라)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // 이미지 품질 (0~100)
        maxWidth: 1000,   // 이미지 최대 너비 (픽셀)
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path); // 선택된 이미지를 File 객체로 변환하여 상태 업데이트
        });
      }
    } catch (e) {
      debugPrint("이미지 선택 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지를 가져오는 중 오류가 발생했습니다: ${e.toString()}')),
        );
      }
    }
  }

  // 이미지 선택 옵션(갤러리/카메라)을 보여주는 BottomSheet
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop(); // BottomSheet 닫기
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop(); // BottomSheet 닫기
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 리뷰 제출 로직
  Future<void> _submitReview() async {
    // 폼 유효성 검사 (현재는 리뷰 내용이 선택 사항이므로, 별점만 확인)
    // if (!_formKey.currentState!.validate()) {
    //   return;
    // }
    if (_rating == 0) { // 별점이 선택되지 않았으면 알림 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점을 선택해주세요.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    // ReviewRequest DTO 생성
    final reviewData = ReviewRequest(
      storeId: widget.storeId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );

    // ReviewProvider를 통해 리뷰 제출
    final success = await reviewProvider.submitReview(
      reviewData: reviewData,
      imageFile: _imageFile,
    );

    if (mounted) { // 위젯이 여전히 화면에 있는지 확인
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰가 성공적으로 등록되었습니다!'), backgroundColor: Colors.green),
        );
        // 리뷰 등록 성공 시, 이전 화면(StoreDetailScreen)으로 돌아가면서 true를 전달하여
        // 이전 화면에서 리뷰 목록 새로고침 등의 후속 작업을 할 수 있도록 함
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리뷰 등록 실패: ${reviewProvider.submissionErrorMessage ?? '알 수 없는 오류'}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose(); // 컨트롤러 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ReviewProvider의 isSubmittingReview 상태를 감지하여 로딩 인디케이터 표시
    final reviewProvider = Provider.of<ReviewProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.storeName} 리뷰 작성'), // AppBar에 가게 이름 표시
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 별점 선택 UI
              const Text('별점을 선택해주세요:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 38, // 별 아이콘 크기
                    ),
                    color: Colors.amber[600],
                    onPressed: () {
                      setState(() {
                        _rating = index + 1; // 선택된 별점으로 _rating 업데이트
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),

              // 리뷰 내용 입력 UI
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: '리뷰 내용 (선택 사항)',
                  hintText: '솔직한 리뷰를 남겨주세요... (예: 어떤 점이 좋았나요?)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true, // 레이블과 힌트 텍스트 정렬
                ),
                maxLines: 5, // 여러 줄 입력 가능
                maxLength: 500, // 최대 글자 수 제한
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),

              // 이미지 첨부 UI
              const Text('사진 첨부 (선택 사항):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context), // 탭하면 이미지 선택 옵션 표시
                child: Container(
                  height: 180, // 이미지 첨부 영역 높이
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.grey[350]!, width: 1.5),
                  ),
                  child: _imageFile != null
                      ? ClipRRect( // 선택된 이미지가 있으면 미리보기
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : Column( // 이미지가 없으면 아이콘과 텍스트 표시
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 50, color: Colors.grey[600]),
                      const SizedBox(height: 10),
                      Text('탭하여 사진 추가하기', style: TextStyle(color: Colors.grey[700], fontSize: 15)),
                    ],
                  ),
                ),
              ),
              // 선택된 이미지 삭제 버튼
              if (_imageFile != null)
                Container(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    label: const Text('선택한 사진 삭제', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                    onPressed: () {
                      setState(() {
                        _imageFile = null; // 이미지 파일 상태를 null로 변경하여 미리보기 제거
                      });
                    },
                  ),
                ),
              const SizedBox(height: 32),

              // 리뷰 등록 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: reviewProvider.isSubmittingReview
                      ? Container( // 로딩 중일 때 작은 인디케이터 표시
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 8),
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                      : const Icon(Icons.send_rounded),
                  label: Text(reviewProvider.isSubmittingReview ? '등록 중...' : '리뷰 등록하기'),
                  onPressed: reviewProvider.isSubmittingReview ? null : _submitReview, // 로딩 중이면 버튼 비활성화
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
