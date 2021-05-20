USE webapidb;
GO
INSERT INTO MyData ([Description], [IsEnabled], [TimeStampUtc], [Title]) 
VALUES ("First entry", 1, GETUTCDATE(), "Seed 1");
INSERT INTO MyData ([Description], [IsEnabled], [TimeStampUtc], [Title]) 
VALUES ("Second entry", 1, GETUTCDATE(), "Seed 2");
INSERT INTO MyData ([Description], [IsEnabled], [TimeStampUtc], [Title]) 
VALUES ("Third entry", 0, GETUTCDATE(), "Seed 3");
INSERT INTO MyData ([Description], [IsEnabled], [TimeStampUtc], [Title]) 
VALUES ("Fourth entry", 0, GETUTCDATE(), "Seed 4");
GO
CHECKPOINT
GO
