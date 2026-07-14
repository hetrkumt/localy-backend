$ErrorActionPreference = "Stop"

$REGION = "ap-northeast-2"
$SERVICES = @(
    "edge-service",
    "store-service",
    "cart-service",
    "order-service",
    "payment-service",
    "user-service"
)

Write-Host "=================================================="
Write-Host "🚀 Localy MSA - AWS ECR 이미지 빌드 및 푸시 스크립트"
Write-Host "=================================================="

# 1. AWS 계정 ID 가져오기
Write-Host "🔍 AWS 계정 정보를 확인하는 중..." -ForegroundColor Cyan
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

if ([string]::IsNullOrWhiteSpace($ACCOUNT_ID)) {
    Write-Host "❌ AWS 계정 ID를 가져오지 못했습니다. AWS CLI 로그인이 되어있는지 확인해주세요." -ForegroundColor Red
    exit 1
}

$ECR_REGISTRY = "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
Write-Host "✅ 대상 ECR 레지스트리: ${ECR_REGISTRY}" -ForegroundColor Green

# 2. Docker를 AWS ECR에 로그인
Write-Host "🔑 AWS ECR에 Docker 로그인 중..." -ForegroundColor Cyan
# PowerShell에서 파이프 처리를 위해 cmd /c 사용
cmd /c "aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ECR 로그인 실패! AWS 권한이나 Docker 실행 여부를 확인하세요." -ForegroundColor Red
    exit 1
}
Write-Host "✅ ECR 로그인 완료!" -ForegroundColor Green

$BASE_DIR = Get-Location

# 3. 각 서비스별 빌드 및 푸시 반복
foreach ($SERVICE in $SERVICES) {
    Write-Host "--------------------------------------------------"
    Write-Host "📦 서비스 처리 시작: ${SERVICE}" -ForegroundColor Yellow
    
    $SERVICE_DIR = Join-Path -Path $BASE_DIR -ChildPath $SERVICE
    
    if (-not (Test-Path -Path $SERVICE_DIR -PathType Container)) {
        Write-Host "⚠️ 경고: ${SERVICE} 디렉토리를 찾을 수 없어 건너뜁니다." -ForegroundColor Yellow
        continue
    }
    
    Set-Location -Path $SERVICE_DIR
    
    # ECR에 올라갈 최종 이미지 주소
    $IMAGE_URI = "${ECR_REGISTRY}/${SERVICE}:latest"
    
    # 이미지 빌드
    Write-Host "🔨 1/3 Docker 이미지 빌드 중..." -ForegroundColor Cyan
    docker build -t "${SERVICE}:latest" .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 빌드 실패! 다음 서비스로 넘어갑니다." -ForegroundColor Red
        Set-Location -Path $BASE_DIR
        continue
    }
    
    # 이미지 태그 달기
    Write-Host "🏷️ 2/3 이미지에 ECR 태그 다는 중..." -ForegroundColor Cyan
    docker tag "${SERVICE}:latest" $IMAGE_URI
    
    # 이미지 푸시
    Write-Host "☁️ 3/3 AWS ECR로 푸시 중..." -ForegroundColor Cyan
    docker push $IMAGE_URI
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 푸시 실패! 다음 서비스로 넘어갑니다." -ForegroundColor Red
    } else {
        Write-Host "✅ ${SERVICE} 푸시 성공!" -ForegroundColor Green
    }
    
    Set-Location -Path $BASE_DIR
}

Write-Host "=================================================="
Write-Host "🎉 모든 작업이 완료되었습니다!" -ForegroundColor Green
Write-Host "=================================================="
