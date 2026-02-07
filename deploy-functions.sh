#!/bin/bash

echo "🚀 Deploying Cloud Functions..."
echo ""

# Kiểm tra đăng nhập
echo "📋 Kiểm tra đăng nhập Firebase..."
firebase projects:list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Chưa đăng nhập Firebase. Vui lòng chạy: firebase login"
    exit 1
fi

echo "✅ Đã đăng nhập Firebase"

# Deploy functions
echo ""
echo "🔧 Deploying functions..."
firebase deploy --only functions

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Deploy thành công!"
    echo ""
    echo "📋 Kiểm tra functions đã deploy:"
    firebase functions:list
    echo ""
    echo "✅ Bây giờ khi xóa user, sẽ tự động xóa khỏi cả Firestore và Firebase Auth"
else
    echo ""
    echo "❌ Deploy thất bại. Vui lòng kiểm tra:"
    echo "   1. Đã đăng nhập Firebase: firebase login"
    echo "   2. Project có Blaze plan (billing enabled)"
    echo "   3. Quyền truy cập project"
fi