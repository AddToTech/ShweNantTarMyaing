# 🌿 SitePyoe Nursery POS — Cloud Deployment & Server Integration Guide

This guide provides end-to-end instructions for deploying the **SitePyoe Backend API & PostgreSQL Database** to a cloud server and connecting the **Flutter Android Tablet POS App**.

---

## 1. 100% Backend Integration Verification

All features and screens in SitePyoe POS are dynamically connected to the backend PostgreSQL REST API:

| Feature / Screen | Backend Endpoint | Offline Cache / Sync | Dynamic Status |
| :--- | :--- | :--- | :--- |
| **Authentication & RBAC** | `POST /api/v1/auth/login`, `GET /users` | SharedPreferences + JWT cache | ✅ 100% Dynamic |
| **Shop Branches** | `GET /api/v1/branches`, `POST`, `PATCH`, `DELETE` | `branches_cache` (Drift SQLite) | ✅ 100% Dynamic |
| **Categories & Subcategories** | `GET /api/v1/categories`, `POST`, `PATCH`, `DELETE` | `categories_cache` (Drift SQLite) | ✅ 100% Dynamic |
| **Products & Inventory** | `GET /api/v1/products`, `PATCH`, `DELETE`, `/image` | `products_cache` & `inventories_cache` | ✅ 100% Dynamic |
| **POS Checkout & Orders** | `POST /api/v1/sales`, `GET /api/v1/sales`, `DELETE` | `pending_sales` queue + auto sync | ✅ 100% Dynamic |
| **Purchases & Stock-In** | `GET /api/v1/purchases`, `POST /api/v1/purchases` | Local persistence fallback | ✅ 100% Dynamic |
| **Vendors & Suppliers** | `GET /api/v1/vendors`, `POST`, `PATCH` | Local persistence fallback | ✅ 100% Dynamic |
| **Wastage (အလေအလွင့်)** | `GET /api/v1/wastage`, `POST /api/v1/wastage` | `pending_wastage_logs` auto sync | ✅ 100% Dynamic |
| **Inter-Branch Transfers** | `GET /api/v1/transfers`, `POST`, `receive` | Local persistence fallback | ✅ 100% Dynamic |
| **HR & Employees** | `GET /api/v1/employees`, `POST`, `PATCH`, `toggle` | Local persistence fallback | ✅ 100% Dynamic |
| **Payroll (လစာပေးချေမှု)** | `GET /api/v1/payrolls`, `POST /api/v1/payrolls` | Local persistence fallback | ✅ 100% Dynamic |
| **Reports & BI Dashboard** | `GET /api/v1/reports/*` (Sales, Purchases, OPEX) | Dynamic Aggregations | ✅ 100% Dynamic |

> **Note on Mock Data:** All baseline mock datasets (`kMockProducts`, `kBaselinePurchases`, `kBaselineTransactions`, `kDefaultCategories`, `kDemoVendors`) are empty `[]`. All screens populate exclusively from backend database records.

---

## 2. Cloud Server Deployment Options

### Option A: 1-Click Docker Compose (Recommended for VPS / Ubuntu / DigitalOcean / Linode)

On your remote Ubuntu/Debian server:
```bash
# 1. Clone repository
git clone <your-repo-url>
cd SitePyoe/backend

# 2. Copy production environment file
cp .env.production.example .env
nano .env   # Update JWT_SECRET and database passwords

# 3. Start PostgreSQL and Backend API with Docker Compose
docker compose up -d --build

# 4. Run database migrations & catalog seed
docker compose exec backend npm run db:migrate
docker compose exec backend npm run db:seed
```

---

### Option B: Cloud App Platforms (Railway / Render / Fly.io)

1. **Database:** Create a managed PostgreSQL database (e.g., Neon, Supabase, Railway Postgres, or Render PostgreSQL).
2. **Web Service:** Connect your Git repository, set root directory to `backend/`.
3. **Environment Variables:**
   - `DATABASE_URL`: `postgresql://<user>:<pass>@<host>:<port>/<dbname>?sslmode=require`
   - `NODE_ENV`: `production`
   - `JWT_SECRET`: `<your-random-64-char-string>`
   - `JWT_REFRESH_SECRET`: `<your-random-64-char-string>`
4. **Deploy Command:** `npm ci --omit=dev`
5. **Start Command:** `npm start`
6. **Migrations:** Once deployed, run `npm run db:migrate` (and `npm run db:seed` if seeding initial catalog).

---

## 3. Connecting the Android Tablet POS App to the Cloud Server

You can connect the app to your cloud server using either of the following two methods:

### Method 1: In-App UI Configuration (No Recompilation Required)
1. **On Login Screen:**
   - Tap the **`Server API`** button at the top-right corner.
   - Enter your Cloud URL (e.g. `https://api.sitepyoe.yourdomain.com/api/v1` or `http://192.168.1.100:5001/api/v1`).
   - Tap **"စမ်းသပ်ချိတ်ဆက်မည် (Ping)"** to verify PostgreSQL connectivity and latency.
   - Tap **"သိမ်းဆည်းမည်"** (saved into SharedPreferences).

2. **In Settings Menu:**
   - Go to **Settings** > **Cloud Server & Database** card.
   - Edit, test, or reset the API Base URL at any time.

### Method 2: Build APK with Pre-Configured Cloud URL
When generating your release APK for Android tablets:
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.sitepyoe.yourdomain.com/api/v1
```
The APK will use your remote cloud server as the default endpoint.

---

## 4. Cloud Server Health Check
Verify your cloud server anytime via:
```bash
curl https://<your-server-domain>/health
```
Response:
```json
{
  "status": "ok",
  "service": "sitepyoe-backend",
  "database": "connected",
  "timestamp": "2026-11-03T07:10:00.000Z"
}
```

