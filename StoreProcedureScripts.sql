--EXEC GetCandidateToken 'Test', 'Test'

CREATE OR ALTER PROC GetCandidateToken
(
   @UserId nvarchar(20),
   @Password nvarchar(20)
)
AS
BEGIN
	DECLARE @candidateLoginId int = 0
	DECLARE @token varchar(50) = ''
	SELECT @candidateLoginId = CandidateLoginId FROM CandidateLogin  WHERE UserId = @UserId AND Password = @Password AND IsActive = 'Y'
   IF @candidateLoginId > 0
   BEGIN
		SET @token = newid() 
		DECLARE @dt datetime = getdate()

		INSERT INTO CandidateLoginToken (CandidateLoginId, Token, LoginStartTime, LoginEndTime) values (@candidateLoginId, @token, @dt, DATEADD(d, 1, @dt))
	END	
	
	SELECT @token
END

GO
--EXEC GetAdminToken 'Test', 'Test'

CREATE OR ALTER PROC GetAdminToken
(
   @UserId nvarchar(20),
   @Password nvarchar(20)
)
AS
BEGIN
	DECLARE @adminLoginId int = 0
	DECLARE @token varchar(50) = ''
	SELECT @adminLoginId = AdminLoginId FROM AdminLogin  WHERE UserId = @UserId AND Password = @Password AND IsActive = 'Y'
   IF @adminLoginId > 0
   BEGIN
		SET @token = newid() 
		DECLARE @dt datetime = getdate()

		INSERT INTO AdminLoginToken (AdminLoginId, Token, LoginStartTime, LoginEndTime) values (@adminLoginId, @token, @dt, DATEADD(d, 1, @dt))
	END	
	
	SELECT @token
END

GO
--EXEC CreateCadidateLogin 'prasad.indra@gmail.com', 'test', 5, 3, '1,2,4','2020/12/31', '2021/12/31'
CREATE OR ALTER PROC CreateCadidateLogin
(
  @RequestedPersonEmail nvarchar(250), 
  @AdminUserId nvarchar(20),
  @NoOfRequestedUserId int,
  @NoOfAttempt int,
  @ExamIds varchar(100), --1,2,3,4
  @ValidFrom date,
  @ValidTo date
)
AS
BEGIN
	DECLARE @counter int = @NoOfRequestedUserId
	Declare @guid varchar(50) = '', @userId varchar(20), @password varchar(20)
	Declare @dt datetime = getdate(), @reqCount int = 0
	Declare @candidateLoginRequestId int
	SELECT @reqCount = COUNT(1) FROM CandidateLoginRequest WHERE RequestedPersonEmail = @RequestedPersonEmail 
	SET @reqCount = @reqCount + 1
	Declare @requestId varchar(20)
	SET @requestId = 'REQ' + REPLACE(STR(@reqCount,5),' ','0')
	
	INSERT INTO CandidateLoginRequest ([RequestId], [RequestDate], [RequestedPersonEmail], [CreatedBy], [CreatedDate], [ModifiedBy], [ModifiedDate], [IsActive]) 
		VALUES (@requestId, @dt, @RequestedPersonEmail, @AdminUserId, @dt, @AdminUserId, @dt, 'Y')

    SET @candidateLoginRequestId = SCOPE_IDENTITY()

	WHILE(@counter > 0)
	BEGIN
		
		SET @guid = newid()
		SET @userId = 'user@'+lower(substring(@guid, 1, CHARINDEX('-', @guid) -1))
		SET @password = 'pass@'+lower(right(@guid, charindex('-', reverse(@guid)) - 1))
		
		IF NOT EXISTS (SELECT 1 FROM CandidateLogin WHERE UserId = @userId AND Password = @password AND IsActive = 'Y') 
		BEGIN
			INSERT INTO CandidateLogin(CandidateLoginRequestId, UserId, [Password], ValidFrom, ValidTo, [CreatedBy], [CreatedDate], [ModifiedBy], [ModifiedDate], [IsActive]) 
			VALUES (@candidateLoginRequestId, @userId, @password, @ValidFrom, @ValidTo, @AdminUserId, @dt, @AdminUserId, @dt, 'Y')

			SET @counter = @counter - 1
		END
	 END

	 INSERT INTO ExamCandidate (ExamId, CandidateLoginId, NoofAttempt,  [CreatedBy], [CreatedDate], [ModifiedBy], [ModifiedDate], [IsActive]) 
		SELECT a.value AS ExamId, b.CandidateLoginId, @noOfAttempt, @adminUserId, @dt, @adminUserId, @dt, 'Y'
			FROM STRING_SPLIT(@ExamIds, ',') a
			CROSS JOIN (SELECT CandidateLoginId FROM CandidateLogin WHERE CandidateLoginRequestId = @candidateLoginRequestId AND IsActive = 'Y') b

  SELECT RequestId, RequestDate, UserId, [Password], NoofAttempt, ExamName, ValidFrom, ValidTo, RequestDate
		FROM CandidateLoginRequest a
		INNER JOIN CandidateLogin b ON a.CandidateLoginRequestId = b.CandidateLoginRequestId 
		INNER JOIN ExamCandidate c ON b.CandidateLoginId = c.CandidateLoginId
		INNER JOIN Exam d ON c.ExamId = d.ExamId 
			WHERE a.IsActive = 'Y' AND b.IsActive = 'Y' AND c.IsActive = 'Y' AND d.IsActive = 'Y'
			AND a.CandidateLoginRequestId = @candidateLoginRequestId
			ORDER BY b.CandidateLoginId, d.ExamId
END

GO


CREATE OR ALTER PROC GetCadidateLoginIds(@requestedPersonEmail nvarchar(250), @requestId varchar(20))
AS
BEGIN
  SELECT RequestId, RequestDate, UserId, [Password], NoofAttempt, ExamName, ValidFrom, ValidTo, RequestDate
		FROM CandidateLoginRequest a
		INNER JOIN CandidateLogin b ON a.CandidateLoginRequestId= b.CandidateLoginRequestId 
		INNER JOIN ExamCandidate c ON b.CandidateLoginId = c.CandidateLoginId
		INNER JOIN Exam d ON c.ExamId = d.ExamId 
			WHERE a.IsActive = 'Y' AND b.IsActive = 'Y' AND c.IsActive = 'Y' AND d.IsActive = 'Y'
			AND RequestedPersonEmail = @requestedPersonEmail AND RequestId =  @requestId
			ORDER BY b.CandidateLoginId, d.ExamId
END

GO
