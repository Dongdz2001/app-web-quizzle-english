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

```bash
# Cài Vercel CLI (nếu chưa có)
npm i -g vercel

# Build Flutter web
flutter build web --release

# Tạo prebuilt output (Vercel Build Output API)
mkdir -p .vercel/output/static
cp -r build/web/* .vercel/output/static/
cp vercel.output.config.json .vercel/output/config.json

# Deploy
vercel deploy --prebuilt --prod --yes
```

**Lưu ý:** Phải dùng `vercel.output.config.json` (có `"handle":"filesystem"`) để Vercel phục vụ file JS/assets trước, chỉ fallback về `index.html` khi không có file. Thiếu bước này sẽ bị màn hình trắng.

Lần đầu chạy sẽ yêu cầu đăng nhập và cấu hình project.
