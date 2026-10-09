-- SQL Server database growth alert (lab setup)
-- Prerequisite: a Database Mail account 'GmailAccount' and profile 'DBProfile' already exist.

USE msdb;
GO
EXEC sysmail_update_account_sp
    @account_name = 'GmailAccount',
    @username = 'your_email@gmail.com',
    @password = '<GMAIL_APP_PASSWORD>',   -- never commit a real password
    @mailserver_name = 'smtp.gmail.com',
    @port = 587,
    @enable_ssl = 1;
GO
EXEC msdb.dbo.sysmail_stop_sp;
EXEC msdb.dbo.sysmail_start_sp;

-- Test email
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'DBProfile',
    @recipients = 'your_email@gmail.com',
    @subject = 'SUCCESS TEST',
    @body = 'Database Mail is now working';
GO

-- Database with growth limits
CREATE DATABASE TestGrowthDB
ON PRIMARY
(
    NAME = TestGrowthDB_Data,
    FILENAME = 'C:\SQLData\TestGrowthDB.mdf',
    SIZE = 500MB, MAXSIZE = 4GB, FILEGROWTH = 100MB
)
LOG ON
(
    NAME = TestGrowthDB_Log,
    FILENAME = 'C:\SQLData\TestGrowthDB.ldf',
    SIZE = 200MB, MAXSIZE = 1GB, FILEGROWTH = 50MB
);
GO

USE TestGrowthDB;
GO
CREATE TABLE GrowthTable (ID INT IDENTITY, BigData CHAR(4000));
INSERT INTO GrowthTable (BigData)
SELECT TOP 1000 REPLICATE('X', 4000)
FROM sys.objects a CROSS JOIN sys.objects b;
GO

-- Agent job: alert at 3.5 GB
USE msdb;
GO
EXEC sp_add_job
    @job_name = 'DB_GROWTH_3_5GB_ALERT',
    @enabled = 1,
    @description = 'Alert when TestGrowthDB reaches 3.5 GB';
GO
EXEC sp_add_jobstep
    @job_name = 'DB_GROWTH_3_5GB_ALERT',
    @step_name = 'Check DB Size',
    @subsystem = 'TSQL',
    @database_name = 'master',
    @command = '
DECLARE @DBSizeMB INT;
SELECT @DBSizeMB = SUM(size) * 8 / 1024
FROM sys.master_files
WHERE database_id = DB_ID(''TestGrowthDB'');
IF @DBSizeMB >= 3584  -- 3.5 GB
BEGIN
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = ''DBProfile'',
        @recipients = ''your_email@gmail.com'',
        @subject = ''ALERT: TestGrowthDB almost FULL'',
        @body = ''TestGrowthDB has reached 3.5 GB. Immediate action required.'';
END';
GO
-- Attach the job to this server so it can run
EXEC sp_add_jobserver @job_name = 'DB_GROWTH_3_5GB_ALERT';
GO

-- Make the database grow to trigger the alert
USE TestGrowthDB;
GO
CREATE TABLE GrowthTest (data CHAR(8000));
INSERT INTO GrowthTest
SELECT TOP 50000 REPLICATE('X', 8000)
FROM sys.objects a CROSS JOIN sys.objects b;
GO
