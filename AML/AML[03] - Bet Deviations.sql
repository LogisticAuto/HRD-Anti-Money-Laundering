/*
Department:	Due Diligence
Requestor:  Olga Carrera
Purpose:    AML [3]
Notes:
	-	Updated
		-	8/3/2022
            -   Meeting w/Ralph on 07/29/2022
                -   Remove
                    -   13-18
                    -   25-33
                -   Add
                    -   Multiple payment Methods/Instruments Success Deposits greater than 3 Unique Cards/Accounts, etc...
                        -   Trigger based on 1 trigger per person
*/
----------------------------------------------------------------------------------------------------------------------------
WITH
    Q1  AS
    (
        SELECT
            *
        FROM
            PROD_CLEAN.SPORTSBOOK.ACCOUNTS
        WHERE
            TEST = 0
    )
,   Q5  as
    (
      Select
            az.Account_Id
        ,   Transaction_Date
        ,   First_Bet_Date
        ,   Count(Distinct Bet_Id) Bet_Cnt
        ,   Sum(Amount) Amt
        ,   Count(Distinct Case When Transaction_Code IN ('DEPOSIT','FINANCE_CORRECTION_DEPOSIT') Then Link_Trans_Ref Else Null End) Deposit_Cnt
        ,   Count(Distinct Case When Transaction_Code IN ('DEPOSIT_FAILED') Then Link_Trans_Ref Else Null End) Deposit_Fail_Cnt
        ,   Sum(Case When Transaction_Code IN ('DEPOSIT','FINANCE_CORRECTION_DEPOSIT') Then Amount Else 0 End) Deposit_Amount
        ,   Sum(Case When Transaction_Code = 'FREEBET_AWARDED' Then Amount Else 0 End) Free_Bet_Amount --C
        ,   Sum(Case When Transaction_Code = 'FREEBET_STAKE' Then Amount Else 0 End) Free_Stake_Amount --C
        ,   Sum(Case When Transaction_Code = 'GOODWILL' Then Amount Else 0 End) Goodwill_Amount --C
        ,   Sum(Case When Transaction_Code = 'SETTLEMENT' Then Amount Else 0 End) Settlement_Amount --B
        ,   Sum(Case When Transaction_Code = 'STAKE' Then Amount Else 0 End) Stake_Amount --A
        ,   Sum(Case When Transaction_Code = 'TAX_ON_WINNINGS' Then Amount Else 0 End) Tax_Amount --D
        ,   Sum(Case When Transaction_Code = 'WITHDRAWAL_APPROVED' Then Amount Else 0 End) Withdrawal_Approved_Amount
        ,   Sum(Case When Transaction_Code IN ('WITHDRAWAL_COMPLETED','FINANCE_CORRECTION_WITHDRAWAL') Then Amount Else 0 End) Withdrawal_Completed_Amount
        
        ,   Sum(Case When Transaction_Code = 'SETTLEMENT' Then Amount Else 0 End)+
            Sum(Case When Transaction_Code = 'STAKE' Then Amount Else 0 End)+
            Sum(Case When Transaction_Code = 'FREEBET_STAKE' Then Amount Else 0 End)-
            Sum(Case When Transaction_Code = 'GOODWILL' Then Amount Else 0 End)+
            Sum(Case When Transaction_Code = 'TAX_ON_WINNINGS' Then Amount Else 0 End) NGR
      From
        Prod_Clean.Sportsbook.Account_Statements az
      Left Join
        (
          Select
                Account_Id
            ,   Min(Case When Transaction_Code = 'STAKE' And Transaction_Date Is Not Null Then Transaction_Date Else Null End) First_Bet_Date
          From
            Prod_Clean.Sportsbook.Account_Statements
          Where
            Account_Id In (Select Account_Id From Q1)
          Group By
            Account_Id
        )a on a.Account_Id = az.Account_Id
      Where
            az.Account_Id In (Select Account_Id From Q1)
        AND MONTH(TRANSACTION_DATE) = MONTH(dateadd(MONTH,-1,CURRENT_DATE))
        AND BRAND_CODE != 'HRD_RETAIL'
      Group By
            az.Account_Id
        ,   Transaction_Date
        ,   First_Bet_Date
    )
