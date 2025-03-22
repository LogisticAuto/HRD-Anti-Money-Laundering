/*
Department: Anti-Money Laundering
Requestor:  Olga Carrera
Purpose:    AML Triggers
Notes:      [5] Players with balance over $3,999 with no betting activity within 60 days
            Update:
                Chris Version added to Tableau
*/
WITH
    Q1  AS
    (
        SELECT
                A.ACCOUNT_ID
            ,   A.STATUS
            ,   A.CHANNEL_CODE
            ,   AZ.BALANCE
            ,   AZ.TRANSACTION_CODE
            ,   AZ.TRANSACTION_TIMESTAMP
            ,   AZ.TRANSACTION_DATE
        FROM
            PROD_CLEAN.SPORTSBOOK.ACCOUNTS A
        LEFT JOIN
            (
                SELECT
                        ACCOUNT_ID
                    ,   TRANSACTION_DATE
                    ,   TRANSACTION_CODE
                    ,   TRANSACTION_TIMESTAMP
                    ,   LAST_VALUE(BALANCE) OVER (PARTITION BY ACCOUNT_ID ORDER BY TRANSACTION_TIMESTAMP) BALANCE
                FROM
                    PROD_CLEAN.SPORTSBOOK.ACCOUNT_STATEMENTS
                WHERE
                        FUND_TYPE = 'CASH'
                    AND EFFECTS_BALANCE = 'TRUE'
                    AND BRAND_CODE != 'HRD_RETAIL'
            ) AZ
            ON  A.ACCOUNT_ID = AZ.ACCOUNT_ID
        WHERE
                A.TEST = 0
            AND MONTH(AZ.TRANSACTION_DATE) = MONTH(dateadd(MONTH,-1,CURRENT_DATE))
            AND AZ.BALANCE > 3999
    )
,   Q2  AS
    (
        SELECT
                ACCOUNT_ID
            ,   DATEADD(day,-60,BET_PLACED_DATETIME) BET_PLACED_DATETIME
        FROM
            PROD_CLEAN.SPORTSBOOK.BETS
        WHERE
            BET_PLACED_DATETIME <=  DATEADD(day,60,BET_PLACED_DATETIME)
    )
,   Q3  AS
    (
        SELECT DISTINCT
                CHANNEL_CODE
            ,   ACCOUNT_ID
            ,   STATUS
            ,   BALANCE
        FROM
            Q1
        WHERE
            ACCOUNT_ID NOT IN (SELECT ACCOUNT_ID FROM Q2)
            AND CHANNEL_CODE != 'FLORIDA_ONLINE'
    )
SELECT * FROM Q3