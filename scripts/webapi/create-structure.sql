CREATE DATABASE webapidb;
GO
USE webapidb;
GO
CREATE TABLE MyData (
    MyDataId     INT            IDENTITY NOT NULL,
    TimeStampUtc DATETIME2 (7)  NOT NULL,
    Title        NVARCHAR (MAX) NULL,
    Description  NVARCHAR (MAX) NULL,
    IsEnabled    BIT            NOT NULL,
    RowVersion   ROWVERSION     NULL,
    CONSTRAINT PK_MyData PRIMARY KEY CLUSTERED (MyDataId ASC)
);
GO