USE ExamDB
GO
-- This SP is used to login screen for Candidate
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

-- This SP is used to login screen for Admin
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


-- This SP is used to Get list of assigned exam for Candiate
CREATE OR ALTER PROC GetListExam(@userId nvarchar(20))
AS
BEGIN
  SELECT d.ExamId, ExamName
		FROM CandidateLoginRequest a
		INNER JOIN CandidateLogin b ON a.CandidateLoginRequestId= b.CandidateLoginRequestId 
		INNER JOIN ExamCandidate c ON b.CandidateLoginId = c.CandidateLoginId
		INNER JOIN Exam d ON c.ExamId = d.ExamId 
			WHERE a.IsActive = 'Y' AND b.IsActive = 'Y' AND c.IsActive = 'Y' AND d.IsActive = 'Y'
			AND b.UserId = @userId 
END

GO

-- This SP is used to Get list of assigned exam for Candiate
CREATE OR ALTER PROC GetCandidateExamInfo(@examId int, @userId nvarchar(20))
AS
BEGIN
  SELECT d.ExamId, ExamName, Instructions, TotalNoofAttempts, NoofAttempted
		FROM CandidateLoginRequest a
		INNER JOIN CandidateLogin b ON a.CandidateLoginRequestId= b.CandidateLoginRequestId 
		INNER JOIN ExamCandidate c ON b.CandidateLoginId = c.CandidateLoginId
		INNER JOIN Exam d ON c.ExamId = d.ExamId 
			WHERE a.IsActive = 'Y' AND b.IsActive = 'Y' AND c.IsActive = 'Y' AND d.IsActive = 'Y'
			AND b.UserId = @userId AND d.ExamId = @examId
END

GO

-- This SP is used to Get list of assigned exam for Candidate
CREATE OR ALTER PROC CandidateExamStart(@examId int, @userId nvarchar(20), @token varchar(50), @candidateName nvarchar(100), @candidateEmailId nvarchar(250), @candidatePhone nvarchar(12))
AS
BEGIN
	DECLARE @totalmarks int = 0, @candidateLoginId int = 0, @minQuestionMark int = 0, @totalQestions int = 0, @questionTypeId int = 0,
		@examCandidateAttemptId INT = 0, @counter int = 1, @questId int = 0, @markval int = 0, @examCandidateAttemptQuestionsId int = 0
	Declare @RandomQuestions Table(sqno int identity(1,1), questionId int, markValue int, questionTypeId int)
	Declare @RandomOptions Table(sqno int identity(1,1), questionOptionsId int)

	SELECT @candidateLoginId = CandidateLoginId FROM CandidateLogin WHERE UserId = @userId AND IsActive = 'Y'

	IF @candidateLoginId > 0
	BEGIN

		SELECT @totalmarks = TotalMarks FROM Exam WHERE ExamId = @examId AND IsActive = 'Y'
		SELECT @minQuestionMark = MIN(MarkValue), @totalQestions = Count(1) FROM Question a 
			INNER JOIN ExamQuestion b ON a.QuestionId = b.QuestionId 
				Where ExamId = @examId AND a.IsActive = 'Y' AND b.IsActive = 'Y'

  	   INSERT INTO [ExamCandidateAttempt] ([Token], [ExamId], [CandidateId], [CandidateName], [CandidateEmailId], 
	     	[CandidatePhone], [AttemptDate], [CompleteAttempt], [StartTime], [EndTime], [TotalScore], [GainScore], [PercentageScore])
	    VALUES (@token, @examId, @candidateLoginId, @candidateName, @candidateEmailId, @candidatePhone, CAST(GETDATE() AS Date), 0, GETDATE(), NULL, @totalmarks, 0, 0)
	
		SET @examCandidateAttemptId = SCOPE_IDENTITY()

		-- Logic for picking random questions
		INSERT INTO @RandomQuestions(questionId, markValue, questionTypeId)
		SELECT a.QuestionId, a.MarkValue, a.QuestionTypeId FROM Question a 
				INNER JOIN ExamQuestion b ON a.QuestionId = b.QuestionId 
					Where ExamId = @examId AND a.IsActive = 'Y' AND b.IsActive = 'Y' ORDER BY newid() 
	
		WHILE(@totalmarks > 0 AND @totalQestions >= @counter)
		BEGIN

			SELECT  @questId = questionid, @markval = markValue, @questionTypeId = questionTypeId FROM @RandomQuestions WHERE sqno = @counter
			IF @totalmarks - @markval >= 0 
			BEGIN
				INSERT INTO ExamCandidateAttemptQuestions (ExamCandidateAttemptId, SeqNo, QuestionId)
					VALUES (@examCandidateAttemptId, @counter, @questId)
				
				SET @examCandidateAttemptQuestionsId = SCOPE_IDENTITY()

				IF(@questionTypeId <> 1)
				BEGIN
					INSERT INTO @RandomOptions(questionOptionsId)
						SELECT QuestionOptionsId FROM QuestionOptions WHERE QuestionId = @questId ORDER BY newid() 
				END
				ELSE 
				BEGIN
					INSERT INTO @RandomOptions(questionOptionsId)
						SELECT QuestionOptionsId FROM QuestionOptions WHERE QuestionId = @questId
				END
				INSERT INTO ExamCandidateAttemptQuestionAnswers (ExamCandidateAttemptQuestionsId, SlNo, QuestionOptionsId, IsSelected)
					SELECT @examCandidateAttemptQuestionsId, sqno, questionOptionsId, 'N' FROM @RandomOptions

				SET @totalmarks = @totalmarks - @markval
			END
		
			SET @counter = @counter + 1
		END
	END
