USE ExamDB
GO

-- Start Candidate Module

-- This SP is used to login screen for Candidate
--EXEC GetCandidateToken 'Test', 'Test'

CREATE OR ALTER PROC GetCandidateToken
(
   @userId nvarchar(20),
   @password nvarchar(20)
)
AS
BEGIN
	DECLARE @candidateLoginId int = 0
	DECLARE @token varchar(50) = ''
	SELECT @candidateLoginId = CandidateLoginId FROM CandidateLogin  WHERE UserId = @userId AND Password = @password AND IsActive = 'Y'
   IF @candidateLoginId > 0
   BEGIN
		SET @token = newid() 
		DECLARE @dt datetime = getdate()

		INSERT INTO CandidateLoginToken (CandidateLoginId, Token, LoginStartTime, LoginEndTime) values (@candidateLoginId, @token, @dt, DATEADD(d, 1, @dt))
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

  	   INSERT INTO [ExamCandidateAttempt] ([Token], [ExamId], [CandidateLoginId], [CandidateName], [CandidateEmailId], 
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
					WHERE a.IsActive = 'Y' AND c.CandidateLoginId = @candidateLoginId AND c.ExamId = @examId AND b.SeqNo = @seqNo AND Token = @token
			
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
					WHERE o.IsActive = 'Y' AND c.CandidateLoginId = @candidateLoginId AND c.ExamId = @examId AND b.SeqNo = @seqNo AND Token = @token
END

GO

-- This SP is used to SubmitAnswer of question for Candidate
CREATE OR ALTER PROC SubmitAnswers(@examId int, @userId nvarchar(20), @token varchar(50), @seqNo int, @selectedOptionIds varchar(100))
AS
BEGIN
	DECLARE @candidateLoginId INT, @examCandidateAttemptQuestionsId int, @isAnswerCorrect char(1) = 'N', @score int = 0, @questionId int = 0
	SELECT @candidateLoginId = CandidateLoginId FROM CandidateLogin WHERE UserId = @userId AND IsActive = 'Y'

	SELECT @examCandidateAttemptQuestionsId = ExamCandidateAttemptQuestionsId, @questionId = QuestionId	
		FROM ExamCandidateAttemptQuestions b 
			INNER JOIN ExamCandidateAttempt c ON b.ExamCandidateAttemptId = c.ExamCandidateAttemptId
					WHERE c.CandidateLoginId = @candidateLoginId AND c.ExamId = @examId AND b.SeqNo = @seqNo AND Token = @token

	UPDATE ExamCandidateAttemptQuestionAnswers SET IsSelected = 'N' WHERE ExamCandidateAttemptQuestionsId = @examCandidateAttemptQuestionsId
	UPDATE ExamCandidateAttemptQuestionAnswers SET IsSelected = 'Y' WHERE ExamCandidateAttemptQuestionsId = @examCandidateAttemptQuestionsId 
		AND QuestionOptionsId IN (SELECT CAST(a.value AS INT) FROM STRING_SPLIT(@selectedOptionIds, ',') a)

	IF NOT EXISTS(SELECT 1 FROM QuestionOptions a 
		INNER JOIN ExamCandidateAttemptQuestions b ON b.ExamCandidateAttemptQuestionsId = @examCandidateAttemptQuestionsId AND a.QuestionId = b.QuestionId
		INNER JOIN ExamCandidateAttemptQuestionAnswers c ON b.ExamCandidateAttemptQuestionsId = c.ExamCandidateAttemptQuestionsId AND c.IsSelected = 'Y'
		WHERE a.IsActive = 'Y' AND (a.IsCorrect <> c.IsSelected) 
	  )
	BEGIN
		SET @isAnswerCorrect = 'Y'
		SELECT @score = MarkValue FROM Question WHERE QuestionId = @questionId AND IsActive = 'Y'
	END

		UPDATE ExamCandidateAttemptQuestions SET  IsAnswerCorrect = @isAnswerCorrect, GainScore = @score, AttemptTime = GETDATE()
			WHERE ExamCandidateAttemptQuestionsId = @examCandidateAttemptQuestionsId 
	
END

GO

-- This SP is used to Calculate total obtained marks for Candidate
CREATE OR ALTER PROC CalculateMarks(@examId int, @userId nvarchar(20), @token varchar(50))
AS
BEGIN
	DECLARE @candidateLoginId INT, @totalGainScore int
	SELECT @candidateLoginId = CandidateLoginId FROM CandidateLogin WHERE UserId = @userId AND IsActive = 'Y'

	SELECT 	@totalGainScore = SUM(b.GainScore)
		FROM ExamCandidateAttemptQuestions b 
			INNER JOIN ExamCandidateAttempt c ON b.ExamCandidateAttemptId = c.ExamCandidateAttemptId
					WHERE c.CandidateLoginId = @candidateLoginId AND c.ExamId = @examId AND Token = @token

	UPDATE ExamCandidateAttempt SET GainScore = @totalGainScore, PercentageScore = (@totalGainScore * 100) / TotalScore, EndTime = GETDATE(),
		CompleteAttempt = 1
		WHERE Token = @token and CandidateLoginId = @candidateLoginId AND ExamId = @examId
	UPDATE ExamCandidate SET NoofAttempted = NoofAttempted + 1, ModifiedBy = 'System', ModifiedDate = GETDATE() 
		WHERE IsActive = 'Y' AND ExamId = @examId AND CandidateLoginId = @candidateLoginId 
	
	SELECT ExamName, RequestedPersonEmail, CandidateName, CandidateEmailId, CandidatePhone, TotalScore, GainScore, PercentageScore, StartTime, EndTime 
		FROM ExamCandidateAttempt a
		INNER JOIN CandidateLogin b ON a.CandidateLoginId = b.CandidateLoginId
		INNER JOIN CandidateLoginRequest c ON b.CandidateLoginRequestId = c.CandidateLoginRequestId
		INNER JOIN Exam d ON a.ExamId = d.ExamId
		WHERE a.Token = @token AND a.ExamId = @examId AND a.CandidateLoginId = @candidateLoginId 
		AND b.IsActive = 'Y' AND c.IsActive = 'Y' AND d.IsActive = 'Y'
END

GO

-- End Candidate Module

-- Start Admin Module

-- This SP is used to login screen for Admin
--EXEC GetAdminToken 'Test', 'Test'

CREATE OR ALTER PROC GetAdminToken
(
   @userId nvarchar(20),
   @password nvarchar(20)
)
AS
BEGIN
	DECLARE @adminLoginId int = 0
	DECLARE @token varchar(50) = ''
	SELECT @adminLoginId = AdminLoginId FROM AdminLogin  WHERE UserId = @userId AND Password = @password AND IsActive = 'Y'
   IF @adminLoginId > 0
   BEGIN
		SET @token = newid() 
		DECLARE @dt datetime = getdate()

		INSERT INTO AdminLoginToken (AdminLoginId, Token, LoginStartTime, LoginEndTime) values (@adminLoginId, @token, @dt, DATEADD(d, 1, @dt))
	END	
	
	SELECT @token
END

GO


-- This SP is used to create login credential for Candidate
--EXEC AddCadidateLogins 'prasad.indra@gmail.com', 'test', 5, 3, '1,2,4','2020/12/31', '2021/12/31'
CREATE OR ALTER PROC AddCadidateLogins
(
  @requestedPersonEmail nvarchar(250), 
  @noOfRequestedUserId int,
  @noOfAttempt int,
  @examIds varchar(100), --1,2,3,4
  @validFrom date,
  @validTo date,
  @adminUserId nvarchar(20)
)
AS
BEGIN
	DECLARE @counter int = @noOfRequestedUserId
	Declare @guid varchar(50) = '', @userId varchar(20), @password varchar(20)
	Declare @dt datetime = getdate(), @reqCount int = 0
	Declare @candidateLoginRequestId int
	SELECT @reqCount = COUNT(1) FROM CandidateLoginRequest WHERE RequestedPersonEmail = @requestedPersonEmail 
	SET @reqCount = @reqCount + 1
	Declare @requestId varchar(20)
	SET @requestId = 'REQ' + REPLACE(STR(@reqCount,5),' ','0')
	
	INSERT INTO CandidateLoginRequest ([RequestId], [RequestDate], [RequestedPersonEmail], [CreatedBy], [CreatedDate], [ModifiedBy], [ModifiedDate], [IsActive]) 
		VALUES (@requestId, @dt, @requestedPersonEmail, @adminUserId, @dt, @adminUserId, @dt, 'Y')

    SET @candidateLoginRequestId = SCOPE_IDENTITY()

	WHILE(@counter > 0)
	BEGIN
		
		SET @guid = newid()
		SET @userId = 'user@'+lower(substring(@guid, 1, CHARINDEX('-', @guid) -1))
		SET @password = 'pass@'+lower(right(@guid, charindex('-', reverse(@guid)) - 1))
		
		IF NOT EXISTS (SELECT 1 FROM CandidateLogin WHERE UserId = @userId AND Password = @password AND IsActive = 'Y') 
		BEGIN
			INSERT INTO CandidateLogin(CandidateLoginRequestId, UserId, [Password], ValidFrom, ValidTo, [CreatedBy], [CreatedDate], [ModifiedBy], [ModifiedDate], [IsActive]) 
			VALUES (@candidateLoginRequestId, @userId, @password, @validFrom, @validTo, @adminUserId, @dt, @adminUserId, @dt, 'Y')

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



-- This SP is used to get list of Candidate for download or send email
CREATE OR ALTER PROC DownloadCadidateLoginIds(@candidateLoginRequestId int)
AS
BEGIN
  SELECT RequestId, RequestDate, UserId, [Password], TotalNoofAttempts, ExamName, ValidFrom, ValidTo, RequestDate
		FROM CandidateLoginRequest a
		INNER JOIN CandidateLogin b ON a.CandidateLoginRequestId= b.CandidateLoginRequestId 
		INNER JOIN ExamCandidate c ON b.CandidateLoginId = c.CandidateLoginId
		INNER JOIN Exam d ON c.ExamId = d.ExamId 
			WHERE a.IsActive = 'Y' AND b.IsActive = 'Y' AND c.IsActive = 'Y' AND d.IsActive = 'Y'
			AND a.CandidateLoginRequestId = @candidateLoginRequestId
			ORDER BY b.CandidateLoginId, d.ExamId
END

GO


-- This SP is used to get list of Candidate for download or send email
CREATE OR ALTER PROC SearchRequests(@search nvarchar(250))
AS
BEGIN
  SELECT CandidateLoginRequestId, RequestId, RequestDate, RequestedPersonEmail
		FROM CandidateLoginRequest 
			WHERE IsActive = 'Y' AND (RequestedPersonEmail LIKE '%' + @search + '%' OR RequestId LIKE '%' + @search + '%')
			ORDER BY RequestDate Desc, RequestId ASC
END

GO

-- This SP is used to get list of Candidate for download or send email
CREATE OR ALTER PROC GetListRequestsByRequestedEmail(@requestedPersonEmail nvarchar(250))
AS
BEGIN
  SELECT CandidateLoginRequestId, RequestId, RequestDate, RequestedPersonEmail
		FROM CandidateLoginRequest 
			WHERE IsActive = 'Y' AND RequestedPersonEmail = @requestedPersonEmail
			ORDER BY RequestDate Desc, RequestId ASC
END

GO

-- This SP is used to get list of Candidate for download or send email
CREATE OR ALTER PROC DeleteRequestedLogin(@candidateLoginRequestId nvarchar(250), @adminUserId nvarchar(20))
AS
BEGIN
	Declare @dt datetime = getdate()

	IF NOT EXISTS (SELECT 1 FROM ExamCandidateAttempt a 
					INNER JOIN CandidateLogin b ON a.CandidateLoginId = b.CandidateLoginId
					INNER JOIN CandidateLoginRequest c ON b.CandidateLoginRequestId = c.CandidateLoginRequestId
					WHERE b.IsActive = 'Y' AND c.IsActive = 'Y' AND c.CandidateLoginRequestId = @candidateLoginRequestId)
	BEGIN

		UPDATE ExamCandidate  SET IsActive = 'N', ModifiedBy = @adminUserId, ModifiedDate = @dt 
			WHERE CandidateLoginId IN (SELECT CandidateLoginId FROM CandidateLogin b
											INNER JOIN CandidateLoginRequest c 
												ON b.CandidateLoginRequestId = c.CandidateLoginRequestId
										WHERE b.IsActive = 'Y' AND c.IsActive = 'Y' AND c.CandidateLoginRequestId = @candidateLoginRequestId)

		UPDATE CandidateLogin SET IsActive = 'N', ModifiedBy = @adminUserId, ModifiedDate = @dt 
			WHERE IsActive = 'Y' AND CandidateLoginRequestId 
				IN (SELECT CandidateLoginRequestId FROM CandidateLoginRequest WHERE IsActive = 'Y' 
							AND CandidateLoginRequestId = @candidateLoginRequestId)

		UPDATE CandidateLoginRequest SET IsActive = 'N', ModifiedBy = @adminUserId, ModifiedDate = @dt 
			WHERE IsActive = 'Y' AND CandidateLoginRequestId = @candidateLoginRequestId

	END
END

GO

-- This SP is used to Add or Edit exam
CREATE OR ALTER PROC AddEditExam(@examId int, @examName nvarchar(1000), 
				@totalMarks int, @passingPercentage int, @instructions nvarchar(4000), @duration int, @adminUserId nvarchar(20))
AS
BEGIN
  DECLARE @dt DateTime = GETDATE()

  IF @examId = 0
  BEGIN
	INSERT INTO Exam (ExamName, TotalMarks, PassingPercentage, Instructions, Duration, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, IsActive)
			VALUES (@examName, @totalMarks, @passingPercentage, @instructions, @duration, @adminUserId, @dt, @adminUserId, @dt, 'Y')
  END
  ELSE
  BEGIN
	UPDATE Exam SET ExamName = @examName, TotalMarks = @totalMarks, PassingPercentage = @passingPercentage, Instructions = @instructions,
			Duration = @duration, ModifiedBy = @AdminUserId, ModifiedDate = @dt WHERE IsActive = 'Y' AND ExamId = @examId
	
  END
END

GO


-- This SP is used to delete exam
CREATE OR ALTER PROC DeleteExam(@examId int, @adminUserId nvarchar(20))
AS
BEGIN
	DECLARE @dt DateTime = GETDATE()

	UPDATE Exam Set IsActive = 'N', ModifiedBy = @adminUserId, ModifiedDate = @dt  WHERE ExamId = @examId AND IsActive = 'Y'

END

GO

-- This SP is used to exam detail
CREATE OR ALTER PROC GetExam(@examId int)
AS
BEGIN
	SELECT ExamId, ExamName, TotalMarks, PassingPercentage, Instructions, Duration FROM Exam WHERE IsActive = 'Y' AND ExamId = @examId
END

GO

-- This SP is used to exam detail
CREATE OR ALTER PROC SearchExams(@search nvarchar(250))
AS
BEGIN
	SELECT ExamId, ExamName, TotalMarks, PassingPercentage, Instructions, Duration FROM Exam WHERE IsActive = 'Y' AND ExamName LIKE '%' + @search + '%'
END

GO

-- This SP is used to Add or Edit question
CREATE OR ALTER PROC AddEditQuestion(@questionId int, @questionTypeId int, @question nvarchar(1000), @noofOption int,
		@markValue int, @complexityLevelId int, @examIds varchar(1000), @options varchar(8000), @adminUserId nvarchar(20))
		--ExamIds like <Exam1_Id>,<Exam5_Id>,<Exam9_Id> and 
		--Options like <QuestionOptionId>||SlNo||<Options>||<IsCorrect>||<Operation>#<QuestionOptionId>||<SlNo>||<Options>||<IsCorrect>||<Operation>
				--Operation A for Add, E for Edit, D for Delete

AS
BEGIN
  DECLARE @dt DateTime = GETDATE()
  DECLARE @optionTable Table (QuestionOptionId int, SlNo int, Options nvarchar(1000), IsCorrect char(1), Operation char(1)) 
  DECLARE @examIdsTable Table (ExamId int) 

  INSERT INTO @examIdsTable (ExamId)
	SELECT CAST(value AS INT) AS ExamId FROM string_split(@examIds, ',')

  INSERT INTO @optionTable (QuestionOptionId, SlNo, Options, IsCorrect, Operation) 
	SELECT 
		REVERSE(PARSENAME(REPLACE(REVERSE(value), '||', '.'), 1)) AS QuestionOptionId,
		REVERSE(PARSENAME(REPLACE(REVERSE(value), '||', '.'), 2)) AS SlNo,
		REVERSE(PARSENAME(REPLACE(REVERSE(value), '||', '.'), 3)) AS Options,
		REVERSE(PARSENAME(REPLACE(REVERSE(value), '||', '.'), 4)) AS IsCorrect,
		REVERSE(PARSENAME(REPLACE(REVERSE(value), '||', '.'), 5)) AS Operation
		FROM string_split(@options, '#')  


  IF @questionId = 0
  BEGIN
	INSERT INTO Question(QuestionTypeId, Question, NoOfOption, MarkValue, ComplexityLevelId, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, IsActive)
			VALUES (@questionTypeId, @question, @noofOption, @markValue, @complexityLevelId, @adminUserId, @dt, @adminUserId, @dt, 'Y')
	
	SET @questionId = SCOPE_IDENTITY()
	
	INSERT INTO ExamQuestion (ExamId, QuestionId, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, IsActive)
		SELECT ExamId, @questionId, @adminUserId, @dt, @adminUserId, @dt, 'Y' FROM @examIdsTable

	INSERT INTO QuestionOptions (QuestionId, SlNo, [Option], IsCorrect, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, IsActive)
		SELECT @questionId, SlNo, Options, IsCorrect, @adminUserId, @dt, @adminUserId, @dt, 'Y' FROM @optionTable 
  END
  ELSE
  BEGIN
		UPDATE Question SET Question = @question, QuestionTypeId = @questionTypeId, NoOfOption= @noofOption, MarkValue= @markValue, ComplexityLevelId= @complexityLevelId,
					ModifiedBy = @adminUserId, ModifiedDate = @dt WHERE IsActive = 'Y' AND QuestionId = @questionId

		UPDATE ExamQuestion SET ModifiedBy = @adminUserId, ModifiedDate = @dt, IsActive = 'N' 
				WHERE QuestionId = @questionId AND IsActive = 'Y' AND ExamId NOT IN (SELECT ExamId FROM @examIdsTable) 

		UPDATE ExamQuestion SET ModifiedBy = @adminUserId, ModifiedDate = @dt, IsActive = 'Y' 
				WHERE QuestionId = @questionId AND IsActive = 'Y' AND ExamId IN (SELECT ExamId FROM @examIdsTable) 

		INSERT INTO ExamQuestion (ExamId, QuestionId, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, IsActive)
				SELECT ExamId, @questionId, @adminUserId, @dt, @adminUserId, @dt, 'Y' FROM @examIdsTable 
						WHERE ExamId NOT IN (SELECT ExamId FROM ExamQuestion WHERE QuestionId = @questionId AND IsActive = 'Y')
	
		
		UPDATE a SET a.[Option] = b.Options, a.SlNo = b.SlNo, a.IsCorrect = b.IsCorrect, 
			a.ModifiedBy = @adminUserId, a.ModifiedDate = @dt, a.IsActive = 'Y' 
			FROM QuestionOptions a 
			INNER JOIN @optionTable b ON a.QuestionOptionsId = b.QuestionOptionId
			WHERE a.QuestionId = @questionId AND b.QuestionOptionId > 0 AND b.Operation = 'E'

		UPDATE a SET a.ModifiedBy = @adminUserId, a.ModifiedDate = @dt, a.IsActive = 'N' 
			FROM QuestionOptions a 
			INNER JOIN @optionTable b ON a.QuestionOptionsId = b.QuestionOptionId
			WHERE a.QuestionId = @questionId AND b.QuestionOptionId > 0 AND b.Operation = 'D'

		INSERT INTO QuestionOptions (QuestionId, SlNo, [Option], IsCorrect, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, IsActive)
			SELECT @questionId, SlNo, Options, IsCorrect, @adminUserId, @dt, @adminUserId, @dt, 'Y' FROM @optionTable WHERE Operation = 'A'
  END
END

GO


-- This SP is used to delete question
CREATE OR ALTER PROC DeleteQuestion(@questionId int, @adminUserId nvarchar(20))
AS
BEGIN
	DECLARE @dt DateTime = GETDATE()

	UPDATE Question Set IsActive = 'N', ModifiedBy = @adminUserId, ModifiedDate = @dt  WHERE QuestionId = @questionId AND IsActive = 'Y'
	UPDATE QuestionOptions Set IsActive = 'N', ModifiedBy = @adminUserId, ModifiedDate = @dt  WHERE QuestionId = @questionId AND IsActive = 'Y'
END

GO

-- This SP is used to question detail
CREATE OR ALTER PROC GetQuestion(@questionId int)
AS
BEGIN
	SELECT QuestionId, QuestionTypeId, Question, NoOfOption, MarkValue, ComplexityLevelId
		FROM Question WHERE IsActive = 'Y' AND QuestionId = @questionId
END

GO

-- This SP is used to question detail
CREATE OR ALTER PROC GetQuestionOptions(@questionId int)
AS
BEGIN
	SELECT QuestionOptionsId, SlNo, [Option], IsCorrect
		FROM QuestionOptions WHERE IsActive = 'Y' AND QuestionId = @questionId
END

GO

-- This SP is used to exam detail
CREATE OR ALTER PROC SearchQuestions(@search nvarchar(250))
AS
BEGIN
	SELECT QuestionId, QuestionType, Question, NoOfOption, MarkValue, ComplexityLevel
		FROM Question a 
			INNER JOIN QuestionType b ON a.QuestionTypeId = b.QuestionTypeId
			INNER JOIN ComplexityLevel c ON a.ComplexityLevelId = c.ComplexityLevelId
		WHERE IsActive = 'Y' AND Question LIKE '%' + @search + '%'
END

GO