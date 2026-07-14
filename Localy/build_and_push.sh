#!/bin/bash

# 스크립트 설명:
# 이 스크립트는 Localy 프로젝트의 각 마이크로서비스 Docker 이미지를 빌드하고
# Docker Hub (asfas244 사용자)에 푸시하는 과정을 자동화합니다.
# 이 스크립트는 Localy 프로젝트의 루트 디렉토리에서 실행되어야 합니다.
# 예: /path/to/your/Localy/build_and_push.sh

# --- 설정 ---
# Docker Hub 사용자 이름 (asfas244로 고정)
DOCKER_HUB_USER="asfas244"

# Localy 프로젝트 루트 디렉토리 (스크립트가 실행되는 현재 디렉토리로 자동 설정)
# BASE_DIR="/path/to/your/Localy" # 만약 스크립트를 다른 곳에서 실행한다면 이 줄의 주석을 해제하고 실제 경로로 수정하세요.
BASE_DIR="$(pwd)" # 스크립트가 실행되는 현재 디렉토리를 BASE_DIR로 설정

# 빌드 및 푸시할 서비스 목록 (서비스 디렉토리 이름)
SERVICES=(
    "edge-service"
    "store-service"
    "cart-service"
    "order-service"
    "payment-service"
    "user-service"
)
# --- 설정 끝 ---

echo "--- Docker 이미지 빌드 및 푸시 시작 ---"
echo "Docker Hub 사용자: ${DOCKER_HUB_USER}"
echo "기반 디렉토리: ${BASE_DIR}"
echo "------------------------------------"

# Docker 데몬 실행 및 Docker Hub 로그인 상태 확인 (선택 사항이지만 권장)
# docker info > /dev/null || { echo "오류: Docker 데몬이 실행 중이 아닙니다. Docker를 시작해주세요."; exit 1; }
# docker login > /dev/null 2>&1 || { echo "경고: Docker Hub에 로그인되어 있지 않습니다. 푸시가 실패할 수 있습니다."; }


# 각 서비스에 대해 반복 실행
for SERVICE in "${SERVICES[@]}"; do
    SERVICE_DIR="${BASE_DIR}/${SERVICE}"
    IMAGE_NAME="${SERVICE}"
    LOCAL_IMAGE_TAG="${IMAGE_NAME}:latest"
    DOCKER_HUB_IMAGE_TAG="${DOCKER_HUB_USER}/${IMAGE_NAME}:latest"

    echo ""
    echo ">>> 서비스: ${SERVICE} 처리 중 <<<"
    echo ">>> 디렉토리: ${SERVICE_DIR}"

    # 서비스 디렉토리로 이동
    if [ -d "${SERVICE_DIR}" ]; then
        cd "${SERVICE_DIR}" || { echo "오류: ${SERVICE_DIR} 디렉토리로 이동할 수 없습니다."; continue; }
        echo ">>> ${SERVICE_DIR} 로 이동 완료"

        # Dockerfile 존재 확인 (선택 사항)
        if [ ! -f "Dockerfile" ]; then
            echo "경고: ${SERVICE_DIR} 에 Dockerfile이 존재하지 않습니다. 이 서비스를 건너뜁니다."
            cd "${BASE_DIR}" # 원래 디렉토리로 돌아가기
            continue
        fi

        # 1. Docker 이미지 빌드
        echo ">>> Docker 이미지 빌드: ${LOCAL_IMAGE_TAG}"
        # 빌드 컨텍스트는 현재 디렉토리(서비스 디렉토리)로 설정
        docker build -t "${LOCAL_IMAGE_TAG}" .
        BUILD_EXIT_CODE=$? # 빌드 결과 코드 저장

        if [ $BUILD_EXIT_CODE -ne 0 ]; then
            echo "오류: ${SERVICE} 이미지 빌드 실패 (종료 코드: ${BUILD_EXIT_CODE}). 다음 서비스로 넘어갑니다."
            cd "${BASE_DIR}" # 원래 디렉토리로 돌아가기
            continue # 다음 서비스로 이동
        fi
        echo ">>> ${SERVICE} 이미지 빌드 성공"

        # 2. Docker 이미지 태그 지정
        echo ">>> Docker 이미지 태그 지정: ${LOCAL_IMAGE_TAG} -> ${DOCKER_HUB_IMAGE_TAG}"
        docker tag "${LOCAL_IMAGE_TAG}" "${DOCKER_HUB_IMAGE_TAG}"
        TAG_EXIT_CODE=$? # 태그 결과 코드 저장

        if [ $TAG_EXIT_CODE -ne 0 ]; then
            echo "오류: ${SERVICE} 이미지 태그 지정 실패 (종료 코드: ${TAG_EXIT_CODE}). 다음 서비스로 넘어갑니다."
            cd "${BASE_DIR}" # 원래 디렉토리로 돌아가기
            continue # 다음 서비스로 이동
        fi
        echo ">>> ${SERVICE} 이미지 태그 지정 성공"


        # 3. Docker 이미지 푸시
        echo ">>> Docker 이미지 푸시: ${DOCKER_HUB_IMAGE_TAG}"
        docker push "${DOCKER_HUB_IMAGE_TAG}"
        PUSH_EXIT_CODE=$? # 푸시 결과 코드 저장

        if [ $PUSH_EXIT_CODE -ne 0 ]; then
            echo "오류: ${SERVICE} 이미지 푸시 실패 (종료 코드: ${PUSH_EXIT_CODE}). Docker Hub 로그인 상태를 확인하세요."
            # 푸시 실패 시 스크립트를 중단하거나 계속 진행하도록 선택할 수 있습니다.
            # 여기서는 오류 메시지를 출력하고 다음 서비스로 넘어갑니다.
        else
            echo ">>> ${SERVICE} 이미지 푸시 성공"
        fi

        # 원래 디렉토리로 돌아가기
        cd "${BASE_DIR}" || { echo "오류: 원래 디렉토리 ${BASE_DIR} 로 돌아갈 수 없습니다. 스크립트를 종료합니다."; exit 1; }
        echo ">>> ${BASE_DIR} 로 돌아옴"

    else
        echo "오류: 서비스 디렉토리 ${SERVICE_DIR} 가 존재하지 않습니다. 이 서비스를 건너뜁니다."
    fi

    echo "------------------------------------"

done

echo ""
echo "--- Docker 이미지 빌드 및 푸시 프로세스 완료 ---"
echo "각 서비스의 빌드 및 푸시 결과를 확인하세요."