END
GO

-- This SP is used to Get next prev question for Candidate
CREATE OR ALTER PROC GetNextPrevQuestion(@examId int, @userId nvarchar(20), @token varchar(50), @seqNo int)
AS
BEGIN
	DECLARE @candidateLoginId INT
	SELECT @candidateLoginId = CandidateLoginId FROM CandidateLogin WHERE UserId = @userId AND IsActive = 'Y'

	SELECT a.QuestionId, a.Question, a.QuestionTypeId, a.MarkValue FROM Question a 
					INNER JOIN ExamCandidateAttemptQuestions b ON a.QuestionId = b.QuestionId
					INNER JOIN ExamCandidateAttempt c ON b.ExamCandidateAttemptId = c.ExamCandidateAttemptId
					WHERE a.IsActive = 'Y' AND c.CandidateId = @candidateLoginId AND c.ExamId = @examId AND b.SeqNo = @seqNo AND Token = @token
			
END

GO

-- This SP is used to Get options of question for Candidate
CREATE OR ALTER PROC GetQuestionOptions(@examId int, @userId nvarchar(20), @token varchar(50), @seqNo int)
AS
BEGIN
	DECLARE @candidateLoginId INT
	SELECT @candidateLoginId = CandidateLoginId FROM CandidateLogin WHERE UserId = @userId AND IsActive = 'Y'

	SELECT a.SlNo, a.QuestionOptionsId, o.[Option], a.IsSelected FROM QuestionOptions o 
			INNER JOIN ExamCandidateAttemptQuestionAnswers a ON a.QuestionOptionsId = o.QuestionOptionsId 
			INNER JOIN ExamCandidateAttemptQuestions b ON a.ExamCandidateAttemptQuestionsId = b.ExamCandidateAttemptQuestionsId
			INNER JOIN ExamCandidateAttempt c ON b.ExamCandidateAttemptId = c.ExamCandidateAttemptId
					WHERE o.IsActive = 'Y' AND c.CandidateId = @candidateLoginId AND c.ExamId = @examId AND b.SeqNo = @seqNo AND Token = @token
END

GO

