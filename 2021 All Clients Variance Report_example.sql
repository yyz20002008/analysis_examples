/*
1. use Max mmdmyearmonth
2. enrollment
3. use centralized client db
*/

Declare @Year as varchar(25) --= '2021' --Intervention Month
Declare @MMDMMonth as varchar(25)-- = '03' --Intervention Month
DECLARE @MonthFlag INT


Declare @clID INT
,		@contract varchar(25)
,		@sqlstring nvarchar(max) = ''
,		@sqlstring2 nvarchar(max) = ''
,		@sqlstringDB1 nvarchar(max) = ''
,		@sqlstringDB2 nvarchar(max) = ''
,		@strWHERE_Condition		VARCHAR(2000)  = ''
,		@SQL_TotalPopulation NVARCHAR(MAX)=''
Declare @MAX_AnalysisID VARCHAR(8) 
		,@MAX_MMDMYearMonth as VARCHAR(50)
		,@FirstDayOfMonth DATE
		,@LastDayOfMonth  DATE

Declare 
              @ServerDB varchar (500),
			  @CDDB varchar (500),
              @ClientName varchar(500),
			  @LOB varchar (500),
              @ClientID varchar(500),
			  @LinkedServer VARCHAR(MAX)

DECLARE @MMDMYrMo AS  VARCHAR(50) ,
	 @svt_id INT,
	 @IDFlag INT,
	 @monthlyAnalysisID AS  VARCHAR(50),
	  @SQLAnalysisID NVARCHAR(4000) ,
	 @MMDMCounts AS  VARCHAR(MAX)
-----------------------------------------------------------------------------     
/******************************
1. Create client look up table
******************************/
if OBJECT_ID('tempdb..#ClientDBs') is not null
drop table #ClientDBs

create table #ClientDBs
( 
			RowID							INT identity (1,1),
			ClientID						INT,
			ClientName						Varchar (500),
			LinkServer						Varchar(500),
			CD_DB							Varchar(500),
			CARA2_Result_DB					Varchar(500),
			LOB								Varchar(20),
			isAnalytics						INT,
			isIntervention					INT,
			isPA							INT,
			isSA							INT,
			isActive						INT
)



INSERT INTO #ClientDBs
		

select C.*,isAnalytics,isIntervention,isPA,isSA,isActive
from (
		SELECT  distinct 
		 Cli_ClientID 
		,  cli_shortname clientname
		,  SUBSTRING(cli_dbname_source,CHARINDEX('[',cli_dbname_source,1),CHARINDEX(']',cli_dbname_source)) LinkServer
		,  SUBSTRING(cli_dbname_source,CHARINDEX('[',cli_dbname_source,2),CHARINDEX(']',cli_dbname_source,CHARINDEX('[',cli_dbname_source,2))) cddb
		,  SUBSTRING(cli_dbname_results,CHARINDEX('[',cli_dbname_results,2),CHARINDEX(']',cli_dbname_results,CHARINDEX('[',cli_dbname_results,2)))  ResultsDB
		,'Medicare' as LOB
		FROM   encrypted a
		join common.dbo.tbclients b
		on a.cli_clientid=b.cli_id

		WHERE  1=1 
		and isHix=0
		AND pg_GroupID = 2
		union
		SELECT  distinct 
		 Cli_ClientID 
		,  cli_shortname clientname
		, SUBSTRING(cli_dbname_source,CHARINDEX('[',cli_dbname_source,1),CHARINDEX(']',cli_dbname_source,1)) LinkServer
		,  SUBSTRING(cli_dbname_source,CHARINDEX('[',cli_dbname_source,2),CHARINDEX(']',cli_dbname_source,CHARINDEX('[',cli_dbname_source,2))) cddb
		,  SUBSTRING(cli_dbname_results,CHARINDEX('[',cli_dbname_results,2),CHARINDEX(']',cli_dbname_results,CHARINDEX('[',cli_dbname_results,2)))  ResultsDB
		,'Medicaid' as LOB
		FROM   encrypted a
		join common.dbo.tbclients b
		on a.cli_clientid=b.cli_id
		WHERE  1=1 AND pg_GroupID = 2
		and isHix=0
		union 
		 SELECT  distinct 
		 Cli_ClientID 
		,  cli_shortname clientname, SUBSTRING(cli_dbname_source,CHARINDEX('[',cli_dbname_source,1),CHARINDEX(']',cli_dbname_source,1)) LinkServer
		,  SUBSTRING(cli_dbname_source,CHARINDEX('[',cli_dbname_source,2),CHARINDEX(']',cli_dbname_source,CHARINDEX('[',cli_dbname_source,2))) cddb
		,  SUBSTRING(cli_dbname_results,CHARINDEX('[',cli_dbname_results,2),CHARINDEX(']',cli_dbname_results,CHARINDEX('[',cli_dbname_results,2)))  ResultsDB
		,'Commercial' as LOB
		FROM   encrypted a
		join common.dbo.tbclients b
		on a.cli_clientid=b.cli_id
		WHERE  1=1 AND pg_GroupID = 2
		and isHix=1
) C
join  encrypted B
	on C.Cli_ClientID=B.clientid and C.LOB=B.LOB
	and B.isactive=1 
	and B.clientid<>123
	and B.clientid<>322


	
