/* ============================================================================
   i2i Systems - Telco Project - SOLUTIONS.sql
   ----------------------------------------------------------------------------
   Bu dosya, projedeki 6 baslik altindaki tum sorulara ait SQL cozumlerini
   icerir. README geregi, her sorgunun ustunde yaklasimi aciklayan en az uc
   cumlelik yorum bulunur. Tablolar: TARIFFS (parent), CUSTOMERS (TARIFF_ID
   ile baglidir), MONTHLY_STATS (CUSTOMER_ID ile baglidir).

   Tarife referansi (TARIFFS):
     1 = Genc Dinamik    (data=10240 MB, dk=600,  sms=600)
     2 = Kurumsal SMS    (data=0,        dk=0,    sms=10000)  -> sadece SMS
     3 = Calisan GB      (data=20480 MB, dk=1000, sms=250)
     4 = Kobiye Destek   (data=20480 MB, dk=1000, sms=1000)
   Odeme durumlari (MONTHLY_STATS.PAYMENT_STATUS): PAID, LATE, UNPAID
   ============================================================================ */


/* ============================================================================
   1. TARIFE BAZLI MUSTERI SORGULARI
   ============================================================================ */

/* ---------------------------------------------------------------------------
   1.1  'Kobiye Destek' tarifesine abone olan musterileri listele.
   ---------------------------------------------------------------------------
   Aciklama:
   CUSTOMERS tablosu tarifeyi TARIFF_ID ile tutar, tarife adi ise TARIFFS
   tablosunda bulunur; bu yuzden iki tabloyu TARIFF_ID uzerinden JOIN ederiz.
   Tarife adini sabit ID (4) yerine NAME='Kobiye Destek' filtresiyle aramak,
   ID degisse bile sorgunun dogru calismasini saglar ve daha okunabilirdir.
   Sonucu CUSTOMER_ID'ye gore siralayarak duzenli bir cikti elde ederiz.
*/
SELECT c.CUSTOMER_ID,
       c.NAME,
       c.CITY,
       c.SIGNUP_DATE
FROM   CUSTOMERS c
JOIN   TARIFFS   t ON c.TARIFF_ID = t.TARIFF_ID
WHERE  t.NAME = 'Kobiye Destek'
ORDER  BY c.CUSTOMER_ID;
-- SONUC: 2483 satir dondu (Kobiye Destek tarifesine abone 2483 musteri).


/* ---------------------------------------------------------------------------
   1.2  Bu tarifeye abone olan EN YENI musteriyi bul.
   ---------------------------------------------------------------------------
   Aciklama:
   "En yeni" musteri, SIGNUP_DATE'i en buyuk (en gec) olan musteridir; bu
   yuzden tarihe gore azalan siralama yapariz. Ayni tarihte birden fazla
   musteri olabilecegi icin, esitligi bozmak adina ikinci kriter olarak en
   yuksek CUSTOMER_ID'yi kullaniriz. Oracle'da ilk satiri almak icin modern
   ve okunabilir bir yontem olan FETCH FIRST 1 ROW ONLY kullanilir.
*/
SELECT c.CUSTOMER_ID,
       c.NAME,
       c.CITY,
       c.SIGNUP_DATE
FROM   CUSTOMERS c
JOIN   TARIFFS   t ON c.TARIFF_ID = t.TARIFF_ID
WHERE  t.NAME = 'Kobiye Destek'
ORDER  BY c.SIGNUP_DATE DESC, c.CUSTOMER_ID DESC
FETCH FIRST 1 ROW ONLY;
-- SONUC: 1 satir. En yeni musteri -> CUSTOMER_ID=8295, NAME=Omer, SIGNUP_DATE=05/04/2026.


/* ============================================================================
   2. TARIFE DAGILIMI
   ============================================================================ */

/* ---------------------------------------------------------------------------
   2.1  Musteriler arasinda tarifelerin dagilimini bul.
   ---------------------------------------------------------------------------
   Aciklama:
   Her tarifeye kac musterinin abone oldugunu bulmak icin TARIFF_ID'ye gore
   GROUP BY yapip COUNT aliriz. Tarife adini da gostermek icin TARIFFS ile
   JOIN ederiz; LEFT JOIN yerine normal JOIN yeterlidir cunku her musterinin
   gecerli bir tarifesi vardir. Dagilimi gormeyi kolaylastirmak adina sonucu
   musteri sayisina gore azalan sirada listeleriz.
*/
SELECT t.TARIFF_ID,
       t.NAME,
       COUNT(c.CUSTOMER_ID) AS CUSTOMER_COUNT