,   Q7  as
    (
      Select
            Account_Id
      --Betting
      --7 Days
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Bet_Cnt Else Null End) Bet_Cnt_7--Last 7 Days - Bet #
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Bet_Cnt Else Null End)/(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Bet_Perc_7--Last 7 Days - Bet %
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-14,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Bet_Cnt Else Null End) Bet_Cnt_P_7--Prior 7 Days - Bet #
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-14,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Bet_Cnt Else Null End)/(DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) - DateAdd(day,-14,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Bet_Perc_P_7--Prior 7 Days - Bet %
      
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Stake_Amount Else Null End) Bet_Amt_7--Last 7 Days - Bet #
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Stake_Amount Else Null End)/(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Bet_Amt_Perc_7--Last 7 Days - Bet %
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-14,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Stake_Amount Else Null End) Bet_Amt_P_7--Prior 7 Days - Bet #
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-14,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Stake_Amount Else Null End)/(DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) - DateAdd(day,-14,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Bet_Amt_Perc_P_7--Prior 7 Days - Bet %
      --30 Days
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Bet_Cnt Else Null End) Bet_Cnt_30--Last 30 Days - Bet #
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Bet_Cnt Else Null End)/(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Bet_Perc_30--Last 30 Days - Bet %
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-60,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Bet_Cnt Else Null End) Bet_Cnt_P_30--Prior 30 Days - Bet #
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-60,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Bet_Cnt Else Null End)/(DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) - DateAdd(day,-60,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Bet_Perc_P_30--Prior 30 Days - Bet %
      
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Stake_Amount Else Null End) Bet_Amt_30--Last 30 Days - Bet #
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Stake_Amount Else Null End)/(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Bet_Amt_Perc_30--Last 30 Days - Bet %
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-60,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Stake_Amount Else Null End) Bet_Amt_P_30--Prior 30 Days - Bet #
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-60,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Stake_Amount Else Null End)/(DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) - DateAdd(day,-60,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Bet_Amt_Perc_P_30--Prior 30 Days - Bet %
      --90 Days
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Bet_Cnt Else Null End) Bet_Cnt_90--Last 90 Days - Bet #
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Bet_Cnt Else Null End)/(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Bet_Perc_90--Last 90 Days - Bet %
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-180,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Bet_Cnt Else Null End) Bet_Cnt_P_90--Prior 90 Days - Bet #
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-180,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Bet_Cnt Else Null End)/(DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) - DateAdd(day,-180,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Bet_Perc_P_90--Prior 90 Days - Bet %
      
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Stake_Amount Else Null End) Bet_Amt_90--Last 90 Days - Bet #
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Stake_Amount Else Null End)/(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Bet_Amt_Perc_90--Last 90 Days - Bet %
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-180,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Stake_Amount Else Null End) Bet_Amt_P_90--Prior 90 Days - Bet #
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-180,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Stake_Amount Else Null End)/(DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) - DateAdd(day,-180,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Bet_Amt_Perc_P_90--Prior 90 Days - Bet %
      
      --Deposits
      --7 Days
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Cnt Else Null End) Deposit_Cnt_7--Last 7 Days - Bet #
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Cnt Else Null End)/(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Deposit_Perc_7--Last 7 Days - Bet %
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-14,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Deposit_Cnt Else Null End) Deposit_Cnt_P_7--Prior 7 Days - Bet #
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-14,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Deposit_Cnt Else Null End)/(DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) - DateAdd(day,-14,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Deposit_Perc_P_7--Prior 7 Days - Bet %
      
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Amount Else Null End) Deposit_Amt_7--Last 7 Days - Bet #
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Amount Else Null End)/(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Deposit_Amt_Perc_7--Last 7 Days - Bet %
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-14,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Deposit_Amount Else Null End) Deposit_Amt_P_7--Prior 7 Days - Bet #
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-14,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Deposit_Amount Else Null End)/(DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) - DateAdd(day,-14,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Deposit_Amt_Perc_P_7--Prior 7 Days - Bet %
      --30 Days
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Cnt Else Null End) Deposit_Cnt_30--Last 30 Days - Bet #
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Cnt Else Null End)/(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Deposit_Perc_30--Last 30 Days - Bet %
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-60,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Deposit_Cnt Else Null End) Deposit_Cnt_P_30--Prior 30 Days - Bet #
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-60,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Deposit_Cnt Else Null End)/(DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) - DateAdd(day,-60,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Deposit_Perc_P_30--Prior 30 Days - Bet %
      
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Amount Else Null End) Deposit_Amt_30--Last 30 Days - Bet #
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Amount Else Null End)/(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Deposit_Amt_Perc_30--Last 30 Days - Bet %
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-60,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Deposit_Amount Else Null End) Deposit_Amt_P_30--Prior 30 Days - Bet #
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-60,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Deposit_Amount Else Null End)/(DateAdd(day,-30,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) - DateAdd(day,-60,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Deposit_Amt_Perc_P_30--Prior 30 Days - Bet %
      --90 Days
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Cnt Else Null End) Deposit_Cnt_90--Last 90 Days - Bet #
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Cnt Else Null End)/(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Deposit_Perc_90--Last 90 Days - Bet %
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-180,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Deposit_Cnt Else Null End) Deposit_Cnt_P_90--Prior 90 Days - Bet #
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-180,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Deposit_Cnt Else Null End)/(DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) - DateAdd(day,-180,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Deposit_Perc_P_90--Prior 90 Days - Bet %
      
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Amount Else Null End) Deposit_Amt_90--Last 90 Days - Bet #
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Amount Else Null End)/(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Deposit_Amt_Perc_90--Last 90 Days - Bet %
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-180,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Deposit_Amount Else Null End) Deposit_Amt_P_90--Prior 90 Days - Bet #
        ,   Sum(Distinct Case When Transaction_Date Between DateAdd(day,-180,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) Then Deposit_Amount Else Null End)/(DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) - DateAdd(day,-180,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)))) Deposit_Amt_Perc_P_90--Prior 90 Days - Bet %
        
      --Failed Deposits
      --7 Days
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-7,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Fail_Cnt Else Null End) Deposit_Fail_Cnt_7--Last 7 Days - Bet #
//        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-7,Current_Date) And Current_Date Then Deposit_Fail_Cnt Else Null End)/(Current_Date - DateAdd(day,-7,Current_Date)) Deposit_Fail_Perc_7--Last 7 Days - Bet %
//        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-14,Current_Date) And DateAdd(day,-7,Current_Date) Then Deposit_Fail_Cnt Else Null End) Deposit_Fail_Cnt_P_7--Prior 7 Days - Bet #
//        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-14,Current_Date) And DateAdd(day,-7,Current_Date) Then Deposit_Fail_Cnt Else Null End)/(DateAdd(day,-7,Current_Date) - DateAdd(day,-14,Current_Date)) Deposit_Fail_Perc_P_7--Prior 7 Days - Bet %
      
      --30 Days
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-30,Current_Date) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Fail_Cnt Else Null End) Deposit_Fail_Cnt_30--Last 30 Days - Bet #
//        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-30,Current_Date) And Current_Date Then Deposit_Fail_Cnt Else Null End)/(Current_Date - DateAdd(day,-30,Current_Date)) Deposit_Fail_Perc_30--Last 30 Days - Bet %
//        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-60,Current_Date) And DateAdd(day,-30,Current_Date) Then Deposit_Fail_Cnt Else Null End) Deposit_Cnt_P_30--Prior 30 Days - Bet #
//        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-60,Current_Date) And DateAdd(day,-30,Current_Date) Then Deposit_Fail_Cnt Else Null End)/(DateAdd(day,-30,Current_Date) - DateAdd(day,-60,Current_Date)) Deposit_Fail_Perc_P_30--Prior 30 Days - Bet %
      
      --90 Days
        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-90,LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE))) And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Deposit_Fail_Cnt Else Null End) Deposit_Fail_Cnt_90--Last 90 Days - Bet #
