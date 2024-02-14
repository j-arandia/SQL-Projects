-- Marking also included "Did the full script run without changes?", Were Requirements followed - was the Test SQL included as requested?

USE Proj3;
GO

/* REQUIREMENT 1*/

CREATE PROCEDURE dbo.Department_Insert (
  -- Parameter datatype and scale match their targets
        @DepartmentName  NVARCHAR(50),
        @DepartmentDesc  NVARCHAR(100)
    )
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    -- Inserts all records from parameter
    INSERT INTO dbo.Departments (
        DepartmentName,
        DepartmentDesc )
        VALUES ( @DepartmentName  , @DepartmentDesc );
END;
GO


/* REQUIREMENT 2 */



-- Inserts using the procedure created in step 1
EXECUTE dbo.Department_Insert  @DepartmentName = 'SQA', @DepartmentDesc  = 'Software Testing and Quality Assurance' ;
EXECUTE dbo.Department_Insert  @DepartmentName =  'Development', @DepartmentDesc = 'Systems Design and development';
EXECUTE dbo.Department_Insert  @DepartmentName =  'Deployment', @DepartmentDesc = 'Deployment and Production Support';
EXECUTE dbo.Department_Insert  @DepartmentName =  'TechSupport', @DepartmentDesc = 'Online Technical Support';
GO
Print ' Should Show Newly added SQA, Development, Deployment, and TechSupport departmeents in Departments table:';
SELECT * FROM DEPARTMENTS;

GO /* REQUIREMENT 3 */
CREATE FUNCTION dbo.GetDepartmentID (	---Scalar function
    -- Parameter datatype and scale match their targets
    @DepartmentName NVARCHAR(50)
     )
RETURNS INT
AS
BEGIN;

    DECLARE @ID INT;

    SELECT @ID = DepartmentID
    FROM dbo.Departments
    WHERE DepartmentName = @DepartmentName;

    -- Note that it is not necessary to initialize @ID or test for NULL, 
    -- NULL is the default, so if it is not overwritten by the select statement
    -- above, NULL will be returned.
    RETURN @ID;
END;
GO
IF  dbo.GetDepartmentID ('Deployment') IS NULL
  PRINT 'CAn not find New Deployment Dept using exec Get DepartmentID function';
GO
PRINT  'Employees before additions: should be 9 Sarah to Dash'
Select * from Employees; 
GO
/* REQUIREMENT 4 */
CREATE PROCEDURE dbo.Employee_Insert (
   -- Parameter datatype and scale match their targets ??
    @DepartmentName    NVARCHAR(50),
    @EmployeeFirstName NVARCHAR(40),
    @EmployeeLastName  NVARCHAR(50),
    @FileFolder	       NVARCHAR (256),
    @ManagerFirstName  NVARCHAR(40),
    @ManagerLastName   NVARCHAR(50),
    -- Optional parameter Salary
    @Salary            MONEY = 44000,
    -- Optional parameter CommissionBonus
    @CommissionBonus   MONEY = 2500)
AS
BEGIN;
    SET NOCOUNT ON;   -- XACT_ABORT will cause the transaction to roll back on error. TRY-CATCH
    -- can also accomplish this but is more complicated whereas XACT_Abort is a best practise.
    SET XACT_ABORT ON;
	
    DECLARE @DepartmentID INT;
    -- Call function to get DepartmentID
    SET @DepartmentID = dbo.GetDepartmentID(@DepartmentName);
    
    DECLARE @ManagerID INT;
    -- Call function to get manager ID
    SET @ManagerID = dbo.GetEmployeeID(@ManagerFirstName, @ManagerLastName);

    -- Begin transaction to allow rollback in case of error (XACT_ABORT alone
    -- is not sufficient)
    BEGIN TRANSACTION;
      IF @DepartmentID IS NULL
      BEGIN;
        -- Test if the function failed to find a Dept, if so, create a new one
        INSERT INTO dbo.Departments( DepartmentName, DepartmentDesc )
        VALUES (  @DepartmentName , CAST ((@DepartmentName + 'Department Description') AS NVARCHAR(256)) );

        -- Capture the newly created dept ID
        SET @DepartmentID = SCOPE_IDENTITY();
      END;

      IF @ManagerID IS NULL
      BEGIN;
        -- Test if the function failed to find a manager, if so, create a new one
        INSERT INTO dbo.Employees ( FirstName, LastName, DepartmentID, Salary , filefolder)
        VALUES ( @ManagerFirstName, @ManagerLastName, @DepartmentID, 44000,  (@ManagerFirstName + @ManagerLastName ) );
        -- Extra bonus points if students concatenate First&LastName to make Filefolder vs leaving as the default "toBeBuilt"
        -- Capture the newly created manager ID
        SET @ManagerID = SCOPE_IDENTITY();
      END;

    -- Insert new employee
      INSERT INTO dbo.Employees (
        DepartmentID,
        FirstName,        
        LastName,
        Salary,
        ManagerEmployeeID,
	Filefolder,
	CommissionBonus )
      VALUES (
        @DepartmentID,
        @EmployeeFirstName,
        @EmployeeLastName,
        @Salary,
        @ManagerID,
	@FileFolder,
	@CommissionBonus );

    -- Commit the transaction if all preceeding steps were successful (ensured
    -- by XACT_ABORT as the best practise, or alternately using TRY-CATCH).
    COMMIT TRANSACTION;
