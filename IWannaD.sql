CREATE DATABASE CosmeticsShopDB;
GO

USE CosmeticsShopDB;
GO

CREATE TABLE Users (
    ID_User INT PRIMARY KEY IDENTITY(1,1),
    LastName VARCHAR(50) NOT NULL,    
	FirstName VARCHAR(50) NOT NULL,    
	MiddleName VARCHAR(50) NULL,      
    Email VARCHAR(100) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    Phone VARCHAR(20) UNIQUE,
    RoleUs VARCHAR(20) NOT NULL CHECK (RoleUs IN ('Клиент','Менеджер','Администратор')),
    DateRegistered DATE NOT NULL DEFAULT GETDATE(),
    StatusUs VARCHAR(20) NOT NULL DEFAULT 'Активен'
);

CREATE TABLE UserProfiles (
    ID_Profile INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL UNIQUE,
    AddressPr VARCHAR(200),
    CityPr VARCHAR(100),
    PostalCodePr VARCHAR(20),
    BirthDate DATE,
    Gender VARCHAR(10) CHECK (Gender IN ('Мужской','Женский','Не указан')),
    Preferences VARCHAR(200),
    CONSTRAINT FK_UserProfiles_Users FOREIGN KEY (UserID) REFERENCES Users(ID_User) ON DELETE CASCADE
);

CREATE TABLE Categories (
    ID_Category INT PRIMARY KEY IDENTITY(1,1),
    NameCa VARCHAR(100) NOT NULL UNIQUE,
    DescriptionCa VARCHAR(200)
);

CREATE TABLE Products (
    ID_Product INT PRIMARY KEY IDENTITY(1,1),
    CategoryID INT NOT NULL,
    NamePr VARCHAR(100) NOT NULL,
    DescriptionPr VARCHAR(300),
    BrandPr VARCHAR(100),
    Price DECIMAL(10,2) NOT NULL CHECK (Price > 0),
    StockQuantity INT NOT NULL CHECK (StockQuantity >= 0),
    IsAvailable BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(ID_Category)
);

CREATE TABLE PromoCodes (
    ID_Promo INT PRIMARY KEY IDENTITY(1,1),
    Code VARCHAR(50) NOT NULL UNIQUE,
    DiscountPercent INT CHECK (DiscountPercent BETWEEN 1 AND 100),
    MaxUsage INT CHECK (MaxUsage >= 0),
    ExpiryDate DATE,
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE Orders (
    ID_Order INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) NOT NULL CHECK (TotalAmount >= 0),
    StatusOr VARCHAR(20) NOT NULL CHECK (StatusOr IN ('В обработке','Собирается','Доставлен','Отменён')),
    DeliveryAddress VARCHAR(200),
    PromoID INT NULL,
    CONSTRAINT FK_Orders_Users FOREIGN KEY (UserID) REFERENCES Users(ID_User),
    CONSTRAINT FK_Orders_PromoCodes FOREIGN KEY (PromoID) REFERENCES PromoCodes(ID_Promo)
);

CREATE TABLE OrderDetails (
    ID_OrderDetail INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID) REFERENCES Orders(ID_Order) ON DELETE CASCADE,
    CONSTRAINT FK_OrderDetails_Products FOREIGN KEY (ProductID) REFERENCES Products(ID_Product)
);

CREATE TABLE Reviews (
    ID_Review INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT NOT NULL,
    UserID INT NOT NULL,
    Rating INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    CommentRe VARCHAR(500),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Reviews_Products FOREIGN KEY (ProductID) REFERENCES Products(ID_Product) ON DELETE CASCADE,
    CONSTRAINT FK_Reviews_Users FOREIGN KEY (UserID) REFERENCES Users(ID_User) ON DELETE CASCADE
);


CREATE TABLE AuditLogs (
    ID_Log INT PRIMARY KEY IDENTITY(1,1), 
    UserID INT NULL,                      
    UserName VARCHAR(130) NULL,          
    TableName VARCHAR(130) NOT NULL,     
    ActionType VARCHAR(50) NOT NULL,    
    OldData VARCHAR(MAX) NULL,           
    NewData VARCHAR(MAX) NULL,           
    TimestampMl DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_AuditLogs_Users FOREIGN KEY (UserID) REFERENCES Users(ID_User)
);

