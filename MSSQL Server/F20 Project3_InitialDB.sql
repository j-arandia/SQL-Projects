use master;
GO
Alter database Project3  set single_user with rollback immediate;
GO
DROP Database Project3;
GO 

CREATE DATABASE Project3;
GO

USE Project3;
GO

CREATE TABLE dbo.Departments (
    DepartmentID    INT IDENTITY PRIMARY KEY,
    DepartmentName  NVARCHAR(50),
    DepartmentDesc  NVARCHAR(100) NOT NULL CONSTRAINT DF_DFDeptDesc DEFAULT 'Dept. Description to be determined'
);

CREATE TABLE dbo.Employees (
    EmployeeID        INT IDENTITY PRIMARY KEY,
    DepartmentID      INT CONSTRAINT FK_Employee_Department FOREIGN KEY REFERENCES dbo.Departments ( DepartmentID ),
    ManagerEmployeeID INT CONSTRAINT FK_Employee_Manager FOREIGN KEY REFERENCES dbo.Employees ( EmployeeID ),
    FirstName         NVARCHAR(40),
    LastName          NVARCHAR(50),
    Salary            MONEY CONSTRAINT CK_EmployeeSalary CHECK ( Salary >= 0 ),
    CommissionBonus   MONEY CONSTRAINT CK_EmployeeCommission CHECK ( CommissionBonus >= 0 ),
    FileFolder        NVARCHAR(256) CONSTRAINT DF_FileFolder DEFAULT 'ToBeBuilt'
);

GO
INSERT INTO dbo.Departments ( DepartmentName, DepartmentDesc )
VALUES ( 'Management', 'Executive Management' ),
       ( 'HR', 'Human Resources' ),
       ( 'DatabaseMgmt', 'Database Management'),
       ( 'Support', 'Product Support' ),
       ( 'Software', 'Software Sales' ),
       ( 'Peripheral', 'Peripheral Sales' );
GO

SET IDENTITY_INSERT dbo.Employees ON;
GO

INSERT INTO dbo.Employees ( EmployeeID, DepartmentID, ManagerEmployeeID, FirstName, LastName, Salary, CommissionBonus, FileFolder )
VALUES ( 1, 1, NULL, 'Sarah', 'Campbell', 76000, NULL, 'SarahCampbell' ),
       ( 2, 3, 1, 'James', 'Donoghue',    66000, NULL, 'JamesDonoghue'),
       ( 3, 1, 1, 'Hank', 'Brady',        74000, NULL, 'HankBrady'),
       ( 4, 2, 1, 'Samantha', 'Jones',    71000, NULL, 'SamanthaJones'),
       ( 5, 3, 4, 'Fred', 'Judd',         42000, 4000, 'FredJudd'),
       ( 6, 3, NULL, 'Hannah', 'Grant',   65000, 3000, 'HannahGrant'),
       ( 7, 3, 4, 'Dhruv', 'Patel',       64000, 2000, 'DhruvPatel'),
       ( 8, 5, 3, 'Ash', 'Mansfield',     52000, 5000, 'AshMansfield'),
       ( 9, 5, 3, 'Dash', 'Summerfield',  44000, 1000, 'DashSummerfield');
GO
SET IDENTITY_INSERT dbo.Employees OFF;
GO

CREATE FUNCTION dbo.GetEmployeeID (
    -- Parameter datatype and scale match their targets
    @FirstName NVARCHAR(40),
    @LastName  NVARCHAR(50) )
RETURNS INT
AS
BEGIN;


    DECLARE @ID INT;

    SELECT @ID = EmployeeID
    FROM dbo.Employees
    WHERE FirstName = @FirstName
          AND LastName = @LastName;

    -- Note that it is not necessary to initialize @ID or test for NULL, 
    -- NULL is the default, so if it is not overwritten by the select statement
    -- above, NULL will be returned.
    RETURN @ID;
END;
GO


/* REQUIREMENT 1*/
CREATE PROCEDURE dbo.Record(
	@DepartmentName NVARCHAR(50), 
	@DepartmentDesc NVARCHAR(100) 
	)
	AS
	BEGIN;
	SELECT @DepartmentName = DepartmentName,
	@DepartmentDesc = DepartmentDesc
	FROM dbo.Departments
	WHERE DepartmentName = @DepartmentName AND
	DepartmentDesc = @DepartmentDesc;
	END;
	GO


