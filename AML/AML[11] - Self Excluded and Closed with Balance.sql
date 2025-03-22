/*
Department: Anti-MOney Laundering
Requestor:  Olga Carrera
Purpose:    AML Triggers
Notes:      Questions:
            -   Do we want to filter on Last Modified or Exclusion Date
*/
WITH
    Q1  AS
    (
      SELECT DISTINCT
            A.ACCOUNT_ID
        ,   S.TYPE
        ,   S.EXCLUSION_OR_TIMEOUT_UNTIL
        ,   LAST_VALUE(S.LAST_MODIFIED_DATE) OVER (PARTITION BY S.ACCOUNT_ID ORDER BY S.LAST_MODIFIED_DATE) LAST_MODIFIED_DATE
        ,   AZ.TRANSACTION_TIMESTAMP
        ,   A.STATUS
        ,   AZ.BALANCE
        ,   A.CHANNEL_CODE
      FROM
        PROD_CLEAN.SPORTSBOOK.ACCOUNTS A
      LEFT JOIN
        (
            SELECT DISTINCT
                    ACCOUNT_ID
                ,   TRANSACTION_CODE
                ,   TRANSACTION_TIMESTAMP
                ,   LAST_VALUE(BALANCE) OVER (PARTITION BY ACCOUNT_ID ORDER BY TRANSACTION_TIMESTAMP) BALANCE
                ,   LAST_VALUE(TRANSACTION_TIMESTAMP) OVER (PARTITION BY ACCOUNT_ID ORDER BY TRANSACTION_TIMESTAMP) TRANSACTION_TIMESTAMP_LST
            FROM
                PROD_CLEAN.SPORTSBOOK.ACCOUNT_STATEMENTS
            WHERE
                    MONTH(TRANSACTION_DATE) = MONTH(DATEADD(MONTH,-1,CURRENT_DATE))
                AND FUND_TYPE = 'CASH'
                AND EFFECTS_BALANCE = 'TRUE'
                AND BRAND_CODE != 'HRD_RETAIL'
        ) AZ
        ON A.ACCOUNT_ID = AZ.ACCOUNT_ID
      LEFT JOIN
        (
            SELECT DISTINCT
                    ACCOUNT_ID
                ,   TYPE
                ,   LAST_MODIFIED_DATE
                ,   EFFECTIVE_FROM_DATE
                ,   EXCLUSION_OR_TIMEOUT_UNTIL
            FROM
                PROD_CLEAN.SPORTSBOOK.SELF_LIMITS_HISTORY
            WHERE
                    EXCLUSION_OR_TIMEOUT_UNTIL IS NOT NULL
                AND EFFECTIVE_FROM_DATE IS NOT NULL
        ) S
        ON A.ACCOUNT_ID = S.ACCOUNT_ID
      WHERE
            A.TEST = 0
      ORDER BY
            A.ACCOUNT_ID
        ,   S.TYPE
  )
,   Q2  AS
    (
      SELECT DISTINCT
            CHANNEL_CODE
        ,   ACCOUNT_ID
        ,   STATUS
        ,   BALANCE
        ,   EXCLUSION_OR_TIMEOUT_UNTIL
        ,   '11. Self Excluded & Closed Accounts with a Balance' RULE
        -- ,   TO_DATE(TRANSACTION_TIMESTAMP) TRANSACTION_DATE
      FROM
        Q1
      WHERE
        --Balance > 0 for 6+ Days
            (
              --       DATEDIFF(day,TRANSACTION_TIMESTAMP,CURRENT_TIMESTAMP) > 6
              -- AND   
                BALANCE > 0
            )
        --Player Account Currently Excluded or Closed
        AND
            (
                    EXCLUSION_OR_TIMEOUT_UNTIL > CURRENT_DATE
              OR    STATUS = 'CLOSED'
            ) 
  )SELECT * FROM Q2