-- This SP is used to SubmitAnswer of question for Candidate
CREATE OR ALTER PROC SubmitAnswers(@examId int, @userId nvarchar(20), @token varchar(50), @seqNo int, @selectedOptionIds varchar(100))
AS
BEGIN
	DECLARE @candidateLoginId INT, @examCandidateAttemptQuestionsId int
	SELECT @candidateLoginId = CandidateLoginId FROM CandidateLogin WHERE UserId = @userId AND IsActive = 'Y'

	SELECT @examCandidateAttemptQuestionsId = ExamCandidateAttemptQuestionsId	
		FROM ExamCandidateAttemptQuestions b 
			INNER JOIN ExamCandidateAttempt c ON b.ExamCandidateAttemptId = c.ExamCandidateAttemptId
					WHERE c.CandidateId = @candidateLoginId AND c.ExamId = @examId AND b.SeqNo = @seqNo AND Token = @token

	UPDATE ExamCandidateAttemptQuestionAnswers SET IsSelected = 'N' WHERE ExamCandidateAttemptQuestionsId = @examCandidateAttemptQuestionsId
	UPDATE ExamCandidateAttemptQuestionAnswers SET IsSelected = 'Y' WHERE ExamCandidateAttemptQuestionsId = @examCandidateAttemptQuestionsId 
		AND QuestionOptionsId IN (SELECT CAST(a.value AS INT) FROM STRING_SPLIT(@selectedOptionIds, ',') a)
END

GO

-- This SP is used to create login credential for Candidate
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

	 INSERT INTO ExamCandidate (ExamId, CandidateLoginId, TotalNoofAttempts, NoofAttempted, [CreatedBy], [CreatedDate], [ModifiedBy], [ModifiedDate], [IsActive]) 
		SELECT a.value AS ExamId, b.CandidateLoginId, @noOfAttempt, 0, @adminUserId, @dt, @adminUserId, @dt, 'Y'
			FROM STRING_SPLIT(@ExamIds, ',') a
			CROSS JOIN (SELECT CandidateLoginId FROM CandidateLogin WHERE CandidateLoginRequestId = @candidateLoginRequestId AND IsActive = 'Y') b

  SELECT RequestId, RequestDate, UserId, [Password], TotalNoofAttempts, ExamName, ValidFrom, ValidTo, RequestDate
		FROM CandidateLoginRequest a
		INNER JOIN CandidateLogin b ON a.CandidateLoginRequestId = b.CandidateLoginRequestId 
		INNER JOIN ExamCandidate c ON b.CandidateLoginId = c.CandidateLoginId
		INNER JOIN Exam d ON c.ExamId = d.ExamId 
			WHERE a.IsActive = 'Y' AND b.IsActive = 'Y' AND c.IsActive = 'Y' AND d.IsActive = 'Y'
			AND a.CandidateLoginRequestId = @candidateLoginRequestId
			ORDER BY b.CandidateLoginId, d.ExamId
END

GO



-- This SP is used to get list of 
CREATE OR ALTER PROC GetCadidateLoginIds(@requestedPersonEmail nvarchar(250), @requestId varchar(20))
AS
BEGIN
  SELECT RequestId, RequestDate, UserId, [Password], TotalNoofAttempts, ExamName, ValidFrom, ValidTo, RequestDate
		FROM CandidateLoginRequest a
		INNER JOIN CandidateLogin b ON a.CandidateLoginRequestId= b.CandidateLoginRequestId 
		INNER JOIN ExamCandidate c ON b.CandidateLoginId = c.CandidateLoginId
		INNER JOIN Exam d ON c.ExamId = d.ExamId 
			WHERE a.IsActive = 'Y' AND b.IsActive = 'Y' AND c.IsActive = 'Y' AND d.IsActive = 'Y'
			AND RequestedPersonEmail = @requestedPersonEmail AND RequestId =  @requestId
			ORDER BY b.CandidateLoginId, d.ExamId
END

GO


