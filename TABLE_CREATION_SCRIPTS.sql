/* ============================================================================
   i2i Systems - Telco Project - TABLE_CREATION_SCRIPTS.sql
   ----------------------------------------------------------------------------
   Bu dosya, projedeki uc tabloyu (TARIFFS, CUSTOMERS, MONTHLY_STATS) ve
   aralarindaki iliskileri (foreign key) ve performans icin gereken index'leri
   olusturur. Calistirma sirasi onemlidir: once parent (TARIFFS), sonra ona
   bagli CUSTOMERS, en son CUSTOMERS'a bagli MONTHLY_STATS.

   Veri tipleri secimi:
   - ID'ler ve sayisal limitler NUMBER olarak tanimlanmistir.
   - Para ve kullanim degerleri (MONTHLY_FEE, DATA_USAGE) ondalik icerdigi
     icin NUMBER(p,s) olarak olceklendirilmistir.
   - Tarih DATE, metin alanlari VARCHAR2 olarak tanimlanmistir.

   NOT: Tablolar zaten mevcutsa, asagidaki DROP bloklarini calistirarak temiz
   bir baslangic yapabilirsiniz. (Bagimlilik nedeniyle once child silinir.)
   ============================================================================ */


/* ----------------------------------------------------------------------------
   (Istege bagli) Temiz baslangic: mevcut tablolari sil.
   Bagimlilik sirasi nedeniyle once MONTHLY_STATS, sonra CUSTOMERS, en son
   TARIFFS silinir. Tablo yoksa hata vermemesi icin tek tek calistirin.
   ---------------------------------------------------------------------------- */
-- DROP TABLE MONTHLY_STATS;
-- DROP TABLE CUSTOMERS;
-- DROP TABLE TARIFFS;


/* ----------------------------------------------------------------------------
   1) TARIFFS  (parent tablo)
   Tarife tanimlari. TARIFF_ID birincil anahtardir. DATA_LIMIT MB cinsindendir
   (orn. 10240 = 10 GB). Bazi tarifelerde data/dakika limiti 0 olabilir
   (orn. Kurumsal SMS yalnizca SMS paketidir).
   ---------------------------------------------------------------------------- */
CREATE TABLE TARIFFS (
    TARIFF_ID     NUMBER         NOT NULL,
    NAME          VARCHAR2(100)  NOT NULL,
    MONTHLY_FEE   NUMBER(10,2),
    DATA_LIMIT    NUMBER,
    MINUTE_LIMIT  NUMBER,
    SMS_LIMIT     NUMBER,
    CONSTRAINT PK_TARIFFS PRIMARY KEY (TARIFF_ID)
);


/* ----------------------------------------------------------------------------
   2) CUSTOMERS  (TARIFFS'e bagli)
   Musteri kayitlari. CUSTOMER_ID birincil anahtardir. TARIFF_ID, TARIFFS
   tablosuna foreign key ile baglidir; boylece her musterinin gecerli bir
   tarifesi olmasi garanti edilir. SIGNUP_DATE musterinin kayit tarihidir.
   ---------------------------------------------------------------------------- */
CREATE TABLE CUSTOMERS (
    CUSTOMER_ID   NUMBER         NOT NULL,
    NAME          VARCHAR2(100),
    CITY          VARCHAR2(100),
    SIGNUP_DATE   DATE,
    TARIFF_ID     NUMBER,
    CONSTRAINT PK_CUSTOMERS PRIMARY KEY (CUSTOMER_ID),
    CONSTRAINT FK_CUSTOMER_TARIFF FOREIGN KEY (TARIFF_ID)
        REFERENCES TARIFFS (TARIFF_ID)
);


/* ----------------------------------------------------------------------------
   3) MONTHLY_STATS  (CUSTOMERS'a bagli)
   Aylik kullanim ve odeme kayitlari. ID birincil anahtardir. CUSTOMER_ID,
   CUSTOMERS tablosuna foreign key ile baglidir. DATA_USAGE ondalik oldugu
   icin NUMBER(12,2)'dir. PAYMENT_STATUS uc deger alir: PAID, LATE, UNPAID.
   Not: Bazi musterilerin bu tabloda kaydi olmayabilir (kasitli eksik kayitlar).
   ---------------------------------------------------------------------------- */
CREATE TABLE MONTHLY_STATS (
    ID             NUMBER        NOT NULL,
    CUSTOMER_ID    NUMBER,
    DATA_USAGE     NUMBER(12,2),
    MINUTE_USAGE   NUMBER,
    SMS_USAGE      NUMBER,
    PAYMENT_STATUS VARCHAR2(50),
    CONSTRAINT PK_MONTHLY_STATS PRIMARY KEY (ID),
    CONSTRAINT FK_STATS_CUSTOMER FOREIGN KEY (CUSTOMER_ID)
        REFERENCES CUSTOMERS (CUSTOMER_ID)
);


/* ----------------------------------------------------------------------------
   4) INDEX'LER
   Foreign key kolonlari ve sorgularda sik filtrelenen/gruplanan kolonlar icin
   index olusturulur. Bu, JOIN ve WHERE/GROUP BY islemlerini hizlandirir.
   (Primary key'ler Oracle tarafindan otomatik index'lendigi icin tekrar
   index'lenmez.)
   ---------------------------------------------------------------------------- */

-- CUSTOMERS.TARIFF_ID: tarife bazli JOIN ve dagilim sorgularini hizlandirir.
CREATE INDEX IX_CUSTOMERS_TARIFF  ON CUSTOMERS (TARIFF_ID);

-- CUSTOMERS.SIGNUP_DATE: kayit tarihine gore siralama/filtrelemeyi hizlandirir.
CREATE INDEX IX_CUSTOMERS_SIGNUP  ON CUSTOMERS (SIGNUP_DATE);

-- CUSTOMERS.CITY: sehir bazli gruplama sorgularini hizlandirir.
CREATE INDEX IX_CUSTOMERS_CITY    ON CUSTOMERS (CITY);

-- MONTHLY_STATS.CUSTOMER_ID: musteri bazli JOIN ve eksik-kayit sorgularini hizlandirir.
CREATE INDEX IX_STATS_CUSTOMER    ON MONTHLY_STATS (CUSTOMER_ID);

-- MONTHLY_STATS.PAYMENT_STATUS: odeme durumu bazli filtre/gruplamayi hizlandirir.
CREATE INDEX IX_STATS_PAYMENT     ON MONTHLY_STATS (PAYMENT_STATUS);


/* ============================================================================
   SON. Tablolar dogru sirayla, birincil anahtar ve foreign key kisitlariyla
   ve performans index'leriyle birlikte olusturulmustur. Verileri yukledikten
   sonra SOLUTIONS.sql dosyasindaki sorgular calistirilabilir.
   ============================================================================ */