Update A
set LinkServer='encrypted'
--select *
from #ClientDBs A
where clientid =140

Update A
set LinkServer='encrypted'
--select *
from #ClientDBs A
where clientid =197
/************************************
2. Create Result Table 
************************************/

if OBJECT_ID('tempdb..#MMDMenrByContrct') is not null
drop table #MMDMenrByContrct
--------------------------------------------------------------------
CREATE TABLE #MMDMenrByContrct
(	
		  ClientID	 INT,
		  ClientName		varchar(50), 
		  [LOB]				varchar(50),   
		  [DataQualityKey]	varchar(100),
		  [Yearmonth]		int,   
		  KeyCount			int
)


/* MMDM  */ 
IF OBJECT_ID('Tempdb..#AllClientMMDMTargets') IS NOT NULL
	DROP TABLE #AllClientMMDMTargets

CREATE TABLE #AllClientMMDMTargets (
ClientID INT,
ClientName VARCHAR(200) ,
LOB VARCHAR(200) ,
An_AnalysisID VARCHAR(20),
MMDMYEARMONTH int,
MonthNumber int,
[Month] Varchar(20),
marketid int,
market  Varchar(200),
ContractNumber Varchar(200),
Intervention Varchar(50),
ResponsibleParty Varchar(50), 
memberid int,
Clientmemberid VARCHAR(200),
Personid VARCHAR(200)
)

IF OBJECT_ID('Tempdb..#AllClientMMDMEnrollment') IS NOT NULL
	DROP TABLE #AllClientMMDMEnrollment

CREATE TABLE #AllClientMMDMEnrollment (
ClientID INT,
ClientName VARCHAR(200) ,
LOB VARCHAR(200) ,
An_AnalysisID VARCHAR(20),
MMDMYEARMONTH int,
Enrollment int
)