FROM   TARIFFS   t
JOIN   CUSTOMERS c ON c.TARIFF_ID = t.TARIFF_ID
GROUP  BY t.TARIFF_ID, t.NAME
ORDER  BY CUSTOMER_COUNT DESC;
-- SONUC: 4 satir. Kurumsal SMS=2577, Genc Dinamik=2527, Kobiye Destek=2483, Calisan GB=2413.


/* ============================================================================
   3. MUSTERI KAYIT (SIGNUP) ANALIZI
   ============================================================================ */

/* ---------------------------------------------------------------------------
   3.1  En erken kaydolan musterileri belirle.
        (Ipucu: en erken musteriler en dusuk ID'ye sahip olmayabilir.)
   ---------------------------------------------------------------------------
   Aciklama:
   "En erken" kayit, en kucuk SIGNUP_DATE degeridir; ID sirasi kayit sirasini
   yansitmadigi icin siralamayi tarihe gore yapariz. Birden fazla musteri ayni
   en erken tarihte kaydolmus olabilecegi icin, tek bir satir yerine o en erken
   tarihe esit olan TUM musterileri getiririz. Bunu, alt sorgu ile minimum
   tarihi bulup ona esit olanlari secerek yapariz; boylece beraberlikler de
   sonuca dahil olur.
*/
SELECT c.CUSTOMER_ID,
       c.NAME,
       c.CITY,
       c.SIGNUP_DATE
FROM   CUSTOMERS c
WHERE  c.SIGNUP_DATE = (SELECT MIN(SIGNUP_DATE) FROM CUSTOMERS)
ORDER  BY c.CUSTOMER_ID;
-- SONUC: 35 satir. En erken kayit tarihi = 07/04/2025, bu tarihte 35 musteri kaydolmus.


/* ---------------------------------------------------------------------------
   3.2  Bu en erken musterilerin sehirlere gore dagilimini, her sehir icin
        toplam sayiyla birlikte bul.
   ---------------------------------------------------------------------------
   Aciklama:
   3.1'deki en erken musteri kumesini temel alip, bu kez sehir bazinda
   gruplariz. En erken tarihi yine bir alt sorgu ile buluruz ve sadece o
   tarihe esit kayitlari filtreleriz. CITY'ye gore GROUP BY yapip COUNT ile
   her sehirdeki en erken musteri sayisini elde eder, en kalabalik sehir uste
   gelecek sekilde siralariz.
*/
SELECT c.CITY,
       COUNT(*) AS CUSTOMER_COUNT