END;
GO
--Test Dept Not exist and mgr exists
Execute dbo.Employee_Insert @DepartmentName = 'Infrastructure', @EmployeeFirstName = 'NewFirstNameNewInfraDepMgrJamesDonoghue', @EmployeeLastName='NewLastNameInfraDeptMgrJamesDonoghue' , 
                            @Filefolder = 'NewNameInfraJamesDonoghueExists', @ManagerFirstName = 'James', @ManagerLastName = 'Donoghue';
--Test Dept exists and mgr does NOT exist
Execute dbo.Employee_Insert @DepartmentName = 'DatabaseMgmt', @EmployeeFirstName = 'NewFirstNameWherewolfWaldoDBaseDepMgrBillGates', @EmployeeLastName='NewLastNameWherewolfWaldoDBaseDepMgrBillGates' , 
                            @Filefolder = 'NewNameDBaseBillGatesAdded', @ManagerFirstName = 'Bill', @ManagerLastName = 'Gates', @Salary = 43000, @CommissionBonus = 2000;
-- Should likely also test Both Dept does not exist and MGR does not exist (or just check Dept & MGR search logic - as above -  is NOT nested... )
GO
Select * from Departments;
Select * from Employees;
GO
-- Requirement 5 Table Valued Function
CREATE FUNCTION dbo.GetSalariedEmpDepts (
    @Salary Money
)
RETURNS @retSalariedEmpDepts TABLE (
        -- Parameter datatype and scale match their targets ?
        DepartmentName  NVARCHAR(50),
        DepartmentDesc  NVARCHAR(100),
	FirstName       NVARCHAR(40),
        LastName        NVARCHAR(50),
        Salary          MONEY,
        CommissionBonus MONEY,
        FileFolder      NVARCHAR(256) 
    
)
AS
BEGIN    
    --IF @Salary < 0 or @Salary is NULL
	--   PRINT 'Salary not >= 0';
    -- Without this IF statement 
    --  ...then this SQL executes ... VS  NOT executing even though no data might be returned anyway...
    IF @Salary >= 0
	BEGIN
    INSERT INTO @retSalariedEmpDepts
	SELECT	DepartmentName,
        DepartmentDesc,
	FirstName,
        Lastname,
	Salary,
	CommissionBonus,
        FileFolder
	   FROM Departments d
		INNER JOIN Employees e
        ON d.DepartmentID = e.DepartmentID
		WHERE Salary > @Salary;
    END

    RETURN;
