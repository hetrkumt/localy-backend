#!/bin/bash

# 설정 (Configuration)
REGION="ap-northeast-2"
SERVICES=(
    "edge-service"
    "store-service"
    "cart-service"
    "order-service"
    "payment-service"
    "user-service"
)

echo "=================================================="
echo "🚀 Localy MSA - AWS ECR 이미지 빌드 및 푸시 스크립트"
echo "=================================================="

# 1. AWS 계정 ID 가져오기
echo "🔍 AWS 계정 정보를 확인하는 중..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$ACCOUNT_ID" ]; then
    echo "❌ AWS 계정 ID를 가져오지 못했습니다. AWS CLI 로그인이 되어있는지 확인해주세요."
    exit 1
fi

ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
echo "✅ 대상 ECR 레지스트리: ${ECR_REGISTRY}"

# 2. Docker를 AWS ECR에 로그인
echo "🔑 AWS ECR에 Docker 로그인 중..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

if [ $? -ne 0 ]; then
    echo "❌ ECR 로그인 실패! AWS 권한이나 Docker 실행 여부를 확인하세요."
    exit 1
fi
echo "✅ ECR 로그인 완료!"

BASE_DIR=$(pwd)

# 3. 각 서비스별 빌드 및 푸시 반복
for SERVICE in "${SERVICES[@]}"; do
    echo "--------------------------------------------------"
    echo "📦 서비스 처리 시작: ${SERVICE}"
    
    SERVICE_DIR="${BASE_DIR}/${SERVICE}"
    
    if [ ! -d "${SERVICE_DIR}" ]; then
        echo "⚠️ 경고: ${SERVICE} 디렉토리를 찾을 수 없어 건너뜁니다."
        continue
    fi
    
    cd "${SERVICE_DIR}"
    
    # ECR에 올라갈 최종 이미지 주소
    IMAGE_URI="${ECR_REGISTRY}/${SERVICE}:latest"
    
    # 이미지 빌드
    echo "🔨 1/3 Docker 이미지 빌드 중..."
    docker build -t ${SERVICE}:latest .
    if [ $? -ne 0 ]; then
        echo "❌ 빌드 실패! 다음 서비스로 넘어갑니다."
        cd "${BASE_DIR}"
        continue
    fi
    
    # 이미지 태그 달기
    echo "🏷️ 2/3 이미지에 ECR 태그 다는 중..."
    docker tag ${SERVICE}:latest ${IMAGE_URI}
    
    # 이미지 푸시
    echo "☁️ 3/3 AWS ECR로 푸시 중..."
    docker push ${IMAGE_URI}
    if [ $? -ne 0 ]; then
        echo "❌ 푸시 실패! 다음 서비스로 넘어갑니다."
    else
        echo "✅ ${SERVICE} 푸시 성공!"
    fi
    
    cd "${BASE_DIR}"
done

echo "=================================================="
echo "🎉 모든 작업이 완료되었습니다!"
echo "=================================================="
