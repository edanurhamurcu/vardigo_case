# VardiGO — Case Study (2 ekran + API)

Flutter (Android / iOS) mobil uygulama + Node.js / Express REST API.

| Klasör | İçerik |
|---|---|
| `backend/` | Express 5 API, JSON file store, seed data, testler, OpenAPI spec |
| `mobile/` | Flutter uygulaması (Riverpod, Dio, flutter_svg) |
| `docker-compose.yml` | Backend'i tek komutla ayağa kaldırır |
| `SUREC.txt` | Geliştirme süreci notu |

---

## Kurulum (~5 dk)

### 1) Backend

**Docker ile (tek komut):**
```bash
docker compose up --build
```

**veya Node ile (Node 18+):**
```bash
cd backend
npm install
npm start          # http://localhost:3000/api
```

Health check: `curl http://localhost:3000/api/health` → `{"ok":true,"data":{"status":"up"}}`

**Swagger UI:** http://localhost:3000/api/docs — `POST /auth/login` ile token al, **Authorize**'a yapıştır, endpoint'leri dene.

| Komut | Açıklama |
|---|---|
| `npm start` | API'yi başlatır (port 3000) |
| `npm run dev` | Watch mode — dosya değişince yeniden başlatır |
| `npm test` | Integration + unit testler (spec'teki "minimum test" senaryosu dahil) |
| `npm run reset` | Veritabanını seed data ile sıfırlar |

### 2) Mobil uygulama (Flutter 3.47+)

```bash
cd mobile
flutter pub get
flutter run                          # Android emulator → otomatik 10.0.2.2:3000
```

- **Telefon frame modu** (referanstaki bezel + Dynamic Island): `flutter run --dart-define=FRAME=true`
- **Gerçek cihaz / farklı host:** `flutter run --dart-define=API_BASE_URL=http://<bilgisayar-ip>:3000/api`
- **390×844 viewport:** Android Studio → Device Manager → New Hardware Profile → 1170×2532 px, **5.8"** (≈480 dpi, xxhdpi) → 390×844 dp. iOS'ta iPhone 15 / 16 simulator birebir 390×844.

Test: `flutter test` · Static analysis: `flutter analyze`

> **Test edilen platform:** Android emulator (Windows üzerinde geliştirildi). iOS için gerekli ayarlar yapıldı (`Info.plist` → local network ATS izni) ancak Mac/Xcode olmadığı için iOS'ta çalıştırılıp doğrulanmadı.

---

## Demo akışı

1. Uygulama açılınca **İşveren olarak devam et** → Eşleşen Personeller.
2. Merve Y. default seçili; kartlara dokunarak multi-select yap → **Görüşme Talebi Gönder (N)**.
3. Geri dön → **İş arayan olarak devam et** → Görüşme Talepleri. Gönderilen talepler **Bekleyen** tab'ında.
4. **İlgileniyorum / İlgilenmiyorum** → kart **Cevaplanan** tab'ına geçer (persistent; uygulama veya server restart sonrası da korunur).
5. **Süresi Dolan** tab'ında seed'deki expired örnek talep görünür.

---

## API

Base URL: `http://localhost:3000/api`

Tüm endpoint'ler ortak bir response formatı kullanır; client her cevabı `ok` alanına bakarak tek bir yerden işler:
`{ "ok": true, "data": ... }` / `{ "ok": false, "error": { "code", "message" } }`

| Method | Path | Rol | Not |
|---|---|---|---|
| POST | `/auth/login` | — | `{ "role": "employer" \| "worker" }` → `dev-employer` / `dev-worker` |
| GET | `/candidates?tab=perfect\|similar&sort=recommended\|near\|rating` | employer | perfect = score ≥ 80 |
| POST | `/offers` | employer | `{ "workerIds": [...] }` — boş → 400, bilinmeyen id → 404, açık pending offer → 409 |
| GET | `/offers?status=pending\|answered\|expired` | worker | `remain` server-side hesaplanır |
| GET | `/offers/:id` | worker | detail + city + note |
| POST | `/offers/:id/accept` | worker | pending değil → 409, expired → 409 "Teklifin süresi doldu" |
| POST | `/offers/:id/reject` | worker | aynı kurallar |

Örnek request'ler: [`backend/requests.http`](backend/requests.http) (VS Code REST Client / IntelliJ HTTP Client) ve Swagger UI.

```bash
# Employer: 2 kişiye offer gönder
curl -X POST http://localhost:3000/api/offers \
  -H "Authorization: Bearer dev-employer" -H "Content-Type: application/json" \
  -d '{"workerIds":["w_merve","w_derya"]}'

# Worker: pending offer'lar
curl "http://localhost:3000/api/offers?status=pending" -H "Authorization: Bearer dev-worker"

# Accept
curl -X POST http://localhost:3000/api/offers/o_garson/accept -H "Authorization: Bearer dev-worker"
```

---

## Mimari

**Backend** — `routes/` (HTTP layer) → `services/` (business logic) → `db.js` (JSON file store).
- Merkezi error handler; tüm hatalar `AppError` üzerinden spec'teki standart error formatına (`code` + `message`) dönüştürülür.
- Yazma işlemleri `db.transaction()` ile yapılır: atomic write (tmp file + rename), yazma hatasında in-memory state rollback edilir.
- Expired kontrolü her read/write'ta yapılır; `expiresAt` geçmiş pending offer'lar `expired` olarak persist edilir.
- Worker yalnızca kendi offer'larını görür ve yanıtlayabilir (başkasının offer'ı → 404).

**Mobil** — feature-first + layered architecture:

```
lib/
  core/        config, theme (design tokens), network (Dio + ortak response formatının parse edilmesi), auth, shared widgets
  features/
    candidates/  domain → data (repository) → presentation (Riverpod Notifier + UI)
    offers/      domain → data (repository) → presentation (Riverpod Notifier + UI)
    home/        demo role selection
```

- **State management: Riverpod** (`Notifier` + immutable state). Selection state client'ta tutulur, gönderilince API'ye yazılır.
- Repository'ler `abstract interface class` → testlerde fake ile override edilebilir.
- Design token'lar (`AppColors`, `AppTextStyles`, `AppShadows`) spec dosyasıyla birebir aynı isimlerde.
- Urbanist font, `liga` ve `calt` kapalı; icon / logo / fotoğraflar case paketinden, yeniden çizilmedi.
- Her ekran loading / error (retry) / empty / data state'lerini handle eder.

## Varsayımlar

Ayrıntılar `SUREC.txt` içinde. Kısaca:
- Referans PNG ile text spec çeliştiğinde brief'teki kaynak sırasına göre **PNG esas alındı**, data seed'den geldi.
- Tab sayıları spec'teki sabit 26 / 16 label'ı yerine veriden hesaplanır (score ≥ 80 kuralı), böylece header ile liste tutarlı kalır. Gerçek sistemde bu sayılar job'a ait tüm eşleşmelerden `COUNT` ile gelir ve liste paginated döner.
- Tek demo worker hesabı var; employer'ın gönderdiği tüm offer'lar bu hesaba düşer.
- Uygulama açılışındaki rol seçim ekranı case'teki iki sayfaya dahil değildir; iki sayfaya tek uygulamadan ulaşmak ve doğru demo token'ı almak için eklenmiş minimal bir giriş noktasıdır (referans tasarımı yoktur).
- Sayfa 1'deki "Ücret beklentisi" satırı PNG'de olduğu için eklendi; değerler seed'e field olarak eklendi.