//        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-90,Current_Date) And Current_Date Then Deposit_Fail_Cnt Else Null End)/(Current_Date - DateAdd(day,-90,Current_Date)) Deposit_Fail_Perc_90--Last 90 Days - Bet %
//        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-180,Current_Date) And DateAdd(day,-90,Current_Date) Then Deposit_Fail_Cnt Else Null End) Deposit_Fail_Cnt_P_90--Prior 90 Days - Bet #
//        ,   Count(Distinct Case When Transaction_Date Between DateAdd(day,-180,Current_Date) And DateAdd(day,-90,Current_Date) Then Deposit_Fail_Cnt Else Null End)/(DateAdd(day,-90,Current_Date) - DateAdd(day,-180,Current_Date)) Deposit_Fail_Perc_P_90--Prior 90 Days - Bet %
      
        ,   Sum(Case When Transaction_Date Between First_Bet_Date And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Bet_Cnt Else Null End) LT_Bet_Cnt
        ,   Sum(Case When Transaction_Date Between First_Bet_Date And LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) Then Bet_Cnt Else Null End)/NullIfZero(Sum(LAST_DAY(DATEADD(MONTH,-1,CURRENT_DATE)) - First_Bet_Date)) LT_perc
      From
        Q5
      Group By
        Account_Id
    )
