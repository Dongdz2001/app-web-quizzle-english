# Deploy lên GitHub Pages (GitHub Actions)

## Thiết lập 1 lần

1. **Bật GitHub Pages** trong repo:
   - Vào **Settings** → **Pages**
   - **Source**: chọn **GitHub Actions**

2. **Push code** lên branch `main`:
   - Mỗi khi push lên `main`, GitHub Action sẽ build Flutter web và deploy lên GitHub Pages

## URL sau khi deploy

```
https://<username>.github.io/<repo-name>/
```

Ví dụ: `https://Dongdz2001.github.io/vocab_app/` nếu repo là `Dongdz2001/vocab_app`

## Chạy deploy thủ công

Vào **Actions** → **Deploy to GitHub Pages** → **Run workflow**
