# Proje "SPLATLINE" — İş ve Geliştirme Planı

> Çalışma adı: **Splatline** (değişebilir)
> Tür: Takım tabanlı, taktiksel paintball nişancı oyunu (FPS)
> Platform: PC (Steam), sonrasında web demo (itch.io)
> Motor ve araçlar: Godot 4 · Meshy AI · Blender
> Hazırlayan: Geliştirme stüdyosu (Claude) · Sunulan: Yatırımcı

---

## 1. Yönetici Özeti

Splatline, oyuncuların boya tabancalarıyla 5v5 takım maçları yaptığı, haritanın vurulan her yerinde boya lekesi kaldığı, **botlarla tek başına** ya da **çevrimiçi arkadaşlarla** oynanabilen bir paintball oyunudur.

**Neden şimdi, neden bu oyun?**
- Splatoon türün popüler olduğunu kanıtladı, ancak yalnızca Nintendo konsollarında var. PC'de bunun karşılığı yok.
- PC'deki paintball oyunları ya çok eski ya da düşük kaliteli mobil uyarlamalar.
- Oyuncu tabanı küçükken bile oyunun "boş sunucu" sorununa düşmemesini **botlar** sağlıyor. Küçük çok oyunculu indie oyunları en çok bu sorun bitiriyor.
- Godot ve Meshy AI ile küçük bir ekip, eskiden 10 kişilik bir stüdyonun ürettiği içeriği üretebiliyor. Bu da maliyeti düşük tutuyor.

**Hedef:** 9 ayda Steam'de Erken Erişim (Early Access) ile satışa çıkmak.

---

## 2. Ürün Tanımı

### Oyunun özü (30 saniyelik döngü)
Siperden sipere koş → rakibi gör → yay çizen boya topunu at → vur veya vurul → takım arkadaşını kurtar veya bayrağı kap.

### Temel mekanikler
| Mekanik | Açıklama |
|---|---|
| Boya mermisi | Hitscan değil, fiziksel mermi. Yavaş gider, yay çizer, rüzgârdan etkilenmez. Paintball hissini bu verir. |
| Boya lekeleri | Vurulan her yüzeyde takım renginde kalıcı leke (Godot `Decal`). Oyunun görsel imzası. |
| Eleme | Gövdeye 1 isabet oyuncuyu eler; kol veya bacağa isabet oyuncuyu yavaşlatır. |
| Siper | Şişme bariyerler, variller ve kasalar. Çömelme ve siperden eğilip bakma. |
| Silahlar | 3 sınıf: Standart (dengeli), Pompalı (yakın mesafe, saçma), Keskin (uzak mesafe, yavaş). |