SET @IDFlag = 1
WHILE ( @IDFlag <= (SELECT MAX(RowID)  FROM #ClientDBs) )
BEGIN
  
   SELECT  @clientName  = ClientName 
	, @ClID = ClientID 
	, @LOB = LOB
	, @ServerDB = CARA2_Result_DB
	, @LinkedServer =  LinkServer
	--, @svt_id=svt_id
	FROM #ClientDBs
	WHERE RowID = @IDFlag
	PRINT (@IDFlag)
	PRINT (@LinkedServer)
	PRINT (@ServerDB)

	/********************************
	--3.GET REQUIRED ANALYSIS
	********************************/
	--DECLARE @MonthName VARCHAR(20) = DateName( month , DateAdd( month , CONVERT(INT,@MMDMMonth) , -1 ))

	
	
	IF @ClID = 512 and @LOB = 'Medicare'
		SET @SQLAnalysisID = '
		SELECT  @MAX_AnalysisID = max_AnalysisID,@MAX_MMDMYearMonth=max_mmdmyearmonth
		FROM OPENQUERY('+ @LinkedServer + ',''
		SELECT   Top 1  MMDMYearMonth max_mmdmyearmonth,An_AnalysisID max_AnalysisID
		FROM '+@ServerDB+'.encrypted
		WHERE Payor = ''''' + @LOB + ''''' 
		AND PopulationName = ''''Wellcare''''
		order by MMDMYearMonth desc
		'')
		'
	ELSE
	SET @SQLAnalysisID = '
		SELECT  @MAX_AnalysisID = max_AnalysisID,@MAX_MMDMYearMonth=max_mmdmyearmonth
		FROM OPENQUERY('+ @LinkedServer + ',''
		SELECT   Top 1  MMDMYearMonth max_mmdmyearmonth,An_AnalysisID max_AnalysisID
		FROM '+@ServerDB+'.encrypted
		WHERE Payor = ''''' + @LOB + ''''' 
		order by MMDMYearMonth desc
		'')
		'
	

	print (@SQLAnalysisID)
	EXEC  sp_executesql @SQLAnalysisID, N' @MAX_AnalysisID INT OUTPUT,@MAX_MMDMYearMonth INT OUTPUT' 
				, @MAX_AnalysisID = @MAX_AnalysisID OUTPUT 
				, @MAX_MMDMYearMonth = @MAX_MMDMYearMonth OUTPUT 
	print ('MAX MMDMYEARMONTH: '+ @MAX_MMDMYearMonth)
	print ('MAX An_analysisid: '+@MAX_AnalysisID)
	
	--select @MAX_AnalysisID,@MAX_MMDMYearMonth
	/***************************************
	Enrollment
	****************************************/
	SET @SQL_TotalPopulation = '
			INSERT INTO #AllClientMMDMEnrollment
		
			SELECT *
			FROM OPENQUERY('+ @LinkedServer + ',''

			SELECT	 '''''+ CONVERT(VARCHAR, @ClID)+''''', 
					''''' + @ClientName + ''''' AS ClientName, 
					''''' + @LOB + ''''' AS LOB,
					M.An_AnalysisID,
					M.MMDMYEARMONTH,
					count(distinct Memberid) Enrollment
			FROM   ' + @ServerDB + '.encrypted M
			WHERE  1=1 
				AND	an_AnalysisID =  '+@MAX_AnalysisID+'
				AND Payor = '''''+@LOB+'''''
				and enrollmentstatus like ''''%Currently%''''
			Group by M.An_AnalysisID,
					M.MMDMYEARMONTH
			'') A
		  '

	PRINT (@SQL_TotalPopulation)
	EXEC SP_EXECUTESQL @SQL_TotalPopulation

	/********************************
	--4.GET REQUIRED MMDMYEARMONTH ASSOCIATED WITH ANALYSISID
	********************************/
	SET @Year=LEFT(@MAX_MMDMYearMonth,4)
	SET @MonthFlag = 1
	WHILE (@MonthFlag <= 12)
	BEGIN
	----1 in DateAdd below is interpreted as '1899-12-31 00:00:00.000
		DECLARE @MonthNameFlag VARCHAR(20) = DateName( month , DateAdd( month , CONVERT(INT,@MonthFlag) , -1 ))
		DECLARE @SQLMonthlyAnalysisID NVARCHAR(4000)
		--When we pull counts from previous month,should use previous analysisid
		IF @MonthFlag<=right(@MAX_MMDMYearMonth,2)
			BEGIN
				--GET Monthly ANALYSIS--SAME as No.3 just change variables
				if @ClID = 512 and @LOB = 'Medicare'
					SET @SQLMonthlyAnalysisID = '
					SELECT  @monthlyAnalysisID = max_AnalysisID
					FROM OPENQUERY('+ @LinkedServer + ',''
					select MAX(An_AnalysisID) max_AnalysisID
					FROM '+@ServerDB+'.encrypted
					WHERE MMDMYearMonth ='+@Year+RIGHT('0'+CONVERT(VARCHAR(2),@MonthFlag),2)+'
					 and Payor = ''''' + @LOB + ''''' 
					 AND PopulationName = ''''Wellcare''''
					 '')  

					 '
				ELSE
					SET @SQLMonthlyAnalysisID  = '
					SELECT  @monthlyAnalysisID = max_AnalysisID
					FROM OPENQUERY('+ @LinkedServer + ',''
					select MAX(An_AnalysisID) max_AnalysisID
					FROM '+@ServerDB+'.encrypted
					WHERE MMDMYearMonth ='+@Year+RIGHT('0'+CONVERT(VARCHAR(2),@MonthFlag),2)+'
					 and Payor = ''''' + @LOB + ''''' '')  '

				print (@SQLMonthlyAnalysisID)
				EXEC  sp_executesql @SQLMonthlyAnalysisID, N' @monthlyAnalysisID INT OUTPUT' , @monthlyAnalysisID = @monthlyAnalysisID OUTPUT 
				PRINT(@monthlyAnalysisID)
			
				--INSERT COUNTS
				SET @MMDMCounts = '
				INSERT INTO #AllClientMMDMTargets
		
				SELECT *
				FROM OPENQUERY('+ @LinkedServer + ',''

				SELECT	'+ CONVERT(VARCHAR, @ClID)+', 
						''''' + @ClientName + ''''' AS ClientName, 
						''''' + @LOB + ''''' AS LOB,
					    An_analysisid
						,MMDMYearmonth,'+Convert(Varchar(5),@MonthFlag)+','''''+@MonthNameFlag+''''',
						marketid,market,ContractNumber,
						REPLACE( (CASE WHEN '+@MonthNameFlag+'  NOT LIKE ''''%(%'''' THEN  '+@MonthNameFlag+'
							ELSE substring( '+@MonthNameFlag+',1,CHARINDEX(''''('''', '+@MonthNameFlag+',1)-1) END ),''''C-'''',''''''''),
						ResponsibleParty,		 
						memberid,	Clientmemberid, Personid
				FROM '+@ServerDB+'.encrypted
				where an_AnalysisID =  '+@monthlyAnalysisID+'
				and	(	'+@MonthNameFlag+' like ''''%EF%''''
					OR	'+@MonthNameFlag+' like ''''%SME%''''
					OR  '+@MonthNameFlag+' like ''''%MEO%''''
				) 
				and isnull(ResponsibleParty ,'''''''') not like  ''''%do%not%deploy%'''' '')
				'

				print(@MMDMCounts)	  
				EXEC(@MMDMCounts)

			END
		ELSE --current month counts and conditional counts,using current analysisid
			BEGIN
				--INSERT COUNTS
				SET @MMDMCounts = '
				INSERT INTO #AllClientMMDMTargets
		
				SELECT *
				FROM OPENQUERY('+ @LinkedServer + ',''

				SELECT	'+ CONVERT(VARCHAR, @ClID)+', 
						''''' + @ClientName + ''''' AS ClientName, 
						''''' + @LOB + ''''' AS LOB,
					    An_analysisid
						,MMDMYearmonth,'+Convert(Varchar(5),@MonthFlag)+','''''+@MonthNameFlag+''''',
						marketid,market,ContractNumber,
						REPLACE( (CASE WHEN '+@MonthNameFlag+'  NOT LIKE ''''%(%'''' THEN  '+@MonthNameFlag+'
							ELSE substring( '+@MonthNameFlag+',1,CHARINDEX(''''('''', '+@MonthNameFlag+',1)-1) END ),''''C-'''',''''''''),
						''''Inovalon'''',		 --conditional targets allow DND targets, because DND is applied to current month only
						memberid,	Clientmemberid, Personid
				FROM '+@ServerDB+'.encrypted
				where an_AnalysisID =  '+@monthlyAnalysisID+'
				and	(	'+@MonthNameFlag+' like ''''%EF%''''
					OR	'+@MonthNameFlag+' like ''''%SME%''''
					OR  '+@MonthNameFlag+' like ''''%MEO%''''
				) 
				--and isnull(ResponsibleParty ,'''''''') not like  ''''%do%not%deploy%'''' '')
				'
				print(@MMDMCounts)	  
				EXEC(@MMDMCounts)
			END

		SET @MonthFlag = @MonthFlag + 1

	END
	
  


	SET  @IDFlag = @IDFlag + 1

END 



--conditional targets' responsibleparty align with client per analytic config
Update A
set A.ResponsibleParty=R.ResponsibleParty
from #AllClientMMDMTargets A
join (
		select distinct cli_ClientID,InterventionType,svt_id, ResponsibleParty
		from [ResponsiblePartyConfig] 
		) R
on  A.ClientID=cli_ClientID
	and A.intervention=InterventionType
	and A.LOB=case when svt_id=73 then 'Medicare'
				   when svt_id in (74,70) then 'Medicaid'
				   when svt_id=68 then 'Commercial'
			   end

Update A
set A.ResponsibleParty='encrypted'
from #AllClientMMDMTargets A
where A.ResponsibleParty='encrypted'


Update A
set A.ResponsibleParty='encrypted'
--select *
from #AllClientMMDMTargets A
where clientid=512

select 
	pivotedData.ClientID
	, pivotedData.ClientName
	, pivotedData.LOB
	, B.isIntervention	
	, B.isAnalytics		
	, B.isPA				
	, B.isSA				
	, B.isActive		
	, C.An_AnalysisID
	, C.MMDMYearMonth
	, C.Enrollment
	, pivotedData.responsibleparty
	
	, pivotedData.Intervention
	, pivotedData.January
	, pivotedData.February
	, pivotedData.March
	, pivotedData.April
	, pivotedData.May
	, pivotedData.June
	, pivotedData.July
	, pivotedData.August
	, pivotedData.September
	, pivotedData.October
	, pivotedData.November
	, pivotedData.December
	, ISNULL(intvnTtls.Total,0) as [Total Targets]
	, ISNULL(intvnTtls.Unique_Total,0) as [Unique Targeted Members]
	, intvnTtls.ReportDate
	
from 
(
	select 
		ClientID,ClientName,LOB,responsibleparty
		, Intervention
		, isNull(January,0) as January
		, ISNULL(February,0) as February
		, ISNULL(March,0) as March
		, ISNULL(April,0) as April
		, ISNULL(May,0) as May
		, ISNULL(June,0) as June
		, ISNULL(July,0) as July
		, ISNULL(August,0) as August
		, ISNULL(September,0) as September
		, ISNULL(October,0) as October
		, ISNULL(November,0) as November
		, ISNULL(December,0) as December

	from
	(
		select 	ClientID,ClientName,LOB,intervention,responsibleparty,Month,count(distinct memberid) Targets
		from #AllClientMMDMTargets
		group by ClientID,ClientName,LOB,intervention,responsibleparty,Month
	
	) as details
	PIVOT
	( Sum(Targets)
	  for [Month] IN (January, February, March, April, May, June,July, August, September, October, November, December)
	) as piv

) as pivotedData
join
--totals by intervention
	( 
	 select ClientID,ClientName,LOB,responsibleparty,intervention, count(*) as Total,count(distinct memberid) Unique_Total, getDate() as ReportDate
	 from #AllClientMMDMTargets	
	 group by ClientID,ClientName,LOB,responsibleparty,intervention
	) as intvnTtls
	on pivotedData.ClientID = intvnTtls.ClientID
	and pivotedData.ClientName = intvnTtls.ClientName
	and pivotedData.LOB = intvnTtls.LOB
	--and pivotedData.An_AnalysisID = intvnTtls.An_AnalysisID
	--and pivotedData.MMDMYEARMONTH = intvnTtls.MMDMYEARMONTH
	and pivotedData.intervention = intvnTtls.intervention
	and pivotedData.responsibleparty = intvnTtls.responsibleparty
join #ClientDBs B
	on pivotedData.clientid=B.clientid and pivotedData.LOB=B.LOB
join #AllClientMMDMEnrollment C
	on pivotedData.clientid=C.clientid and pivotedData.LOB=C.LOB

order by ClientName, LOB,B.isIntervention desc,B.isAnalytics desc,intervention


/*
select *,(KeyCount - Last_MMDM_Count) Variance,FORMAT(
		(KeyCount - Last_MMDM_Count)*1.0  / Last_MMDM_Count*1.0,
		'P'
	) Variance_Percent
from (
select *,LAG(KeyCount,1) OVER (
			PARTITION BY ClientID,LOB
			ORDER BY Yearmonth
		) Last_MMDM_Count
from #MMDMenrByContrct
) A
order by ClientID,LOB,Yearmonth

--Pivot
if OBJECT_ID('tempdb..#Result') is not null
drop table #Result

select * ,([CD_enrollment] - MMDMEnrollment) Variance,FORMAT(
		([CD_enrollment] - MMDMEnrollment)*1.0  / MMDMEnrollment*1.0,
		'P'
	) Variance_Percent
into #Result
from (
	select ClientID,ClientName,LOB,DataQualityKey,ISNULL(KeyCount, 0)  as KeyCount from #MMDMenrByContrct
) 
as r
	Pivot
	( sum(KeyCount) for DataQualityKey in ([CD_enrollment],MMDMEnrollment) 
) 

AS P

select *
from #Result
order by clientname

 */