END;
GO
Print 'Test Getsalaries with NULL:';
Select *, 'GetSalariedEmpDept TVF with Null Invalid Recs ' AS 'Should Be No Records From GetSalariedEmpDEpt TVF with Null Parameter'  from dbo.GetSalariedEmpDepts(NULL);
Print 'Test Getsalaries with -100:';
Select *, 'GetSalariedEmpDept TVF with -100 Invalid Recs ' AS 'Should Be No Records From GetSalariedEmpDEpt TVF with -100 Parameter' from dbo.GetSalariedEmpDepts(-100);
Print 'Test Getsalaries with 44000: should be 7 rows ... NOT 11 if used >=';
Select *, 'GetSalariedEmpDept TVF with 44000 Should be 7 Recs ' AS 'Should Be 7 Records From GetSalariedEmpDEpt TVF with 44000 Parameter' from dbo.GetSalariedEmpDepts(44000);
GO 
Print 'Test Req 6 Windows Function: expect 12 rows with specific windows values';
-- Requirement 6 Windows Function 
SELECT FirstName,
       LastName,
       CommissionBonus,
       --  CommissionBonus rank by department. Each new department creates a new window,
       -- so department is the partition. Employees are ranked by descending 
       -- Commission, so that is the order.
	   DepartmentID,
	   Salary,     -- Salary just added to help determine correct results (not asked for in Requirements!)
	   (ISNULL(CommissionBonus, 0) + Salary) AS 'Total Compensation',
      -- Extra Bonus marks if checked bonus was NULL and use 0 instead!! Otherwise new Mgrs get NULL TotalCompensation
	   AVG(CommissionBonus) OVER ( PARTITION BY DepartmentID  ) AS CommissionDeptAverage,
	   RANK() OVER ( PARTITION BY DepartmentID ORDER BY CommissionBonus DESC ) AS CommissionRank,
       -- Next highest above employee info (name and salary). Should use LAG to get
       -- data from the record prior to the current record.
       LAG(FirstName) OVER ( PARTITION BY DepartmentID ORDER BY CommissionBonus DESC ) AS NextHighestFirstName,
       LAG(LastName) OVER ( PARTITION BY DepartmentID ORDER BY CommissionBonus DESC ) AS NextHighestLastName,
       LAG(CommissionBonus) OVER ( PARTITION BY DepartmentID ORDER BY CommissionBonus DESC ) AS NextHighestComission
FROM dbo.Employees;
GO
/* Requrement 6 even better solution from Lisa :
SELECT
	d.DepartmentName AS 'Department Name',
	e.FirstName AS 'First Name',
	e.LastName AS 'Last Name',
	RANK () OVER ( PARTITION BY d.DepartmentName ORDER BY e.CommissionBonus DESC ) AS 'Bonus Rank',
	e.CommissionBonus AS Bonus,
	AVG ( e.CommissionBonus ) OVER ( PARTITION BY d.DepartmentName ) AS 'Avg. Dept. Bonus',
	(ISNULL(e.CommissionBonus, 0) + e.Salary) AS 'Total Compensation',
	LAG ( e.FirstName, 1 ) OVER ( PARTITION BY d.DepartmentName ORDER BY e.CommissionBonus DESC ) AS 'Next Highest First Name',
	LAG ( e.LastName, 1 ) OVER ( PARTITION BY d.DepartmentName ORDER BY e.CommissionBonus DESC ) AS 'Next Highest Last Name',
	LAG ( e.CommissionBonus, 1 ) OVER ( PARTITION BY d.DepartmentName ORDER BY e.CommissionBonus DESC ) AS 'Next Highest Bonus'
FROM dbo.Employees e
JOIN dbo.Departments d
	ON e.DepartmentID = d.DepartmentID
GO
*/
/* REQUIREMENT 7 */
WITH EmployeeTree AS (
    
    -- Anchor member will have no manager (ManagerEmployeeID IS NULL). We can
    -- return NULL for the manager's name for this employee.
    SELECT e.EmployeeID,           
           e.FirstName,
           e.LastName,
           e.DepartmentID,
		   e.filefolder,
           CAST(NULL AS NVARCHAR(40)) AS ManagerFirstName,
           CAST(NULL AS NVARCHAR(50)) AS ManagerLastName,
	   e.filefolder AS "EmployeeManagerRecursiveFilePath"
           --start with 1st folder AS FilePath -- With no manager, this employee's filepath only incl their folder.
    FROM dbo.Employees e    
    WHERE ManagerEmployeeID IS NULL
    
    UNION ALL
    
    -- Recursive member joins the employee table to the CTE. Records from the
    -- Employees table are joined to their managers that have already been added
    -- to the CTE.
    SELECT e.EmployeeID,
           e.FirstName,
           e.LastName,
           e.DepartmentID,
		   e.FileFolder,
           m.FirstName AS ManagerFirstName,
           m.LastName AS ManagerLastName,
           CAST((m.EmployeeManagerRecursiveFilePath + '\' + e.FileFolder ) AS NVARCHAR(256)) AS "EmployeeManagerRecursiveFilePath" 
		   -- Add file folder  level
    FROM dbo.Employees e
    JOIN EmployeeTree m
        ON e.ManagerEmployeeID = m.EmployeeID )
SELECT FirstName,
       Lastname,
       DepartmentID,
       ManagerFirstName,
       ManagerLastName,
       EmployeeManagerRecursiveFilePath
FROM EmployeeTree;
GO