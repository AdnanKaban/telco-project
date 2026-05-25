-- Telco Project - SQL cozumleri
-- Tablolar: TARIFFS, CUSTOMERS (tarife -> TARIFF_ID), MONTHLY_STATS (musteri -> CUSTOMER_ID)
-- Tarifeler: 1 Genc Dinamik, 2 Kurumsal SMS, 3 Calisan GB, 4 Kobiye Destek
-- Odeme durumlari: PAID, LATE, UNPAID


-- 1.1 Kobiye Destek tarifesine abone olan musteriler
-- Tarife adi CUSTOMERS'ta degil TARIFFS'te oldugu icin iki tabloyu TARIFF_ID
-- uzerinden birlestiriyorum. Sabit ID yerine tarife adina gore filtreledim,
-- boylece ID degisse bile sorgu calismaya devam eder.
SELECT c.CUSTOMER_ID, c.NAME, c.CITY, c.SIGNUP_DATE
FROM   CUSTOMERS c
JOIN   TARIFFS   t ON c.TARIFF_ID = t.TARIFF_ID
WHERE  t.NAME = 'Kobiye Destek'
ORDER  BY c.CUSTOMER_ID;
-- 2483 musteri donuyor.


-- 1.2 Bu tarifeye abone olan en yeni musteri
-- En yeni = en gec kayit tarihi, o yuzden SIGNUP_DATE'e gore tersten siraladim.
-- Ayni tarihte birden fazla kayit olabilir, esitligi en buyuk CUSTOMER_ID ile
-- bozuyorum. Tek satir istedigim icin FETCH FIRST 1 ROW ONLY kullandim.
SELECT c.CUSTOMER_ID, c.NAME, c.CITY, c.SIGNUP_DATE
FROM   CUSTOMERS c
JOIN   TARIFFS   t ON c.TARIFF_ID = t.TARIFF_ID
WHERE  t.NAME = 'Kobiye Destek'
ORDER  BY c.SIGNUP_DATE DESC, c.CUSTOMER_ID DESC
FETCH FIRST 1 ROW ONLY;
-- CUSTOMER_ID 8295, Omer, 05/04/2026.


-- 2.1 Tarifelerin musteriler arasindaki dagilimi
-- Her tarifede kac musteri var diye TARIFF_ID bazinda gruplayip saydim.
-- Tarife adini gostermek icin TARIFFS ile join ettim; her musterinin gecerli
-- bir tarifesi oldugu icin normal join yeterli. En kalabalik tarife uste gelsin
-- diye sayiya gore azalan siraladim.
SELECT t.TARIFF_ID, t.NAME, COUNT(c.CUSTOMER_ID) AS CUSTOMER_COUNT
FROM   TARIFFS   t
JOIN   CUSTOMERS c ON c.TARIFF_ID = t.TARIFF_ID
GROUP  BY t.TARIFF_ID, t.NAME
ORDER  BY CUSTOMER_COUNT DESC;
-- Kurumsal SMS 2577, Genc Dinamik 2527, Kobiye Destek 2483, Calisan GB 2413.


-- 3.1 En erken kaydolan musteriler
-- ID sirasi kayit sirasini yansitmiyor (dusuk ID illa erken degil), o yuzden
-- tarihe bakmak gerekiyor. En kucuk SIGNUP_DATE'i alt sorguyla bulup ona esit
-- olan tum kayitlari getiriyorum, boylece ayni gun kaydolanlarin hepsi geliyor.
SELECT c.CUSTOMER_ID, c.NAME, c.CITY, c.SIGNUP_DATE
FROM   CUSTOMERS c
WHERE  c.SIGNUP_DATE = (SELECT MIN(SIGNUP_DATE) FROM CUSTOMERS)
ORDER  BY c.CUSTOMER_ID;
-- En erken tarih 07/04/2025, o gun kaydolan 35 musteri var.


-- 3.2 Bu en erken musterilerin sehir dagilimi
-- Yukaridaki en erken musteri kumesini bu sefer sehir bazinda gruplluyorum.
-- En erken tarihi yine alt sorgu ile buluyorum, sonra CITY'ye gore sayiyorum.
-- En cok musterisi olan sehir uste gelecek sekilde siraladim.
SELECT c.CITY, COUNT(*) AS CUSTOMER_COUNT
FROM   CUSTOMERS c
WHERE  c.SIGNUP_DATE = (SELECT MIN(SIGNUP_DATE) FROM CUSTOMERS)
GROUP  BY c.CITY
ORDER  BY CUSTOMER_COUNT DESC, c.CITY;
-- En cok Antalya, Gaziantep, Sirnak (ikiser), kalan sehirler birer.


-- 4.1 Aylik kaydi eksik olan musteriler
-- Eksik musteri = CUSTOMERS'ta olup MONTHLY_STATS'ta karsiligi olmayan.
-- MONTHLY_STATS'taki musteri ID'lerinin disinda kalanlari NOT IN ile buluyorum.
-- Alt sorguda NULL gelirse NOT IN bozulacagi icin IS NOT NULL kosulu ekledim.
SELECT c.CUSTOMER_ID, c.NAME, c.CITY
FROM   CUSTOMERS c
WHERE  c.CUSTOMER_ID NOT IN (SELECT ms.CUSTOMER_ID
                             FROM   MONTHLY_STATS ms
                             WHERE  ms.CUSTOMER_ID IS NOT NULL)
ORDER  BY c.CUSTOMER_ID;
-- 50 musteri eksik (orn. 6, 10, 31, ...).