GO

CREATE TABLE Images (
    ID_Image INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT NOT NULL,
    ImageURL VARCHAR(200) NOT NULL,
    DescriptionIMG VARCHAR(200),
    CONSTRAINT FK_Images_Products FOREIGN KEY (ProductID) REFERENCES Products(ID_Product) ON DELETE CASCADE
);
GO

INSERT INTO Users (LastName, FirstName, MiddleName, Email, PasswordHash, Phone, RoleUs)
VALUES 
('Иванов', 'Иван', 'Иванович', 'ivanov@mail.ru', 'hash123', '89000000001', 'Клиент'),
('Петров', 'Пётр', 'Сергеевич', 'petrov@mail.ru', 'hash456', '89000000002', 'Менеджер'),
('Сидорова', 'Анна', 'Павловна', 'sidorova@mail.ru', 'hash789', '89000000003', 'Администратор');
GO

INSERT INTO UserProfiles (UserID, AddressPr, CityPr, PostalCodePr, BirthDate, Gender, Preferences)
VALUES
(1, 'ул. Ленина, д.10', 'Москва', '101000', '1995-05-12', 'Женский', 'Уход за кожей'),
(2, 'ул. Гагарина, д.15', 'Санкт-Петербург', '190000', '1988-11-03', 'Мужской', 'Мужская косметика');
GO

INSERT INTO Categories (NameCa, DescriptionCa)
VALUES
('Уход за кожей', 'Кремы, маски, лосьоны'),
('Макияж', 'Тональные основы, тушь, помада'),
('Уход за волосами', 'Шампуни, кондиционеры, маски');
GO

INSERT INTO Products (CategoryID, NamePr, DescriptionPr, BrandPr, Price, StockQuantity)
VALUES
(1, 'Крем увлажняющий', 'Подходит для сухой кожи', 'Natura', 450.00, 50),
(2, 'Помада красная', 'Стойкая, насыщенный цвет', 'Luxe', 799.00, 30),
(3, 'Шампунь питательный', 'Для повреждённых волос', 'HairCare', 350.00, 40);
GO

INSERT INTO PromoCodes (Code, DiscountPercent, MaxUsage, ExpiryDate)
VALUES
('SALE10', 10, 100, '2025-12-31'),
('WELCOME5', 5, 50, '2025-06-01');
GO

INSERT INTO Orders (UserID, TotalAmount, StatusOr, DeliveryAddress, PromoID)
VALUES
(1, 1124.10, 'В обработке', 'Москва, ул. Ленина, д.10', 1),
(2, 350.00, 'Собирается', 'Санкт-Петербург, ул. Гагарина, д.15', NULL);
GO

INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Price)
VALUES
(1, 1, 1, 450.00),
(1, 2, 1, 799.00),
(2, 3, 1, 350.00);
GO

INSERT INTO Reviews (ProductID, UserID, Rating, CommentRe)
VALUES
(1, 1, 5, 'Очень понравился крем, кожа стала мягкой!'),
(2, 2, 4, 'Цвет красивый, но смывается не сразу.');
GO

INSERT INTO Images (ProductID, ImageURL, DescriptionIMG)
VALUES
(1, 'images/cream1.jpg', 'Крем увлажняющий - вид спереди'),
(1, 'images/cream2.jpg', 'Крем увлажняющий - упаковка'),
(2, 'images/lipstick.jpg', 'Красная помада'),
(3, 'images/shampoo.jpg', 'Шампунь питательный');
GO
-- пока просто добавила для заполнения несуществующие картинки --

-- Представления --

-- все заказы с пользователями и промокодами
CREATE OR ALTER VIEW vw_UserOrders AS
SELECT 
    o.ID_Order AS [Номер заказа],
    (u.LastName + ' ' + u.FirstName + ISNULL(' ' + u.MiddleName, '')) AS [ФИО клиента],
    u.Email AS [Электронная почта],
    o.OrderDate AS [Дата заказа],
    o.TotalAmount AS [Сумма заказа],
    o.StatusOr AS [Статус заказа],
    ISNULL(p.Code, '-') AS [Промокод]
