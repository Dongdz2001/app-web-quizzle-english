# Deploy lên Vercel

## Cách 1: GitHub Actions (tự động)

1. **Tạo project trên Vercel**
   - Vào [vercel.com](https://vercel.com) → New Project
   - Import repo GitHub (chưa cần deploy)
   - Lấy **Project ID** và **Org ID** từ Settings của project

2. **Tạo token Vercel**
   - Vercel → Settings → Tokens → Create Token

3. **Thêm Secrets vào GitHub**
   - Repo → Settings → Secrets and variables → Actions
   - Thêm 3 secrets:
     - `VERCEL_TOKEN`: token vừa tạo
     - `VERCEL_ORG_ID`: Org ID
     - `VERCEL_PROJECT_ID`: Project ID

4. **Push lên main**
   - Mỗi lần push lên branch `main`, GitHub Action sẽ build Flutter web và deploy lên Vercel.

## Cách 2: Deploy thủ công (CLI)

TTS trên web dùng **Web Speech API** (trình duyệt), không cần API server — deploy chỉ cần static:

```bash
# Cài Vercel CLI (nếu chưa có)
npm i -g vercel

# Build Flutter web
flutter build web --release

# Deploy
vercel deploy --prod --yes
```

`vercel.json` đã cấu hình `outputDirectory: "build/web"`. Đọc từ (TTS) hoạt động ngay sau khi deploy nhờ Web Speech API trong trình duyệt.

**Nếu dùng prebuilt (tùy chọn):**

```bash
flutter build web --release
mkdir -p .vercel/output/static
cp -r build/web/* .vercel/output/static/
cp vercel.output.config.json .vercel/output/config.json
vercel deploy --prebuilt --prod --yes
```

Prebuilt cần `vercel.output.config.json` (có `"handle":"filesystem"`) để tránh màn hình trắng.

Lần đầu chạy sẽ yêu cầu đăng nhập và cấu hình project.
