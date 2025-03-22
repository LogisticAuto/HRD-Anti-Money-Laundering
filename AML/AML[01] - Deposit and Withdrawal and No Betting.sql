/*
Department: Anti-Money Laundering
Requestor:  Jason Garrandes
Purpose:    AML Triggers
Section:    Deposit and Withdrawal with no Bet Activity
Notes:
*/
With
    Q1  as
    (
      Select
            Q1.Account_ID
        ,   MONTH(Q2.TRANSACTION_DATE) A
        ,   MONTH(dateadd(MONTH,-1,CURRENT_DATE)) B
        ,   Q2.Transaction_Code
        ,   Q2.Link_Trans_Ref
        ,   Q1.Status
        ,   Q1.Channel_Code
        ,   Q2.Transaction_Timestamp
        ,   Lead(Q2.Transaction_Code,1) over (Partition By Q2.Account_Id Order By Q2.Transaction_Timestamp) Nxt_Transaction_Code
        ,   Lead(Q2.Link_Trans_Ref,1) over (Partition By Q2.Account_Id Order By Q2.Transaction_Timestamp) Nxt_Transaction_ID
        ,   Lead(Q2.Transaction_Timestamp,1) over (Partition By Q2.Account_Id Order By Q2.Transaction_Timestamp) Nxt_Transaction_Timestamp
      From
        "PROD_CLEAN"."SPORTSBOOK"."ACCOUNTS" Q1
      Right Join
        "PROD_CLEAN"."SPORTSBOOK"."ACCOUNT_STATEMENTS" Q2
            on Q1.Account_ID = Q2.Account_ID
      Where
            Q1.Test = 0
        AND Q2.BRAND_CODE != 'HRD_RETAIL'
        And Q2.Transaction_Code In ('DEPOSIT','WITHDRAWAL_COMPLETED','STAKE')
        AND MONTH(TRANSACTION_DATE) = MONTH(dateadd(MONTH,-1,CURRENT_DATE))
    )
,   Q2  as
    (
      Select    
            Account_Id
        ,   Status
        ,   Channel_Code
      --Deposit
        ,   Transaction_Code
        ,   Link_Trans_Ref Transaction_Id
        ,   Transaction_Timestamp
      --Withdrawal
        ,   Nxt_Transaction_Code
        ,   Case When Nxt_Transaction_Code = 'WITHDRAWAL_COMPLETED' Then Nxt_Transaction_ID Else Null End Nxt_Transaction_Id
        ,   Nxt_Transaction_Timestamp
      From
        Q1
      Where
            Transaction_Code = 'DEPOSIT'
        And Nxt_Transaction_Code = 'WITHDRAWAL_COMPLETED'
Union All
      Select    
            Account_Id
        ,   Status
        ,   Channel_Code
      --Deposit
        ,   Case When Transaction_Code = 'DEPOSIT' Then Transaction_Code Else Null End Transaction_Code
        ,   Case When Transaction_Code = 'DEPOSIT' Then Link_Trans_Ref Else Null End  Transaction_Id
        ,   Case When Transaction_Code = 'DEPOSIT' Then Transaction_Timestamp Else Null End Transaction_Timestamp
      --Withdrawal
        ,   Case When Transaction_Code = 'WITHDRAWAL_COMPLETED' Then Transaction_Code Else Null End Nxt_Transaction_Code
        ,   Case When Transaction_Code = 'WITHDRAWAL_COMPLETED' Then Link_Trans_Ref Else Null End  Nxt_Transaction_Id
        ,   Case When Transaction_Code = 'WITHDRAWAL_COMPLETED' Then Transaction_Timestamp Else Null End Nxt_Transaction_Timestamp
//        ,   Rank() over (Partition By Account_Id,Link_Trans_Ref Order By Transaction_Timestamp) Instance
      From
        Q1
      Where
            Account_Id Not In (Select Account_Id From Prod_Clean.Sportsbook.Bets)
    )
,   Q3  as
    (
      Select Distinct
            Account_Id
        ,   Status
        ,   Channel_Code
        ,   'DEPOSIT' Transaction_Code
        ,   Transaction_Id
      From
        Q2
      Where
        Transaction_Id Is Not Null
      Union All
      Select Distinct
            Account_Id
        ,   Status
        ,   Channel_Code
        ,   'WITHDRAWAL_COMPLETED' Transaction_Code
        ,   Nxt_Transaction_Id Transaction_Id
      From
        Q2
      Where
        Nxt_Transaction_Id Is Not Null
    )
,   Q4  as
    (
      Select
            Account_Id
        ,   Status
        ,   Channel_Code
        ,   Transaction_Code
        ,   Count(Distinct Case When Transaction_Code = 'DEPOSIT' Then Transaction_Id Else Null End) D_Transactions
        ,   Count(Distinct Case When Transaction_Code = 'WITHDRAWAL_COMPLETED' Then Transaction_Id Else Null End) W_Transactions
      From
        Q3
      Group By
            Account_Id
        ,   Status
        ,   Channel_Code
        ,   Transaction_Code
    )
,   Account_Details  as
    (
      Select
            Account_Id
        ,   Status
        ,   Channel_Code
        ,   Max(D_Transactions) Deposits
        ,   Max(W_Transactions) Withdrawals
      From
        Q4
      Group By
            Account_Id
        ,   Status
        ,   Channel_Code
      Having
            Deposits    >=  2
        And Withdrawals >=  2
    )--Select * From Account_Details
,   Summary  as
    (
      Select
            Status
        -- ,   Channel_Code
        ,   Count(Distinct Account_Id)      Player_Accounts
      From
        Account_Details
      Group By
            Status
        -- ,   Channel_Code
    )
Select * From
    Account_Details
//   Summary