FROM Orders o
INNER JOIN Users u ON o.UserID = u.ID_User
LEFT JOIN PromoCodes p ON o.PromoID = p.ID_Promo;
GO

-- отзывы с именами пользователей и названиями товаров
CREATE OR ALTER VIEW vw_ProductReviews AS
SELECT 
    r.ID_Review AS [Номер отзыва],
    (u.FirstName + ' ' + LEFT(u.LastName,1) + '.') AS [Автор отзыва],
    pr.NamePr AS [Товар],
    r.Rating AS [Оценка],
    ISNULL(r.CommentRe, '-') AS [Комментарий], 
    r.CreatedAt AS [Дата отзыва]
FROM Reviews r
INNER JOIN Users u ON r.UserID = u.ID_User
INNER JOIN Products pr ON r.ProductID = pr.ID_Product;
GO


-- остатки товаров по категориям
CREATE OR ALTER VIEW vw_ProductStock AS
SELECT 
    p.ID_Product AS [Код товара],
    p.NamePr AS [Название товара],
    p.StockQuantity AS [На складе],
    ISNULL(SUM(od.Quantity), 0) AS [Продано],
    (p.StockQuantity - ISNULL(SUM(od.Quantity),0)) AS [Доступно]
FROM Products p
LEFT JOIN OrderDetails od ON p.ID_Product = od.ProductID
GROUP BY p.ID_Product, p.NamePr, p.StockQuantity;
GO

CREATE OR ALTER VIEW vw_SalesByCategory AS
SELECT 
    c.NameCa AS [Категория],
    SUM(od.Quantity * od.Price) AS [Общая сумма продаж]
FROM Categories c
INNER JOIN Products p ON c.ID_Category = p.CategoryID
INNER JOIN OrderDetails od ON p.ID_Product = od.ProductID
GROUP BY c.NameCa;
GO

SELECT * FROM vw_SalesByCategory;
SELECT * FROM vw_UserOrders;
SELECT * FROM vw_ProductReviews;
SELECT * FROM vw_ProductStock;
GO

-- Триггеры --
DECLARE @TableName NVARCHAR(128),
        @SQL NVARCHAR(MAX),
        @PKColumn NVARCHAR(128);

DECLARE table_cursor CURSOR FOR
SELECT name 
FROM sys.tables 
WHERE name NOT IN ('AuditLogs');

OPEN table_cursor
FETCH NEXT FROM table_cursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT TOP 1 @PKColumn = c.name
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    WHERE i.object_id = OBJECT_ID(@TableName)
      AND i.is_primary_key = 1;

    IF @PKColumn IS NOT NULL
    BEGIN
        SET @SQL = '
        CREATE OR ALTER TRIGGER trg_' + @TableName + '_Audit
        ON ' + QUOTENAME(@TableName) + '
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;

            -- INSERT
            IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
            BEGIN
                INSERT INTO AuditLogs (TableName, ActionType, UserName, NewData)
                SELECT 
                    ''' + @TableName + ''', 
                    ''INSERT'', 
                    SYSTEM_USER,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                FROM inserted i;
            END

            -- UPDATE
            IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
            BEGIN
                INSERT INTO AuditLogs (TableName, ActionType, UserName, OldData, NewData)
                SELECT 
                    ''' + @TableName + ''', 
                    ''UPDATE'', 
                    SYSTEM_USER,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                FROM inserted i
                JOIN deleted d ON i.' + QUOTENAME(@PKColumn) + ' = d.' + QUOTENAME(@PKColumn) + ';
            END

            -- DELETE
            IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
            BEGIN
                INSERT INTO AuditLogs (TableName, ActionType, UserName, OldData)
                SELECT 
                    ''' + @TableName + ''', 
                    ''DELETE'', 
                    SYSTEM_USER,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                FROM deleted d;
            END
        END;
        ';

        PRINT @SQL;   
        EXEC sp_executesql @SQL; 
    END

    FETCH NEXT FROM table_cursor INTO @TableName
END

CLOSE table_cursor
DEALLOCATE table_cursor;
GO