,   Q12  as
    (
      Select
            *
        ,   DateDiff('minute',Transaction_Timestamp,Nxt_Bet_Timestamp) Gap
      From
        (
            Select
                    Account_Id
                ,   Bet_Id
                ,   Transaction_Timestamp
                ,   Lead(Bet_Id,1) over (Partition By Account_Id Order By Transaction_Timestamp) Nxt_Bet_Id
                ,   Lead(Transaction_Timestamp,1) over (Partition By Account_Id Order By Transaction_Timestamp) Nxt_Bet_Timestamp
              From
                (
                    Select
                        *
                    From
                        Prod_Clean.Sportsbook.Account_Statements
                    Where
                            Bet_Id Is Not Null
                        AND MONTH(TRANSACTION_DATE) = MONTH(dateadd(MONTH,-1,CURRENT_DATE))
                        And Account_Id In (Select Account_Id From Q1)
                        And Transaction_Code = 'STAKE'
                        AND BRAND_CODE != 'HRD_RETAIL'
                )
              Order By    Account_Id,Transaction_Timestamp
        )
    )
,   Q13  as
    (
      Select
            Account_Id
        ,   Avg(Gap)
        ,   Avg(Case When Transaction_Timestamp Between DateAdd(day,-7,Current_Timestamp) And Current_Timestamp Then Gap Else Null End) Bet_Gap_7--Last 7 Days - Bet #
        ,   Avg(Case When Transaction_Timestamp Between DateAdd(day,-14,Current_Timestamp) And DateAdd(day,-7,Current_Timestamp) Then Gap Else Null End) Bet_Gap_P_7--Last 7 Days - Bet #
//      
        ,   Avg(Case When Transaction_Timestamp Between DateAdd(day,-30,Current_Timestamp) And Current_Timestamp Then Gap Else Null End) Bet_Gap_30--Last 7 Days - Bet #
        ,   Avg(Case When Transaction_Timestamp Between DateAdd(day,-60,Current_Timestamp) And DateAdd(day,-30,Current_Timestamp) Then Gap Else Null End) Bet_Gap_P_30--Last 7 Days - Bet #
//        
        ,   Avg(Case When Transaction_Timestamp Between DateAdd(day,-90,Current_Timestamp) And Current_Timestamp Then Gap Else Null End) Bet_Gap_90--Last 7 Days - Bet #
        ,   Avg(Case When Transaction_Timestamp Between DateAdd(day,-180,Current_Timestamp) And DateAdd(day,-90,Current_Timestamp) Then Gap Else Null End) Bet_Gap_P_90--Last 7 Days - Bet #
      From
        Q12
      Group By
            Account_Id
    )