-- 4.2 Eksik musterilerin sehir dagilimi
-- 4.1'deki ayni NOT IN mantigini kullanip eksik musterileri buluyorum.
-- Bu sefer sonucu CITY'ye gore gruplayip her sehirdeki eksik sayisini sayiyorum.
-- En cok eksigi olan sehir uste gelsin diye azalan siraladim.
SELECT c.CITY, COUNT(*) AS MISSING_COUNT
FROM   CUSTOMERS c
WHERE  c.CUSTOMER_ID NOT IN (SELECT ms.CUSTOMER_ID
                             FROM   MONTHLY_STATS ms
                             WHERE  ms.CUSTOMER_ID IS NOT NULL)
GROUP  BY c.CITY
ORDER  BY MISSING_COUNT DESC, c.CITY;
-- En cok Osmaniye (3), sonra Bitlis, Denizli, Kayseri, Izmir vb. ikiser.


-- 5.1 Data limitinin en az %75'ini kullananlar
-- Limit TARIFFS'te, kullanim MONTHLY_STATS'te oldugu icin uc tabloyu birlestirdim.
-- Kosul olarak DATA_USAGE'in limitin %75'ine ulasmasini aradim.
-- Kurumsal SMS gibi data limiti 0 olan tarifelerde oranlama anlamsiz ve sifira
-- bolme riski var, o yuzden DATA_LIMIT > 0 filtresini ekledim.
SELECT c.CUSTOMER_ID, c.NAME, t.NAME AS TARIFF_NAME,
       t.DATA_LIMIT, ms.DATA_USAGE,
       ROUND(ms.DATA_USAGE / t.DATA_LIMIT * 100, 1) AS USAGE_PCT
FROM   CUSTOMERS     c
JOIN   TARIFFS       t  ON c.TARIFF_ID    = t.TARIFF_ID
JOIN   MONTHLY_STATS ms ON ms.CUSTOMER_ID = c.CUSTOMER_ID
WHERE  t.DATA_LIMIT > 0
AND    ms.DATA_USAGE >= 0.75 * t.DATA_LIMIT
ORDER  BY USAGE_PCT DESC, c.CUSTOMER_ID;
-- 1880 musteri, en yuksek kullanim %100'e dayaniyor.


-- 5.2 Tum limitleri (data, dakika, sms) tamamen tuketenler
-- Uc kategorinin de limitine ulasmis olmasi gerekiyor, kosullari AND ile bagladim.
-- Bazi tarifelerde limit 0 (orn. Kurumsal SMS'in datasi ve dakikasi), 0 limitli
-- bir kategoriyi tuketmek mumkun olmadigi icin onu otomatik saglanmis sayiyorum
-- ve sadece sifirdan buyuk limitlerde kullanim >= limit kontrolu yapiyorum.
SELECT c.CUSTOMER_ID, c.NAME, t.NAME AS TARIFF_NAME,
       ms.DATA_USAGE,   t.DATA_LIMIT,
       ms.MINUTE_USAGE, t.MINUTE_LIMIT,
       ms.SMS_USAGE,    t.SMS_LIMIT
FROM   CUSTOMERS     c
JOIN   TARIFFS       t  ON c.TARIFF_ID    = t.TARIFF_ID
JOIN   MONTHLY_STATS ms ON ms.CUSTOMER_ID = c.CUSTOMER_ID
WHERE  (t.DATA_LIMIT   = 0 OR ms.DATA_USAGE   >= t.DATA_LIMIT)
AND    (t.MINUTE_LIMIT = 0 OR ms.MINUTE_USAGE >= t.MINUTE_LIMIT)
AND    (t.SMS_LIMIT    = 0 OR ms.SMS_USAGE    >= t.SMS_LIMIT)
ORDER  BY c.CUSTOMER_ID;
-- Bu veride uc limiti birden dolduran kimse yok, sorgu bos donuyor.


-- 6.1 Odenmemis faturasi olan musteriler
-- PAYMENT_STATUS uc deger aliyor: PAID, LATE, UNPAID. Odenmemis derken PAID
-- disinda kalan her seyi (hem UNPAID hem LATE) saydim. Sadece kesin odenmeyenler
-- isteniyorsa alttaki yorum satirindaki UNPAID filtresine gecmek yeterli.
SELECT c.CUSTOMER_ID, c.NAME, c.CITY, ms.PAYMENT_STATUS
FROM   CUSTOMERS     c
JOIN   MONTHLY_STATS ms ON ms.CUSTOMER_ID = c.CUSTOMER_ID
WHERE  ms.PAYMENT_STATUS <> 'PAID'
-- WHERE  ms.PAYMENT_STATUS = 'UNPAID'
ORDER  BY c.CUSTOMER_ID;
-- PAID disi (LATE + UNPAID) 2951 satir; sadece UNPAID alirsak 1454.


-- 6.2 Odeme durumlarinin tarifelere gore dagilimi
-- Burada iki kirilim var: hem tarife hem odeme durumu, ikisine gore grupladim.
-- Tarife adi icin TARIFFS, odeme durumu icin MONTHLY_STATS gerektiginden uc
-- tabloyu birlestirdim. Once tarifeye sonra duruma gore siralayip okunabilir
-- bir tablo cikardim.
SELECT t.TARIFF_ID, t.NAME AS TARIFF_NAME, ms.PAYMENT_STATUS,
       COUNT(*) AS STATUS_COUNT
FROM   TARIFFS       t
JOIN   CUSTOMERS     c  ON c.TARIFF_ID    = t.TARIFF_ID
JOIN   MONTHLY_STATS ms ON ms.CUSTOMER_ID = c.CUSTOMER_ID
GROUP  BY t.TARIFF_ID, t.NAME, ms.PAYMENT_STATUS
ORDER  BY t.TARIFF_ID, ms.PAYMENT_STATUS;
-- 12 satir (4 tarife x 3 durum). Orn. Genc Dinamik: PAID 1792, LATE 372, UNPAID 352.