SELECT 
    name AS TriggerName,
    parent_class_desc,
    OBJECT_NAME(parent_id) AS TableName,
    create_date,
    modify_date,
    is_disabled
FROM sys.triggers
WHERE parent_class_desc = 'OBJECT_OR_COLUMN';
GO

-- добавила еще валидацию
ALTER TABLE Users
ADD CONSTRAINT CK_Users_Phone CHECK (Phone LIKE '+%' OR Phone NOT LIKE '%[^0-9]%');
GO

ALTER TABLE UserProfiles
ADD CONSTRAINT CK_UserProfiles_PostalCode CHECK (PostalCodePr NOT LIKE '%[^0-9A-Za-z]%');
GO

ALTER TABLE Reviews
ADD CONSTRAINT UQ_Reviews_User_Product UNIQUE (UserID, ProductID);
GO

ALTER TABLE OrderDetails
ADD CONSTRAINT UQ_OrderDetails_Order_Product UNIQUE (OrderID, ProductID);
GO

-- тут хранимые процедуры
CREATE OR ALTER PROCEDURE sp_CreateOrder
    @UserID INT,
    @DeliveryAddress VARCHAR(200),
    @PromoCode VARCHAR(50) = NULL
AS
BEGIN
    DECLARE @OrderID INT, @PromoID INT = NULL, @Discount INT = 0;

    BEGIN TRY
        BEGIN TRAN;

        IF @PromoCode IS NOT NULL
        BEGIN
            SELECT TOP 1 @PromoID = ID_Promo, @Discount = DiscountPercent
            FROM PromoCodes
            WHERE Code = @PromoCode AND IsActive = 1 AND ExpiryDate >= GETDATE();
        END;

        INSERT INTO Orders (UserID, DeliveryAddress, PromoID, StatusOr, TotalAmount)
        VALUES (@UserID, @DeliveryAddress, @PromoID, 'В обработке', 0);

        SET @OrderID = SCOPE_IDENTITY();

        COMMIT;
        SELECT @OrderID AS NewOrderID;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        RAISERROR('Ошибка при создании заказа', 16, 1);
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_AddUserPoints
    @UserID INT,
    @Points INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;
        UPDATE Users
        SET StatusUs = CASE 
                          WHEN StatusUs = 'Активен' THEN 'Активен'
                          ELSE 'Активен'
                       END
        WHERE ID_User = @UserID;

        INSERT INTO AuditLogs (UserID, UserName, TableName, ActionType, NewData)
        VALUES (@UserID, SYSTEM_USER, 'Users', 'ADD_POINTS', '{"PointsAdded":'+CAST(@Points AS VARCHAR)+'}');
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        RAISERROR('Ошибка при начислении бонусов', 16, 1);
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_ApplyPromoCode
    @OrderID INT,
    @PromoCode VARCHAR(50)