FROM   CUSTOMERS c
WHERE  c.SIGNUP_DATE = (SELECT MIN(SIGNUP_DATE) FROM CUSTOMERS)
GROUP  BY c.CITY
ORDER  BY CUSTOMER_COUNT DESC, c.CITY;
-- SONUC: En erken (07/04/2025) musteriler sehirlere dagilmis; en cok Antalya, Gaziantep, Sirnak (2'ser), digerleri 1'er.


/* ============================================================================
   4. EKSIK AYLIK KAYITLAR
   ============================================================================ */

/* ---------------------------------------------------------------------------
   4.1  Bazi musterilerin aylik kaydi (MONTHLY_STATS) eksik. Bu eksik
        musterilerin ID'lerini bul.
   ---------------------------------------------------------------------------
   Aciklama:
   Her musterinin bir aylik kaydi olmasi beklenir; eksik olanlar, CUSTOMERS'ta
   bulunup MONTHLY_STATS'ta KARSILIGI OLMAYAN musterilerdir. Bunu bulmak icin
   bir anti-join kullaniriz: MONTHLY_STATS'taki CUSTOMER_ID kumesinde yer
   ALMAYAN musterileri NOT IN ile sececegiz. (NULL guvenligi icin alt sorguya
   CUSTOMER_ID IS NOT NULL kosulu eklenmistir.) Beklenen sonuc 50 musteridir.
*/
SELECT c.CUSTOMER_ID,
       c.NAME,
       c.CITY
FROM   CUSTOMERS c
WHERE  c.CUSTOMER_ID NOT IN (SELECT ms.CUSTOMER_ID
                             FROM   MONTHLY_STATS ms
                             WHERE  ms.CUSTOMER_ID IS NOT NULL)
ORDER  BY c.CUSTOMER_ID;
-- SONUC: 50 satir. MONTHLY_STATS'ta kaydi olmayan 50 musteri (orn. CUSTOMER_ID=6, 10, 31, ...).


/* ---------------------------------------------------------------------------
   4.2  Bu eksik musterilerin sehirlere gore dagilimini bul.
   ---------------------------------------------------------------------------
   Aciklama:
   4.1'deki eksik musteri kumesini alip sehir bazinda gruplariz. Ayni anti-join
   mantigini (NOT IN) WHERE kosulunda tekrar kullaniriz, ardindan CITY'ye gore
   GROUP BY yapariz. COUNT ile her sehirdeki eksik musteri sayisini bulur ve
   en cok eksigi olan sehir uste gelecek sekilde siralariz.
*/
SELECT c.CITY,
       COUNT(*) AS MISSING_COUNT
FROM   CUSTOMERS c
WHERE  c.CUSTOMER_ID NOT IN (SELECT ms.CUSTOMER_ID
                             FROM   MONTHLY_STATS ms
                             WHERE  ms.CUSTOMER_ID IS NOT NULL)
GROUP  BY c.CITY
ORDER  BY MISSING_COUNT DESC, c.CITY;
-- SONUC: Eksik musteriler sehirlere dagilmis; en cok OSMANIYE (3), ardindan Bitlis/Denizli/Kayseri/Izmir/Mus/Nevsehir/Ordu/Sivas/Kirikkale (2'ser).


/* ============================================================================
   5. KULLANIM ANALIZI
   ============================================================================ */

/* ---------------------------------------------------------------------------
   5.1  Veri (data) limitinin EN AZ %75'ini kullanan musterileri bul.
   ---------------------------------------------------------------------------
   Aciklama:
   Bir musterinin data limiti tarifesinde (TARIFFS.DATA_LIMIT) tanimlidir,
   kullanimi ise MONTHLY_STATS.DATA_USAGE'da bulunur; bu yuzden uc tabloyu
   JOIN ederiz. "En az %75" kosulu DATA_USAGE >= 0.75 * DATA_LIMIT seklinde
   yazilir. Data limiti 0 olan tarifeler (Kurumsal SMS) icin oranlama anlamsiz
   ve sifira bolme riski tasidigi icin DATA_LIMIT > 0 kosulu eklenir.
*/
SELECT c.CUSTOMER_ID,
       c.NAME,
       t.NAME              AS TARIFF_NAME,
       t.DATA_LIMIT,
       ms.DATA_USAGE,
       ROUND(ms.DATA_USAGE / t.DATA_LIMIT * 100, 1) AS USAGE_PCT
FROM   CUSTOMERS     c
JOIN   TARIFFS       t  ON c.TARIFF_ID   = t.TARIFF_ID
JOIN   MONTHLY_STATS ms ON ms.CUSTOMER_ID = c.CUSTOMER_ID
WHERE  t.DATA_LIMIT > 0
AND    ms.DATA_USAGE >= 0.75 * t.DATA_LIMIT
ORDER  BY USAGE_PCT DESC, c.CUSTOMER_ID;
-- SONUC: 1880 satir. Data limitinin en az %75'ini kullanan 1880 musteri (en yuksek kullanim %100'e ulasiyor).


/* ---------------------------------------------------------------------------
   5.2  Tum paket limitlerini (data, dakika VE sms) tamamen tuketen
        musterileri bul.
   ---------------------------------------------------------------------------
   Aciklama:
   "Tamamen tuketmek", her kategoride kullanimin ilgili limite ulasmasi ya da
   asmasi demektir; bu yuzden uc kosulu da AND ile birlestiririz. Ancak bazi
   tarifelerde limit 0'dir (orn. Kurumsal SMS'te data ve dakika limiti 0);
   limiti 0 olan bir kategoriyi "tuketmek" mumkun olmadigindan, sadece limiti
   0'dan buyuk olan kategoriler icin "kullanim >= limit" kosulunu uygularken,
   limiti 0 olan kategoriyi otomatik saglanmis sayariz. Boylece her musteri
   kendi tarifesinin gercek (sifirdan buyuk) limitleri uzerinden degerlendirilir.
*/
SELECT c.CUSTOMER_ID,
       c.NAME,
       t.NAME AS TARIFF_NAME,
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
-- SONUC: 0 satir. Bu veri setinde data+dakika+sms limitlerinin UCUNU birden tam tuketen musteri yok (sorgu dogru, sonuc bos).


/* ============================================================================
   6. ODEME ANALIZI
   ============================================================================ */

/* ---------------------------------------------------------------------------
   6.1  Odenmemis faturasi olan musterileri bul.
   ---------------------------------------------------------------------------
   Aciklama:
   Odeme durumu MONTHLY_STATS.PAYMENT_STATUS'ta tutulur ve uc deger alir:
   PAID (odendi), LATE (gec/geciken), UNPAID (odenmedi). "Odenmemis" ifadesi,
   PAID DISINDAKI tum durumlari, yani UNPAID ve LATE'i kapsayacak sekilde genis
   yorumlanmistir; bu yuzden PAYMENT_STATUS <> 'PAID' filtresi kullanilir.
   (Yalnizca kesin odenmeyenler istenirse PAYMENT_STATUS = 'UNPAID' kullanmak
   yeterlidir; ilgili satir asagida yorum olarak birakilmistir.)
*/
SELECT c.CUSTOMER_ID,
       c.NAME,
       c.CITY,
       ms.PAYMENT_STATUS
FROM   CUSTOMERS     c
JOIN   MONTHLY_STATS ms ON ms.CUSTOMER_ID = c.CUSTOMER_ID
WHERE  ms.PAYMENT_STATUS <> 'PAID'
-- WHERE  ms.PAYMENT_STATUS = 'UNPAID'   -- yalnizca kesin odenmeyenler icin
ORDER  BY c.CUSTOMER_ID;
-- SONUC: 2951 satir (PAID disi: LATE + UNPAID). Yalnizca UNPAID istenirse 1454 satir doner.


/* ---------------------------------------------------------------------------
   6.2  Tum odeme durumlarinin tarifelere gore dagilimini bul.
   ---------------------------------------------------------------------------
   Aciklama:
   Bu, iki boyutlu bir dagilimdir: her tarife icin her odeme durumunun sayisi.
   Bu yuzden hem tarife (TARIFFS uzerinden) hem de PAYMENT_STATUS'a gore
   GROUP BY yapariz. Uc tabloyu JOIN ederek tarife adini ve odeme durumunu
   bir araya getirir, COUNT ile her kombinasyonun adedini buluruz. Sonucu once
   tarifeye, sonra odeme durumuna gore siralayarak okunabilir bir tablo elde
   ederiz.
*/
SELECT t.TARIFF_ID,
       t.NAME            AS TARIFF_NAME,
       ms.PAYMENT_STATUS,
       COUNT(*)          AS STATUS_COUNT
FROM   TARIFFS       t
JOIN   CUSTOMERS     c  ON c.TARIFF_ID    = t.TARIFF_ID
JOIN   MONTHLY_STATS ms ON ms.CUSTOMER_ID = c.CUSTOMER_ID
GROUP  BY t.TARIFF_ID, t.NAME, ms.PAYMENT_STATUS
ORDER  BY t.TARIFF_ID, ms.PAYMENT_STATUS;
-- SONUC: 12 satir (4 tarife x 3 durum). Orn. Genc Dinamik: LATE=372, PAID=1792, UNPAID=352; Kurumsal SMS: LATE=368, PAID=1796, UNPAID=403; Calisan GB: LATE=365, PAID=1692, UNPAID=339; Kobiye Destek: LATE=392, PAID=1719, UNPAID=360.


/* ============================================================================
   SON. Tum sorgular test edilmis ve aciklamalari README gerekliligine
   (her sorgu icin en az 3 cumle) uygun sekilde yazilmistir.
   ============================================================================ */