,   Q14 AS
    (
        SELECT
                ACCOUNT_ID
            ,   Count(Distinct Case When Bet_7_Gap_Flag  > 0 Then Account_Id Else Null End) Num_31--Bet Time frequency (over last rolling 7 days)
            ,   Count(Distinct Case When Bet_30_Gap_Flag > 0 Then Account_Id Else Null End) Num_32--Bet Time frequency (over last rolling 30 days)
            ,   Count(Distinct Case When Bet_90_Gap_Flag > 0 Then Account_Id Else Null End) Num_33--Bet Time frequency (over last rolling 90 days)
            ,   'Section' SECTION
        FROM
            (
                SELECT
                        ACCOUNT_ID
                    ,   Case When ((Bet_Gap_7 - Bet_Gap_P_7)/NullIfZero(Bet_Gap_P_7)) > 0.30 Then 1 Else 0 End Bet_7_Gap_Flag--Frequency
                    ,   Case When ((Bet_Gap_30 - Bet_Gap_P_30)/NullIfZero(Bet_Gap_P_30)) > 0.30 Then 1 Else 0 End Bet_30_Gap_Flag--Frequency
                    ,   Case When ((Bet_Gap_90 - Bet_Gap_P_90)/NullIfZero(Bet_Gap_P_90)) > 0.30 Then 1 Else 0 End Bet_90_Gap_Flag--Frequency
                FROM
                    Q13
            )
        GROUP BY
            ACCOUNT_ID
    )
,   PLAYER_LEVEL    AS
    (
        SELECT
                Q1.Account_Id
        --Deposits
            --7 Day
            ,   Case When Q7.Deposit_Cnt_7 > 0 And ((Q7.Deposit_Cnt_7 - Q7.Deposit_Cnt_P_7)/NullIfZero(Q7.Deposit_Cnt_P_7)) > 3.00 Then 1 Else 0 End Num_19--Frequency
            ,   Case When Q7.Deposit_Amt_7 > 0 And ((Q7.Deposit_Amt_7 - Q7.Deposit_Amt_P_7)/NullIfZero(Q7.Deposit_Amt_P_7)) > 3.00 Then 1 Else 0 End Num_22--Handle
            --30 Day
            ,   Case When Q7.Deposit_Cnt_30 > 0 And ((Q7.Deposit_Cnt_30 - Q7.Deposit_Cnt_P_30)/NullIfZero(Q7.Deposit_Cnt_P_30)) > 10.00 Then 1 Else 0 End Num_20--Frequency
            ,   Case When Q7.Deposit_Amt_30 > 0 And ((Q7.Deposit_Amt_30 - Q7.Deposit_Amt_P_30)/NullIfZero(Q7.Deposit_Amt_P_30)) > 10.00 Then 1 Else 0 End Num_23--Handle
            --90 Day
            ,   Case When Q7.Deposit_Cnt_90 > 0 And ((Q7.Deposit_Cnt_90 - Q7.Deposit_Cnt_P_90)/NullIfZero(Q7.Deposit_Cnt_P_90)) > 20.00 Then 1 Else 0 End Num_21--Frequency
            ,   Case When Q7.Deposit_Amt_90 > 0 And ((Q7.Deposit_Amt_90 - Q7.Deposit_Amt_P_90)/NullIfZero(Q7.Deposit_Amt_P_90)) > 20.00 Then 1 Else 0 End Num_24--Handle
        FROM
            Q1
        LEFT JOIN
            Q7 ON Q1.ACCOUNT_ID = Q7.ACCOUNT_ID
        LEFT JOIN
            Q13 ON Q1.ACCOUNT_ID = Q13.ACCOUNT_ID
    )
SELECT
        *
    ,   Num_19+Num_22+Num_20+Num_23+Num_21+Num_24 TTL_Flag
    ,   'Players deviating from their bet history' RULE
FROM
    PLAYER_LEVEL
WHERE
    Num_19+Num_22+Num_20+Num_23+Num_21+Num_24 > 2