### Oyun modları (öncelik sırasıyla)
1. **Takım Eleme (5v5):** Ana mod, raund tabanlı.
2. **Bayrak Kap:** Klasik paintball "speedball" modu.
3. **Boya Hâkimiyeti:** Haritada en çok alanı boyayan takım kazanır (Splatoon'a selam).

### Bot sistemi
- Boş kalan her slotu bot doldurur. Oyuncu tek başına 4 bot takım arkadaşıyla 5 bota karşı oynayabilir.
- 3 zorluk seviyesi: Çaylak, Oyuncu, Profesyonel.
- Davranışlar: devriye, siper arama, yan çizme (flank), geri çekilme, takım arkadaşına destek.
- Teknik altyapı: `NavigationAgent3D`, durum makinesi ve görüş kontrolü (`RayCast3D`).

### Görsel stil
Parlak renkli ve stilize (Fortnite ile Splatoon arası). Bu seçimin iki faydası var:
- Meshy AI'nın ürettiği modellerdeki kusurlar gerçekçi stile göre çok daha az göze batar.
- Düşük donanımlı bilgisayarlarda da akıcı çalışır, bu da oyuncu kitlesini genişletir.

---

## 3. Pazar ve Rakipler

| Oyun | Güçlü yanı | Eksiği / Bizim fırsatımız |
|---|---|---|
| Splatoon 3 | Boya mekaniği, marka gücü | PC'de yok |
| Roblox "Paintball!" | Çok oyuncusu var | Basit, çocuk kitlesine yönelik, Roblox'a bağımlı |
| Eski PC paintball oyunları | Nostalji | Terk edilmiş, güncel değil |
| Krunker / Splitgate | Hızlı arena FPS'i | Paintball kimliği yok |

**Hedef kitle:** 13–30 yaş arası, arkadaşlarıyla oynayacak ucuz ve eğlenceli bir çok oyunculu oyun arayan PC oyuncuları.

**Fiyatlandırma önerisi:** Erken Erişim'de **$9.99** (Türkiye bölgesel fiyatı ayrıca belirlenecek). Kozmetik DLC'ler sonraki aşamada düşünülecek. Oyunu kazanmaya etki eden ücretli içerik (pay-to-win) olmayacak.

---

## 4. Teknik Mimari

```
┌─────────────┐   .glb    ┌──────────────┐   sahneler   ┌──────────────────┐
│  Meshy AI   │ ────────▶ │   Blender    │ ───────────▶ │     Godot 4      │
│ (ham model) │           │ düzenleme,   │              │ oyun mantığı,    │
└─────────────┘           │ rig, UV      │              │ bot AI, ağ kodu  │
                          └──────────────┘              └──────────────────┘
```

- **Dil:** GDScript (hızlı geliştirme). Yalnızca performans gerektiren yerlerde C#.
- **Ağ modeli:**
  - **Aşama 1:** Bir oyuncunun oyunu host ettiği model (listen server, Godot High-Level Multiplayer + ENet).
  - **Aşama 2:** Steam lobileri ve NAT geçişi (GodotSteam). Oyuncuların port açmasına gerek kalmaz.
  - **Aşama 3 (başarı hâlinde):** Özel sunucular ve eşleştirme sistemi.
- **Sunucu otoritesi:** İsabetleri sunucu hesaplar, böylece hile yapmak zorlaşır.
- **Sürüm kontrolü:** Git + GitHub (bu repo). Büyük model dosyaları için Git LFS.
- **Otomatik test:** GitHub Actions ile Godot'un ekransız (headless) modunda derleme ve temel testler.

---

## 5. Yol Haritası

| Aşama | Süre | Çıktı | Başarı kriteri (geçemezsek durup değerlendiririz) |
|---|---|---|---|
| **0. Hazırlık** | 1. hafta | Repo, Godot proje iskeleti, klasör yapısı, CI | Proje açılıyor ve CI yeşil |
| **1. Prototip** | 2.–5. hafta | Gri kutulardan bir harita; hareket, ateş, boya lekesi, eleme | Oyunu 10 dakika oynayınca "bir tur daha" deniyor |
| **2. Bot AI** | 6.–9. hafta | 5v5 bot maçı, 3 zorluk seviyesi | Botlara karşı maç tek başına eğlenceli |
| **3. Çok oyunculu** | 10.–15. hafta | Listen server, lobi, 4 kişilik gerçek test | 100 ms pinge kadar oyun akıcı |
| **4. Görsel içerik** | 12.–22. hafta (3. aşamayla paralel) | Meshy + Blender ile 2 harita, 6 karakter, 3 silah, ses ve efektler | Oyun ekran görüntülerinde "profesyonel" görünüyor |
| **5. Dikey dilim (vertical slice)** | 23.–26. hafta | Tamamen cilalanmış tek harita ve tek mod | Steam sayfası ve fragman çekilebilir kalitede |
| **6. Steam sayfası ve demo** | 27.–32. hafta | Steam sayfası, istek listesi (wishlist) toplama, itch.io demosu, Steam Next Fest | 5.000+ istek listesi |
| **7. Erken Erişim** | 33.–36. hafta | Steam'de satışa çıkış | İlk ayda 1.000+ satış |

---

## 6. Ekip ve Görev Dağılımı

Açık olmak gerekirse: stüdyo bir yapay zekâdır. Neleri yapabildiğini ve nerede insan desteği gerektiğini baştan yazıyoruz.

| Rol | Kim | Kapsam |
|---|---|---|
| Baş geliştirici, sistem tasarımcısı | **Claude (stüdyo)** | Tüm GDScript kodu, sahne yapısı, bot AI, ağ kodu, araç script'leri, dokümantasyon, CI |
| Yatırımcı, yapımcı, test oyuncusu | **Siz** | Yön ve öncelik kararları, oyunu bilgisayarınızda çalıştırıp test etmek, hesaplar (Meshy, Steam), bütçe |
| Model üretimi | Meshy AI (Claude'un hazırladığı prompt'larla) | Ham 3D modeller |
| Model düzenleme | Siz veya ücretli bir freelancer | Blender'da düzenleme, rig ve animasyon |
| Ses ve müzik (isteğe bağlı) | Hazır ses paketleri veya freelancer | Silah ve boya efektleri, müzik |

**Stüdyonun sınırları:**
- Oyunu ekranda görüp oynayamıyorum. "His" testi sizde olacak, bu yüzden her aşama sonunda sizden kısa bir oynanış raporu isteyeceğim.
- Meshy ve Steam hesaplarını açmak ve ödeme yapmak sizin işiniz. İsterseniz Meshy'nin API'si üzerinden model üretimini otomatikleştirebilirim.
- Blender'da görsel düzenlemeyi elle yapamam. Ancak Blender Python script'leriyle toplu işlemleri (ölçek, poligon azaltma, dışa aktarma) otomatikleştirebilirim.

---

## 7. Bütçe (9 ay, asgari senaryo)

| Kalem | Tahmini maliyet |
|---|---|
| Godot, Blender | $0 (açık kaynak) |
| Meshy AI Pro aboneliği (~$20/ay × 9) | ~$180 |
| Steam Direct kayıt ücreti | $100 (satışlar $1.000'ı geçince geri ödenir) |
| Ses ve efekt paketleri | $50–150 |
| Freelancer desteği (karakter rig ve animasyon, isteğe bağlı) | $300–1.000 |
| Fragman ve kapsül görseli (isteğe bağlı) | $200–500 |
| Test sunucusu (3. aşamadan sonra, ~$10/ay) | ~$60 |
| **Toplam** | **~$600 – $2.000** |

Steam %30 komisyon alır. $9.99 fiyat, bölgesel indirimler ve vergiler sonrası kopya başına net gelir kabaca **$5–6** olur. 1.000 satışla bütçenin tamamı karşılanır.

---

## 8. Riskler ve Önlemler

| Risk | Olasılık | Etki | Önlem |
|---|---|---|---|
| Çevrimiçi kod beklenenden zor çıkar | Yüksek | Yüksek | Önce botlu tek oyunculu mod yapılır. Online gecikirse oyun yine satılabilir durumda olur. |
| Meshy modelleri kalitesiz veya oyuna uygun değil | Orta | Orta | Stilize görsel stil, Blender'da düzeltme, gerekirse hazır CC0 model paketleri (Kenney, Quaternius) |
| Oyuncu kitlesi küçük kalır, sunucular boş olur | Yüksek | Yüksek | Botlar boş slotları doldurur. Oyun tek başına da eğlenceli olur. |
| Kapsam büyür, oyun hiç bitmez | Yüksek | Yüksek | Her aşamanın başarı kriteri var. Yeni özellik fikirleri "Erken Erişim sonrası" listesine yazılır. |
| AI ile üretilen içerik için Steam beyan zorunluluğu | Kesin | Düşük | Steam'in AI içerik formu doğru ve eksiksiz doldurulur. |
| Hile | Orta | Orta | İsabet hesaplarını sunucu yapar. |

---

## 9. Takip Edilecek Metrikler

- **Geliştirme sırasında:** Her aşamanın başarı kriteri, sizin oynanış puanınız (1–10)
- **Pazarlama:** Steam istek listesi sayısı, demo indirme sayısı, demoyu oynayanların ortalama oynama süresi
- **Satış sonrası:** Satış adedi, Steam inceleme puanı (hedef %80+ olumlu), günlük aktif oyuncu, iade oranı

---

## 10. Yatırımcıdan Beklenen Kararlar

1. **Oyun adı:** "Splatline" uygun mu, alternatif ister misiniz?
2. **Görsel stil:** Stilize ve parlak renkli (önerilen) mi, yarı gerçekçi mi?
3. **Bütçe:** Asgari (~$600) mi, freelancer destekli (~$2.000) mi?
4. **Online kapsamı:** Erken Erişim'de listen server + Steam lobileri yeterli mi? (Önerilen: evet)
5. **Test düzeni:** Her aşama sonunda (yaklaşık 2–4 haftada bir) oyunu bilgisayarınızda deneyip geri bildirim verebilir misiniz?

Onayınızla **0. Aşama**'ya başlanır: Godot 4 proje iskeleti, klasör yapısı ve oynanabilir ilk karakter kontrolcüsü.
