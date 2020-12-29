USE [ExamDB]
GO

/****** Object:  Table [dbo].[CandidateLogin]    Script Date: 12/24/2020 12:48:14 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON

IF OBJECT_ID('dbo.CandidateLoginRequest', 'U') IS NOT NULL 
  DROP TABLE [dbo].[CandidateLoginRequest]
GO
CREATE TABLE [dbo].[CandidateLoginRequest](
	[CandidateLoginRequestId] [int] IDENTITY(1,1) NOT NULL,
	[RequestId] [nvarchar](20) NOT NULL,
	[RequestDate] [datetime] NOT NULL,
	[RequestedPersonEmail] nvarchar(250) NOT NULL,
	[CreatedBy] [nvarchar](20) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](20) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[IsActive] [char](1) NOT NULL
) ON [PRIMARY]

GO
IF OBJECT_ID('dbo.CandidateLogin', 'U') IS NOT NULL 
  DROP TABLE [dbo].[CandidateLogin]
GO
CREATE TABLE [dbo].[CandidateLogin](
	[CandidateLoginId] [int] IDENTITY(1,1) NOT NULL,
	[CandidateLoginRequestId] int NOT NULL,
	[UserId] [nvarchar](20) NOT NULL,
	[Password] [nvarchar](20) NOT NULL,
	[ValidFrom] [date] NOT NULL,
	[ValidTo] date NOT NULL,
	[CreatedBy] [nvarchar](20) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](20) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[IsActive] [char](1) NOT NULL
) ON [PRIMARY]
GO

IF OBJECT_ID('dbo.AdminLogin', 'U') IS NOT NULL 
  DROP TABLE [dbo].[AdminLogin]
GO
CREATE TABLE [dbo].[AdminLogin](
	[AdminLoginId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [nvarchar](20) NOT NULL,
	[EmailId] nvarchar(250) NOT NULL,
	[Password] [nvarchar](20) NOT NULL,
	[IsActive] [char](1) NOT NULL
) ON [PRIMARY]
GO

IF OBJECT_ID('dbo.Exam', 'U') IS NOT NULL 
  DROP TABLE [dbo].[Exam]
GO
CREATE TABLE [dbo].[Exam](
	[ExamId] [int] IDENTITY(1,1) NOT NULL,
	[ExamName] [nvarchar](1000) NOT NULL,
	[TotalMarks] int NOT NULL,
	[PassingPercentage] int NOT NULL,
	[Instructions] [nvarchar](4000) NOT NULL,
	[Duration] int NOT NULL,
	[CreatedBy] [nvarchar](20) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](20) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[IsActive] [char](1) NOT NULL
) ON [PRIMARY]
GO

IF OBJECT_ID('dbo.QuestionType', 'U') IS NOT NULL 
DROP TABLE [dbo].[QuestionType]
GO
CREATE TABLE [dbo].[QuestionType](
	[QuestionTypeId] [int] NOT NULL,
	[QuestionType] [nvarchar](100) NOT NULL
) ON [PRIMARY]
GO

INSERT INTO QuestionType (QuestionTypeId, QuestionType) Values (1, 'Yes No Selection')
INSERT INTO QuestionType (QuestionTypeId, QuestionType) Values (2, 'Multi-Choice Single Answer')
INSERT INTO QuestionType (QuestionTypeId, QuestionType) Values (3, 'Multi-Choice Multiple Answers')
GO

IF OBJECT_ID('dbo.ComplexityLevel', 'U') IS NOT NULL 
DROP TABLE [dbo].[ComplexityLevel]
GO
CREATE TABLE [dbo].[ComplexityLevel](
	[ComplexityLevelId] [int] NOT NULL,
	[ComplexityLevel] [nvarchar](100) NOT NULL
) ON [PRIMARY]
GO

INSERT INTO ComplexityLevel (ComplexityLevelId, ComplexityLevel) Values (1, 'Easy')
INSERT INTO ComplexityLevel (ComplexityLevelId, ComplexityLevel) Values (2, 'Medium')
INSERT INTO ComplexityLevel (ComplexityLevelId, ComplexityLevel) Values (3, 'Difficult')
GO

IF OBJECT_ID('dbo.Question', 'U') IS NOT NULL 
DROP TABLE [dbo].[Question]
GO
CREATE TABLE [dbo].[Question](
	[QuestionId] [int]  IDENTITY(1,1) NOT NULL,
	[QuestionTypeId] [int] NOT NULL,
	[Question] [nvarchar](1000) NOT NULL,
	[NoOfOption] [int] NOT NULL,
	[MarkValue] [int] NOT NULL,
	[ComplexityLevelId] [int] NOT NULL,
	[CreatedBy] [nvarchar](20) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](20) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[IsActive] [char](1) NOT NULL
) ON [PRIMARY]
GO

IF OBJECT_ID('dbo.QuestionOptions', 'U') IS NOT NULL 
DROP TABLE [dbo].[QuestionOptions]
GO
CREATE TABLE [dbo].[QuestionOptions](
	[QuestionOptionsId] [int]  IDENTITY(1,1) NOT NULL,
	[SlNo] [int] NOT NULL,
	[Option] [nvarchar](1000) NOT NULL,
	[IsCorrect] [int] NOT NULL,
	[CreatedBy] [nvarchar](20) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](20) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[IsActive] [char](1) NOT NULL
) ON [PRIMARY]
GO

IF OBJECT_ID('dbo.ExamQuestion', 'U') IS NOT NULL 
DROP TABLE [dbo].[ExamQuestion]
GO
CREATE TABLE [dbo].[ExamQuestion](
	[ExamQuestionId] [int]  IDENTITY(1,1) NOT NULL,
	[ExamId] [int] NOT NULL,
	[QuestionId] [int] NOT NULL,
	[CreatedBy] [nvarchar](20) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](20) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[IsActive] [char](1) NOT NULL
) ON [PRIMARY]
GO

IF OBJECT_ID('dbo.ExamCandidate', 'U') IS NOT NULL 
DROP TABLE [dbo].[ExamCandidate]
GO
CREATE TABLE [dbo].[ExamCandidate](
	[ExamCandidateId] [int]  IDENTITY(1,1) NOT NULL,
	[ExamId] [int] NOT NULL,
	[CandidateLoginId] [int] NOT NULL,
	[TotalNoofAttempts] [int] NOT NULL,
	[NoofAttempted] [int] NOT NULL,
	[CreatedBy] [nvarchar](20) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](20) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[IsActive] [char](1) NOT NULL
) ON [PRIMARY]
GO

IF OBJECT_ID('dbo.ExamCandidateAttempt', 'U') IS NOT NULL 
DROP TABLE [dbo].[ExamCandidateAttempt]
GO
CREATE TABLE [dbo].[ExamCandidateAttempt](
	[ExamCandidateAttemptId] [int]  IDENTITY(1,1) NOT NULL,
	[Token] varchar(50) NOT NULL,
	[ExamId] [int] NOT NULL,
	[CandidateId] [int] NOT NULL,
	[CandidateName] [nvarchar](100) NULL,
	[CandidateEmailId] [nvarchar](250) NULL,
	[CandidatePhone] [nvarchar](12) NULL,
	[AttemptDate] [Date] NULL,
	[CompleteAttempt] bit NULL,
	[StartTime] [time] NULL,
	[EndTime] [time] NULL,
	[TotalScore] [int] NULL,
	[GainScore] [int] NULL,
	[PercentageScore] [int] NULL,
) ON [PRIMARY]
GO


IF OBJECT_ID('dbo.ExamCandidateAttemptQuestions', 'U') IS NOT NULL 
DROP TABLE [dbo].[ExamCandidateAttemptQuestions]
GO
CREATE TABLE [dbo].[ExamCandidateAttemptQuestions](
	[ExamCandidateAttemptQuestionsId] [int]  IDENTITY(1,1) NOT NULL,
	[ExamCandidateAttemptId] [int] NOT NULL,
	[SeqNo] [int] NOT NULL,
	[QuestionId] [int] NOT NULL,
	[IsAnswerCorrect] [char](1) NOT NULL,
	[GainScore] [int] NOT NULL,
	[AttemptTime] [time] NOT NULL,
) ON [PRIMARY]
GO

IF OBJECT_ID('dbo.ExamCandidateAttemptQuestionAnswers', 'U') IS NOT NULL 
  DROP TABLE [dbo].[ExamCandidateAttemptQuestionAnswers]
GO
CREATE TABLE [dbo].[ExamCandidateAttemptQuestionAnswers](
	[ExamCandidateAttemptQuestionAnswersId] [int]  IDENTITY(1,1) NOT NULL,
	[ExamCandidateAttemptQuestionsId] [int] NOT NULL,
	[SlNo] [int] NOT NULL,
	[QuestionOptionsId] [int] NOT NULL,
	[IsSelected] [char](1) NOT NULL,
) ON [PRIMARY]
GO

IF OBJECT_ID('dbo.CandidateLoginToken', 'U') IS NOT NULL 
  DROP TABLE [dbo].[CandidateLoginToken]
GO
CREATE TABLE [dbo].[CandidateLoginToken](
	[CandidateLoginTokenId] [int]  IDENTITY(1,1) NOT NULL,
	[CandidateLoginId] [int] NOT NULL,
	[Token] varchar(50) NOT NULL,
	[LoginStartTime] [datetime] NOT NULL,
	[LoginEndTime] [datetime] NOT NULL,
) ON [PRIMARY]
GO


IF OBJECT_ID('dbo.AdminLoginToken', 'U') IS NOT NULL 
  DROP TABLE [dbo].[AdminLoginToken]
GO
CREATE TABLE [dbo].[AdminLoginToken](
	[AdminLoginTokenId] [int]  IDENTITY(1,1) NOT NULL,
	[AdminLoginId] [int] NOT NULL,
	[Token] varchar(50) NOT NULL,
	[LoginStartTime] [datetime] NOT NULL,
	[LoginEndTime] [datetime] NOT NULL,
) ON [PRIMARY]
GO