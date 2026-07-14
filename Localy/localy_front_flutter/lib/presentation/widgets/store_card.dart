// 파일 위치: lib/presentation/widgets/store_card.dart
import 'package:flutter/material.dart';
import 'package:localy_front_flutter/core/config/app_config.dart'; // AppConfig 임포트
import 'package:localy_front_flutter/data/models/store_models.dart';
// import 'package:cached_network_image/cached_network_image.dart';

class StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const StoreCard({
    super.key,
    required this.store,
    required this.onTap,
  });

  String _buildFullImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      return ''; // 빈 문자열 반환 또는 기본 이미지 URL
    }
    // AppConfig.baseUrl에서 scheme, host, port만 추출
    final uri = Uri.parse(AppConfig.baseUrl);
    // Edge Service는 /api 경로 없이 바로 /images, /store-images 등으로 접근 가능해야 함
    // 백엔드 store-service의 app.image.url-path가 /images/ 또는 /store-images/ 등으로 설정되어 있고,
    // Edge Service에서 해당 경로를 store-service로 라우팅한다고 가정합니다.
    // 따라서 AppConfig.baseUrl의 path 부분(/api)은 이미지 URL에 포함하지 않습니다.
    return '${uri.scheme}://${uri.host}:${uri.port}$relativeUrl';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final Color primaryColor = theme.primaryColor;

    final String fullMainImageUrl = _buildFullImageUrl(store.mainImageUrl);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: (fullMainImageUrl.isNotEmpty)
                  ? Image.network(
                fullMainImageUrl, // 전체 URL 사용
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2.0,
                      color: primaryColor,
                    ),
                  );
                },
                errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.storefront_outlined, size: 60, color: Colors.grey[400]),
                  );
                },
              )
                  : Container(
                color: Colors.grey[200],
                child: Icon(Icons.storefront_outlined, size: 60, color: Colors.grey[400]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Icon(Icons.sell_outlined, size: 14, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        storeCategoryToString(store.category),
                        style: textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 8),
                      if (store.status == StoreStatus.OPEN)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '영업중',
                            style: TextStyle(fontSize: 10, color: Colors.green[800], fontWeight: FontWeight.w500),
                          ),
                        )
                      else if (store.status == StoreStatus.PREPARING)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '준비중',
                            style: TextStyle(fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.w500),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            storeStatusToString(store.status),
                            style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w500),
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
                      const SizedBox(width: 4.0),
                      Text(
                        store.averageRating?.toStringAsFixed(1) ?? ' - ',
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        '(${store.reviewCount ?? 0} 리뷰)',
                        style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  if (store.address != null && store.address!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            store.address!,
                            style: textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
