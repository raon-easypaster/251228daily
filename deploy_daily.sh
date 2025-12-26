#!/bin/bash

# 1. 오늘 날짜 가져오기 (Format: YYMMDD, 예: 251215)
REPO_NAME=$(date +"%y%m%d")

echo "=========================================="
echo "   자동 배포 시작: $REPO_NAME"
echo "=========================================="

# 2. Git 초기화 및 커밋
if [ ! -d ".git" ]; then
    git init
    git branch -m main
fi

git add .
git commit -m "Auto-deploy: $REPO_NAME"

# 3. GitHub 저장소 생성 및 푸시
# gh repo create가 실패해도(이미 존재함 등) 넘어가도록 || true 사용 등을 고려하나,
# 여기서는 repo create 시도 후 실패 시 기존 리모트 연결을 시도하는 방식으로 처리

echo "GitHub 저장소 생성 시도 중..."
gh repo create "$REPO_NAME" --public --source=. --push

if [ $? -eq 0 ]; then
    echo "✅ 저장소 생성 및 배포 성공!"
else
    echo "⚠️ 저장소 생성 실패 (이미 존재하거나 권한 문제일 수 있음)."
    echo "기존 저장소에 연결하여 푸시를 시도합니다..."
    
    # 사용자 아이디 가져오기
    USER_ID=$(gh api user -q .login)
    REMOTE_URL="https://github.com/$USER_ID/$REPO_NAME.git"
    
    git remote remove origin 2>/dev/null
    git remote add origin "$REMOTE_URL"
    git push -u origin main
fi

# 4. GitHub Pages 설정 (GitHub Actions로 배포되도록 설정)
echo "GitHub Pages 설정 중..."
gh api -X POST "repos/$USER_ID/$REPO_NAME/pages" -f "build_type=workflow" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ GitHub Pages 설정 완료 (Source: GitHub Actions)"
else
    echo "⚠️ GitHub Pages 설정 실패 (이미 설정되어 있거나 권한 문제)"
fi

echo "=========================================="
echo "   배포 완료!"
echo "   주소: https://$USER_ID.github.io/$REPO_NAME/"
echo "=========================================="