AS
BEGIN
    DECLARE @Discount INT, @PromoID INT;

    SELECT @PromoID = ID_Promo, @Discount = DiscountPercent
    FROM PromoCodes
    WHERE Code = @PromoCode AND IsActive = 1 AND ExpiryDate >= GETDATE();

    IF @PromoID IS NULL
    BEGIN
        RAISERROR('Промокод недействителен или истёк', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;
        UPDATE Orders
        SET PromoID = @PromoID,
            TotalAmount = TotalAmount * (1 - @Discount / 100.0)
        WHERE ID_Order = @OrderID;
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        RAISERROR('Ошибка применения промокода', 16, 1);
    END CATCH
END;
GO

CREATE ROLE AdminUs;
CREATE ROLE Manager;
CREATE ROLE Client;

GRANT SELECT, INSERT, UPDATE, DELETE ON Users TO AdminUs;
GRANT SELECT, INSERT, UPDATE, DELETE ON Products TO AdminUs;
GRANT SELECT, INSERT, UPDATE, DELETE ON Orders TO AdminUs;

GRANT SELECT, INSERT, UPDATE ON Products TO Manager;
GRANT SELECT, UPDATE ON Orders TO Manager;

GRANT SELECT ON Products TO Client;
GRANT SELECT, INSERT ON Orders TO Client;

-- бэкапчик
--BACKUP DATABASE CosmeticsShopDB
--TO DISK = 'C:\Backups\CosmeticsShopDB.bak'
--WITH INIT;
--GO 
--
--RESTORE DATABASE CosmeticsShopDB_Test
--FROM DISK = 'C:\Backups\CosmeticsShopDB.bak'
--WITH MOVE 'CosmeticsShopDB' TO 'C:\SQLData\CosmeticsShopDB_Test.mdf',
--     MOVE 'CosmeticsShopDB_log' TO 'C:\SQLData\CosmeticsShopDB_Test.ldf',
--     REPLACE;
--GO

--отредачила процедуру
ALTER TABLE Users
ADD Points INT NOT NULL DEFAULT 0;
GO

CREATE OR ALTER PROCEDURE sp_AddUserPoints
    @UserID INT,
    @Points INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Users
        SET Points = Points + @Points
        WHERE ID_User = @UserID;

        INSERT INTO AuditLogs (UserID, UserName, TableName, ActionType, NewData)
        SELECT 
            u.ID_User,
            u.FirstName + ' ' + u.LastName,
            'Users',
            'UPDATE (AddPoints)',
            (SELECT u.Points AS CurrentPoints FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
        FROM Users u
        WHERE u.ID_User = @UserID;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- проверка процедур
EXEC sp_AddUserPoints @UserID = 1, @Points = 50;
GO

SELECT ID_User, FirstName, LastName, Points FROM Users WHERE ID_User = 1;
GO

SELECT * FROM AuditLogs WHERE UserID = 1 ORDER BY ID_Log DESC;
GO

-- заказ без промокода
EXEC sp_CreateOrder 
    @UserID = 1, 
    @DeliveryAddress = N'Москва, ул. Ленина, 10';
GO

-- заказ с промокодом
EXEC sp_CreateOrder 
    @UserID = 2, 
    @DeliveryAddress = N'Санкт-Петербург, Невский проспект, 25', 
    @PromoCode = 'DISCOUNT10';
GO

INSERT INTO Categories (NameCa, DescriptionCa)
VALUES 
('Парфюмерия', 'Духи, туалетная вода, спрей'),
('Уход за кожей', 'Крема, сыворотки, маски'),
('Уход за телом', 'Гели для душа, скрабы, лосьоны'),
('Мужская косметика', 'Средства для бритья, уход за бородой'),
('Люкс косметика', 'Премиальные бренды и лимитированные коллекции'),
('Все категории', 'Премиальные бренды и лимитированные коллекции');
GO

select * from orders;
GO

UPDATE Users
SET RoleUs = 'Администратор' where ID_User = 23;
GO

UPDATE Users
SET StatusUs = 'Заблокирован' where StatusUs = 'string';
GO

INSERT INTO Images (ProductID, ImageURL, DescriptionIMG)
VALUES
(1, 'images/cream1.jpg', 'Крем увлажняющий - вид спереди'),
(1, 'images/cream2.jpg', 'Крем увлажняющий - упаковка'),
(2, 'images/lipstick.jpg', 'Красная помада'),
(3, 'images/shampoo.jpg', 'Шампунь питательный');
GO

UPDATE Images
SET ImageURL = 'https://i.postimg.cc/bNhVfBpB/image.png' where ProductID = 1;
GO

UPDATE Images
SET ImageURL = 'https://i.postimg.cc/j2cxK3kx/image.png' where ProductID = 2;
GO

UPDATE Images
SET ImageURL = 'https://i.postimg.cc/DwhnMTjZ/image.png' where ProductID = 3;
GO

Update Users
SET RoleUs = 'Менеджер' where ID_User = 24;
GO

Update Users
SET RoleUs = 'Менеджер' where Email = 'katelol129ioi@gmail.com';
GO

ALTER TABLE Users 
ADD PasswordResetToken VARCHAR(255) NULL,
    PasswordResetTokenExpiry DATETIME NULL;
	go
CREATE INDEX IX_Users_PasswordResetToken ON Users (PasswordResetToken);
go
CREATE INDEX IX_Users_Email_Token ON Users (Email, PasswordResetToken);
GO
