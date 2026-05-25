-- Telco Project - tablo olusturma scriptleri
-- Sira onemli: once TARIFFS, sonra ona bagli CUSTOMERS, en son MONTHLY_STATS.
-- Tablolar zaten varsa asagidaki DROP'lari sirayla acip calistirabilirsiniz.

-- DROP TABLE MONTHLY_STATS;
-- DROP TABLE CUSTOMERS;
-- DROP TABLE TARIFFS;


-- Tarife tanimlari. DATA_LIMIT MB cinsinden (10240 = 10 GB).
-- Bazi tarifelerde data/dakika limiti 0 olabiliyor (Kurumsal SMS gibi).
CREATE TABLE TARIFFS (
    TARIFF_ID     NUMBER         NOT NULL,
    NAME          VARCHAR2(100)  NOT NULL,
    MONTHLY_FEE   NUMBER(10,2),
    DATA_LIMIT    NUMBER,
    MINUTE_LIMIT  NUMBER,
    SMS_LIMIT     NUMBER,
    CONSTRAINT PK_TARIFFS PRIMARY KEY (TARIFF_ID)
);


-- Musteriler. TARIFF_ID ile TARIFFS'e bagli, boylece gecersiz tarife girilemiyor.
CREATE TABLE CUSTOMERS (
    CUSTOMER_ID   NUMBER         NOT NULL,
    NAME          VARCHAR2(100),
    CITY          VARCHAR2(100),
    SIGNUP_DATE   DATE,
    TARIFF_ID     NUMBER,
    CONSTRAINT PK_CUSTOMERS PRIMARY KEY (CUSTOMER_ID),
    CONSTRAINT FK_CUSTOMER_TARIFF FOREIGN KEY (TARIFF_ID) REFERENCES TARIFFS (TARIFF_ID)
);


-- Aylik kullanim ve odeme kayitlari. DATA_USAGE ondalikli oldugu icin NUMBER(12,2).
-- PAYMENT_STATUS: PAID / LATE / UNPAID. Bazi musterilerin burada kaydi yok.
CREATE TABLE MONTHLY_STATS (
    ID             NUMBER        NOT NULL,
    CUSTOMER_ID    NUMBER,
    DATA_USAGE     NUMBER(12,2),
    MINUTE_USAGE   NUMBER,
    SMS_USAGE      NUMBER,
    PAYMENT_STATUS VARCHAR2(50),
    CONSTRAINT PK_MONTHLY_STATS PRIMARY KEY (ID),
    CONSTRAINT FK_STATS_CUSTOMER FOREIGN KEY (CUSTOMER_ID) REFERENCES CUSTOMERS (CUSTOMER_ID)
);


-- Sorgularda sik kullanilan foreign key ve filtre/gruplama kolonlari icin index.
-- Primary key'ler zaten otomatik index'lendigi icin onlari tekrar eklemedim.
CREATE INDEX IX_CUSTOMERS_TARIFF ON CUSTOMERS (TARIFF_ID);
CREATE INDEX IX_CUSTOMERS_SIGNUP ON CUSTOMERS (SIGNUP_DATE);
CREATE INDEX IX_CUSTOMERS_CITY   ON CUSTOMERS (CITY);
CREATE INDEX IX_STATS_CUSTOMER   ON MONTHLY_STATS (CUSTOMER_ID);
CREATE INDEX IX_STATS_PAYMENT    ON MONTHLY_STATS (PAYMENT_STATUS);