/* REQUIREMENT 2*/
EXECUTE dbo.Record 'SQA', 'Software Testing and Quality Assurance';
EXECUTE dbo.Record 'Development', 'System Design and Development';
EXECUTE dbo.Record 'Deployment', 'Deployment and Production Support';
EXECUTE dbo.Record 'TextSupport', 'Online Technical Support';


/* REQUIREMENT 3*/
CREATE FUNCTION dbo.GetDepartmentID(
@DepartmentName NVARCHAR(50)
)
RETURNS INT
AS
BEGIN;
DECLARE @DepartmentID INT;

SELECT @DepartmentID = DepartmentID
FROM dbo.Departments
WHERE DepartmentName = @DepartmentName;

RETURN @DepartmentID;
END;
GO


/* REQUIREMENT 4*/
CREATE PROCEDURE dbo.CreateRecord(
@DepartmentName NVARCHAR(50), 
@FirstName NVARCHAR(40),
@LastName NVARCHAR(50),
@Salary  MONEY = 42000,
@FileFolder NVARCHAR(256),
@ManagerFirstName NVARCHAR(40),
@ManagerLastName NVARCHAR(50),
@CommissionBonus MONEY = 32000
)
AS
BEGIN;

INSERT INTO dbo.Employees (DepartmentID, FirstName, LastName, FileFolder, ManagerEmployeeID )
VALUES(dbo.GetDepartmentID(@DepartmentName), @FirstName, @LastName, @FileFolder,dbo.GetEmployeeID(@ManagerFirstName, @ManagerLastName));

END;
GO

/* REQUIREMENT 5*/
CREATE FUNCTION dbo.GetData(@Salary MONEY)
RETURNS TABLE
AS
RETURN
(SELECT e.FirstName, e.LastName, e.Salary,e.CommissionBonus,
d.DepartmentName, d.DepartmentDesc
FROM Employees e 
JOIN Departments d
ON Salary >= 0);
GO


/* REQUIREMENT 6*/
WITH RankEmployeesByCommissionBonus AS(
SELECT 
d.DepartmentName,
e.FirstName,
e.LastName,
AVG(e.CommissionBonus) AS CommissionBonus,
SUM(e.Salary + e.CommissionBonus) AS TotalCompensation
FROM Employees e
JOIN Departments d
ON e.DepartmentID = d.DepartmentID
GROUP BY d.DepartmentName, e.FirstName, e.LastName
)
SELECT
DepartmentName,
FirstName,
LastName,
CommissionBonus,
TotalCompensation,
RANK() OVER(PARTITION BY DepartmentName ORDER BY CommissionBonus DESC) AS EmpRank
FROM RankEmployeesByCommissionBonus
ORDER BY DepartmentName;

/* REQUIREMENT 7*/

WITH cteEmployeesByManager(EmployeeID, DepartmentID, ManagerEmployee, FirstName, LastName, FileFolder ) AS
(
SELECT EmployeeID,DepartmentID, ManagerEmployeeID, FirstName, LastName, FileFolder
	FROM Employees
	WHERE EmployeeID = ManagerEmployeeID
UNION ALL
SELECT e.EmployeeID, e.DepartmentID, e.ManagerEmployeeID, e.FirstName, e.LastName, r.FileFolder
	FROM Employees e 
	JOIN cteEmployeesByManager r
		ON e.ManagerEmployeeID = r.EmployeeID
)
SELECT 
	FirstName AS EmployeeFirstName,
	LastName AS EmployeeLastName,
	DepartmentID,
	(SELECT FirstName FROM Employees WHERE EmployeeID = ManagerEmployeeID ) AS ManagerFirstName,
	(SELECT LastName FROM Employees WHERE EmployeeID = ManagerEmployeeID ) AS ManagerLastName,
	FileFolder + '\' + (SELECT FileFolder FROM Employees WHERE EmployeeID = ManagerEmployeeID ) AS FilePath

FROM cteEmployeesByManager
ORDER BY DepartmentID;

