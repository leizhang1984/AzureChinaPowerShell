USE AdventureWorks2016CTP3
--Review the Data
SELECT COUNT(*) FROM Sales.OrderTracking WHERE TrackingEventID <= 3
--Review the Data
SELECT COUNT(*) FROM Sales.OrderTracking WHERE TrackingEventID > 3


--对本地SQL Server 2016，打开归档功能
EXEC sp_configure 'remote data archive' , '1';
RECONFIGURE;

--对云端Azure SQL Database的用户名和密码，进行加密，加密的密码同SQL Database的密码：
USE Adventureworks2016CTP3;
CREATE MASTER KEY ENCRYPTION BY PASSWORD='Abc@123456'
CREATE DATABASE SCOPED CREDENTIAL AzureDBCred WITH IDENTITY = 'sqladmin', SECRET = 'Abc@123456';

--将本地的SQL Server 2016的归档目标，指向到微软云SQL Database Server(l3cq1dckpd.database.chinacloudapi.cn)
--这个l3cq1dckpd.database.chinacloudapi.cn，是我们在准备工作中，创建的新的服务器
ALTER DATABASE [AdventureWorks2016CTP3] SET REMOTE_DATA_ARCHIVE = ON 
(SERVER = 'l3cq1dckpd.database.chinacloudapi.cn', CREDENTIAL = AzureDBCred);


--Create Function
CREATE FUNCTION dbo.fn_stretchpredicate(@status int) 
RETURNS TABLE WITH SCHEMABINDING AS 
RETURN	SELECT 1 AS is_eligible WHERE @status <= 3; 


--Migrate Some Data to the Cloud
ALTER TABLE Sales.OrderTracking SET (REMOTE_DATA_ARCHIVE = ON (
	MIGRATION_STATE = OUTBOUND,
	FILTER_PREDICATE = dbo.fn_stretchpredicate(TrackingEventId)));


--查看归档数据迁移的进度
SELECT * from sys.dm_db_rda_migration_status


USE AdventureWorks2016CTP3
GO
--显示本地数据行和数据容量
EXEC sp_spaceused 'Sales.OrderTracking', 'true', 'LOCAL_ONLY';
GO

--显示云端Stretch Database的数据行和数据量
EXEC sp_spaceused 'Sales.OrderTracking', 'true', 'REMOTE_ONLY';
GO