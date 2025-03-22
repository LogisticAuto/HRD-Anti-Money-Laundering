WITH
    Q1  AS
    (
        SELECT
            ACCOUNT_ID
        FROM
            PROD_CLEAN.SPORTSBOOK.ACCOUNTS
        WHERE
                TEST = 0
            AND TO_DATE(HRD_UTILITIES.PUBLIC.EST_TIME(CREATION_TIMESTAMP)) >= '2022-02-21'
    )
,   Q2  AS
    (
        SELECT
                ACCOUNT_ID
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   CREATED
            ,   hrd_utilities.public.hrd_sync_decrypt_prod(GATEWAY) GATEWAY
            -- ,   DEPOSIT_ID
            ,   MODIFIED_DATE
            ,   hrd_utilities.public.hrd_sync_decrypt_prod(PAYMENT_BRAND) PAYMENT_BRAND
            ,   STATUS
            ,   TRANS_REF
        --Credit Card
            ,   CREDIT_CARD_CARD_TYPE
            ,   CREDIT_CARD_DEBIT
            ,   CREDIT_CARD_EXPIRATION_DATE
            ,   CREDIT_CARD_ISSUING_BANK
            ,   CREDIT_CARD_MASKED_NUMBER
            ,   PAYMENT_INSTRUMENT_TYPE
            ,   CUSTOMER_CUSTOMER_ID
            ,   CUSTOMER_EMAIL
            ,   RESPONSE_JSON
        --Venmo
            ,   RESPONSE_JSON:venmoAccountDetails:username::string Venmo_UserId
            ,   RESPONSE_JSON:venmoAccountDetails:username::string Venmo_Username
            ,   'BRAINTREE_DEPOSITS' TBL
        FROM
            PROD_CLEAN.SPORTSBOOK.DEPOSITS_BRAINTREE
        WHERE
                ACCOUNT_ID IN (SELECT ACCOUNT_ID FROM Q1)
            AND MONTH(CREATED) = MONTH(dateadd(MONTH,-1,CURRENT_DATE))
            AND STATUS IN ('DEPOSIT_SUCCESS','WITHDRAWAL_COMPLETED')
            AND hrd_utilities.public.hrd_sync_decrypt_prod(PAYMENT_BRAND) != 'CARD'
            -- AND ORDER_ID = '214794230001301'
    )SELECT * FROM Q2 LIMIT 100
,   Q3  AS
    (
        SELECT
                ACCOUNT_ID
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   CREATED
            ,   DESCRIPTION
            ,   hrd_utilities.public.hrd_sync_decrypt_prod(GATEWAY) GATEWAY
            -- ,   DEPOSIT_ID
            ,   LINK_TRANS_REF
            ,   MODIFIED_DATE
            ,   hrd_utilities.public.hrd_sync_decrypt_prod(PAYMENT_BRAND) PAYMENT_BRAND
            ,   STATUS
            ,   TRANS_REF
            ,   ADDITIONAL_DATA
            ,   ADDITIONAL_DATA[0].key::string key0
            ,   ADDITIONAL_DATA[0].value::string value0
            ,   ADDITIONAL_DATA[1].key::string key1
            ,   ADDITIONAL_DATA[1].value::string value1
            ,   ADDITIONAL_DATA[2].key::string key2
            ,   ADDITIONAL_DATA[2].value::string value2
            ,   ADDITIONAL_DATA[3].key::string key3
            ,   ADDITIONAL_DATA[3].value::string value3
            ,   ADDITIONAL_DATA[4].key::string key4
            ,   ADDITIONAL_DATA[4].value::string value4
            ,   ADDITIONAL_DATA[5].key::string key5
            ,   ADDITIONAL_DATA[5].value::string value5
            ,   ADDITIONAL_DATA[6].key::string key6
            ,   ADDITIONAL_DATA[6].value::string value6
            ,   'MAZOOMA_DEPOSITS' TBL
        FROM
            PROD_CLEAN.SPORTSBOOK.DEPOSITS_MAZOOMA
        WHERE
                ACCOUNT_ID IN (SELECT ACCOUNT_ID FROM Q1)
            AND MONTH(CREATED) = MONTH(dateadd(MONTH,-1,CURRENT_DATE))
            AND STATUS IN ('DEPOSIT_SUCCESS','WITHDRAWAL_COMPLETED')
    )--SELECT * FROM Q3
,   Q4  AS
    (
        SELECT
                ACCOUNT_ID
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   SUBMITTED_AT CREATED
            ,   DESCRIPTION
            ,   hrd_utilities.public.hrd_sync_decrypt_prod(GATEWAY) GATEWAY
            ,   INITIATED_AT
            ,   LINK_TRANS_REF
            ,   MODIFIED_DATE
            ,   hrd_utilities.public.hrd_sync_decrypt_prod(PAYMENT_BRAND) PAYMENT_BRAND
            ,   STATUS
            ,   TRANSACTION_REF TRANS_REF
            ,   hrd_utilities.public.hrd_sync_decrypt_prod(RESPONSE_JSON) RESPONSE_JSON
            ,   'BRAINTREE_WITHDRAWALS' TBL
        FROM
            PROD_CLEAN.SPORTSBOOK.WITHDRAWALS_BRAINTREE
        WHERE
                ACCOUNT_ID IN (SELECT ACCOUNT_ID FROM Q1)
            AND MONTH(SUBMITTED_AT) = MONTH(dateadd(MONTH,-1,CURRENT_DATE))
            AND STATUS IN ('DEPOSIT_SUCCESS','WITHDRAWAL_COMPLETED')
    )--SELECT * FROM Q4
,   Q5  AS
    (
        SELECT
                ACCOUNT_ID
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   SUBMITTED_AT CREATED
            ,   DESCRIPTION
            ,   hrd_utilities.public.hrd_sync_decrypt_prod(GATEWAY) GATEWAY
            ,   INITIATED_AT
            ,   LINK_TRANS_REF TRANS_REF
            ,   MODIFIED_TIMESTAMP
            ,   MODIFIED_DATE
            ,   hrd_utilities.public.hrd_sync_decrypt_prod(PAYMENT_BRAND) PAYMENT_BRAND
            -- ,   hrd_utilities.public.hrd_sync_decrypt_prod(RESPONSE_JSON) RESPONSE_JSON
            ,   STATUS
            ,   ACCOUNT_LABEL
            ,   FINAME
            ,   PAYMENT_METHOD
            ,   'MAZOOMA_WITHDRAWALS' TBL
        FROM
            PROD_CLEAN.SPORTSBOOK.WITHDRAWALS_MAZOOMA
        WHERE
                ACCOUNT_ID IN (SELECT ACCOUNT_ID FROM Q1)
            AND MONTH(SUBMITTED_AT) = MONTH(dateadd(MONTH,-1,CURRENT_DATE))
            AND STATUS IN ('DEPOSIT_SUCCESS','WITHDRAWAL_COMPLETED')
    )
,   COMBINE AS
    (
        SELECT DISTINCT
                ACCOUNT_ID
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   CREATED
            ,   NULL DESCRIPTION
            ,   GATEWAY
            ,   MODIFIED_DATE
            ,   PAYMENT_BRAND
            ,   STATUS
            ,   TRANS_REF
        --Credit Card
            ,   MAX(CREDIT_CARD_CARD_TYPE) CREDIT_CARD_CARD_TYPE
            ,   MAX(CREDIT_CARD_DEBIT) CREDIT_CARD_DEBIT
            ,   MAX(CREDIT_CARD_EXPIRATION_DATE) CREDIT_CARD_EXPIRATION_DATE
            ,   MAX(CREDIT_CARD_ISSUING_BANK) CREDIT_CARD_ISSUING_BANK
            ,   MAX(CREDIT_CARD_MASKED_NUMBER) CREDIT_CARD_MASKED_NUMBER
            ,   MAX(PAYMENT_INSTRUMENT_TYPE) PAYMENT_INSTRUMENT_TYPE
            ,   MAX(CUSTOMER_CUSTOMER_ID) CUSTOMER_CUSTOMER_ID
            ,   MAX(CUSTOMER_EMAIL) CUSTOMER_EMAIL
        --Venmo
            ,   MAX(Venmo_UserId) Venmo_UserId
            ,   MAX(Venmo_Username) Venmo_Username
            ,   MAX(TBL) TBL
        --Bank Accounts
            ,   MAX(NULL) BANK_NBR
            ,   MAX(NULL) BANK_NAME
            FROM
                Q2
            GROUP BY
                ACCOUNT_ID
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   CREATED
            ,   DESCRIPTION
            ,   GATEWAY
            ,   MODIFIED_DATE
            ,   PAYMENT_BRAND
            ,   STATUS
            ,   TRANS_REF
        UNION ALL
            SELECT
                ACCOUNT_ID
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   CREATED        
            ,   DESCRIPTION
            ,   GATEWAY
            ,   MODIFIED_DATE
            ,   PAYMENT_BRAND
            ,   STATUS
            ,   TRANS_REF
        --Credit Card
            ,   MAX(NULL) CREDIT_CARD_CARD_TYPE
            ,   MAX(NULL) CREDIT_CARD_DEBIT
            ,   MAX(NULL) CREDIT_CARD_EXPIRATION_DATE
            ,   MAX(NULL) CREDIT_CARD_ISSUING_BANK
            ,   MAX(NULL) CREDIT_CARD_MASKED_NUMBER
            ,   MAX(NULL) PAYMENT_INSTRUMENT_TYPE
            ,   MAX(NULL) CUSTOMER_CUSTOMER_ID
            ,   MAX(NULL) CUSTOMER_EMAIL
        --Venmo
            ,   MAX(NULL) Venmo_UserId
            ,   MAX(NULL) Venmo_Username
            ,   MAX(TBL) TBL
        --Bank Accounts
            ,   MAX(CASE
                    WHEN key0  = 'accountLabel' THEN value0
                    WHEN key1  = 'accountLabel' THEN value1
                    WHEN key2  = 'accountLabel' THEN value2
                    WHEN key3  = 'accountLabel' THEN value3
                    WHEN key4  = 'accountLabel' THEN value4
                    WHEN key5  = 'accountLabel' THEN value5
                    WHEN key6  = 'accountLabel' THEN value6
                    ELSE NULL
                END) BANK_NBR
            ,   MAX(CASE
                    WHEN key0  = 'fiName' THEN value0
                    WHEN key1  = 'fiName' THEN value1
                    WHEN key2  = 'fiName' THEN value2
                    WHEN key3  = 'fiName' THEN value3
                    WHEN key4  = 'fiName' THEN value4
                    WHEN key5  = 'fiName' THEN value5
                    WHEN key6  = 'fiName' THEN value6
                    ELSE NULL
                END) BANK_NAME
            FROM
                Q3
            GROUP BY
                ACCOUNT_ID
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   CREATED
            ,   DESCRIPTION
            ,   GATEWAY
            ,   MODIFIED_DATE
            ,   PAYMENT_BRAND
            ,   STATUS
            ,   TRANS_REF
        UNION ALL
            SELECT
                ACCOUNT_ID
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   CREATED
            ,   DESCRIPTION
            ,   GATEWAY
            ,   MODIFIED_DATE
            ,   PAYMENT_BRAND
            ,   STATUS
            ,   TRANS_REF
        --Credit Card
            ,   MAX(NULL) CREDIT_CARD_CARD_TYPE
            ,   MAX(NULL) CREDIT_CARD_DEBIT
            ,   MAX(NULL) CREDIT_CARD_EXPIRATION_DATE
            ,   MAX(NULL) CREDIT_CARD_ISSUING_BANK
            ,   MAX(NULL) CREDIT_CARD_MASKED_NUMBER
            ,   MAX(NULL) PAYMENT_INSTRUMENT_TYPE
            ,   MAX(NULL) CUSTOMER_CUSTOMER_ID
            ,   MAX(NULL) CUSTOMER_EMAIL
        --Venmo
            ,   MAX(NULL) Venmo_UserId
            ,   MAX(NULL) Venmo_Username
            ,   MAX(TBL) TBL
        --Bank Accounts
            ,   MAX(NULL) BANK_NBR
            ,   MAX(NULL) BANK_NAME
            FROM
                Q4
            GROUP BY
                ACCOUNT_ID
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   CREATED
            ,   DESCRIPTION
            ,   GATEWAY
            ,   MODIFIED_DATE
            ,   PAYMENT_BRAND
            ,   STATUS
            ,   TRANS_REF
        UNION ALL
            SELECT
                ACCOUNT_ID
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   CREATED
            ,   DESCRIPTION
            ,   GATEWAY
            ,   MODIFIED_DATE
            ,   PAYMENT_BRAND
            ,   STATUS
            ,   TRANS_REF
        --Credit Card
            ,   MAX(NULL) CREDIT_CARD_CARD_TYPE
            ,   MAX(NULL) CREDIT_CARD_DEBIT
            ,   MAX(NULL) CREDIT_CARD_EXPIRATION_DATE
            ,   MAX(NULL) CREDIT_CARD_ISSUING_BANK
            ,   MAX(NULL) CREDIT_CARD_MASKED_NUMBER
            ,   MAX(NULL) PAYMENT_INSTRUMENT_TYPE
            ,   MAX(NULL) CUSTOMER_CUSTOMER_ID
            ,   MAX(NULL) CUSTOMER_EMAIL
        --Venmo
            ,   MAX(NULL) Venmo_UserId
            ,   MAX(NULL) Venmo_Username
            ,   MAX(TBL) TBL
        --Bank Accounts
            ,   MAX(ACCOUNT_LABEL) BANK_NBR
            ,   MAX(FINAME) BANK_NAME
            FROM
                Q5
            GROUP BY
                ACCOUNT_ID
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   CREATED
            ,   DESCRIPTION
            ,   GATEWAY
            ,   MODIFIED_DATE
            ,   PAYMENT_BRAND
            ,   STATUS
            ,   TRANS_REF
    )--SELECT * FROM COMBINE
,   FINAL   AS
    (
        SELECT DISTINCT
                -- *
                ACCOUNT_ID
            ,   STATUS
            ,   PAYMENT_BRAND
            -- ,   CREATED
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   TRANS_REF
            ,   CREDIT_CARD_MASKED_NUMBER
            ,   CUSTOMER_EMAIL PAYPAL_EMAIL
            ,   VENMO_USERNAME
            ,   BANK_NAME
            ,   BANK_NBR
        FROM
            COMBINE
    )
,   Q10 AS
    (
        SELECT DISTINCT
                ACCOUNT_ID
        --PAYPAL
            ,   CASE WHEN STATUS IN ('DEPOSIT_SUCCESS','DEPOSIT_FAILED')            THEN PAYPAL_EMAIL ELSE NULL END D_PAYPAL
            ,   CASE WHEN STATUS IN ('WITHDRAWAL_COMPLETED','WITHDRAWAL_REJECTED')  THEN PAYPAL_EMAIL ELSE NULL END W_PAYPAL
        --VENMO
            ,   CASE WHEN STATUS IN ('DEPOSIT_SUCCESS','DEPOSIT_FAILED')            THEN VENMO_USERNAME ELSE NULL END D_VENMO
            ,   CASE WHEN STATUS IN ('WITHDRAWAL_COMPLETED','WITHDRAWAL_REJECTED')  THEN VENMO_USERNAME ELSE NULL END W_VENMO
        --BANK
            ,   CASE WHEN STATUS IN ('DEPOSIT_SUCCESS','DEPOSIT_FAILED')            THEN BANK_NBR ELSE NULL END D_BANK
            ,   CASE WHEN STATUS IN ('WITHDRAWAL_COMPLETED','WITHDRAWAL_REJECTED')  THEN BANK_NBR ELSE NULL END W_BANK
        FROM
            FINAL
        ORDER BY
            ACCOUNT_ID
    )--SELECT * FROM Q10
,   Q11 AS
    (
        SELECT
                ACCOUNT_ID
            --PAYPAL
            ,   LISTAGG(D_PAYPAL, ', ') D_PAYPAL
            ,   LISTAGG(W_PAYPAL, ', ') W_PAYPAL
            --VENMO
            ,   LISTAGG(D_VENMO, ', ') D_VENMO
            ,   LISTAGG(W_VENMO, ', ') W_VENMO
            --BANK
            ,   LISTAGG(D_BANK, ', ') D_BANK
            ,   LISTAGG(W_BANK, ', ') W_BANK
        FROM
            Q10
        GROUP BY
            ACCOUNT_ID
    )--SELECT * FROM Q11
,   Q12 AS
    (
        SELECT
                ACCOUNT_ID
            ,   CASE
                    WHEN W_PAYPAL = '' THEN 'No Withdrawal'
                    WHEN D_PAYPAL = '' THEN 'No Deposit'
                    WHEN D_PAYPAL != W_PAYPAL THEN 'DEPOSIT ACCOUNTS '||D_PAYPAL||' --> WITHDRAWAL ACCOUNTS '||W_PAYPAL
                    ELSE 'Matched'
                END PAYPAL
            ,   CASE
                    WHEN W_VENMO = '' THEN 'No Withdrawal'
                    WHEN D_VENMO = '' THEN 'No Deposit'
                    WHEN D_VENMO   != W_VENMO  THEN 'DEPOSIT ACCOUNTS '||D_VENMO||' --> WITHDRAWAL ACCOUNTS '||W_VENMO
                    ELSE 'Matched'
                END VENMO
            ,   CASE
                    WHEN W_BANK = '' THEN 'No Withdrawal'
                    WHEN D_BANK = '' THEN 'No Deposit'
                    WHEN D_BANK != W_BANK THEN 'DEPOSIT ACCOUNTS '||D_BANK||' --> WITHDRAWAL ACCOUNTS '||W_BANK
                    ELSE 'Matched'
                END BANK
            -- ,   CASE WHEN W_PAYPAL_EMAIL != D_PAYPAL_EMAIL THEN 1 ELSE 0 END PAYPAL
        FROM
            Q11
    )
,   Q13a    AS
    (
        SELECT
                ACCOUNT_ID
            ,   STATUS
            ,   PAYMENT_BRAND
            ,   AMOUNT
            ,   COMPLETED_AT
            ,   TRANS_REF
            ,   CASE WHEN BANK_NAME IS NOT NULL THEN BANK_NAME ELSE NULL END INSTITUTION
            ,   CASE
                    WHEN PAYMENT_BRAND = 'PAYPAL'     AND PAYPAL_EMAIL IS NOT NULL THEN PAYPAL_EMAIL
                    WHEN PAYMENT_BRAND = 'VENMO'      AND VENMO_USERNAME IS NOT NULL THEN VENMO_USERNAME
                    WHEN PAYMENT_BRAND IN ('MAZOOMA','ACCOUNT')   AND BANK_NBR IS NOT NULL THEN BANK_NBR
                    ELSE NULL
                END ACCOUNT_INFO
        FROM
            FINAL
    )
,   Q13b_1    AS
    (
        SELECT
                ACCOUNT_ID
            ,   ARRAY_AGG(ACCOUNT_INFO) WITHIN GROUP (ORDER BY ACCOUNT_ID) ACCOUNT_ARRAY
            ,   'DEPOSIT_ACCOUNTS' ACCOUNT_LIST
        FROM
            (
                SELECT DISTINCT
                        ACCOUNT_ID
                    ,   CASE
                            WHEN PAYMENT_BRAND IN ('MAZOOMA','ACCOUNT') THEN RIGHT(ACCOUNT_INFO,4)
                            ELSE ACCOUNT_INFO
                        END ACCOUNT_INFO
                FROM
                    Q13a
                WHERE
                    STATUS IN ('DEPOSIT_SUCCESS')
            )
            Q13a
        GROUP BY
            ACCOUNT_ID
    )
,   Q13b_2  AS
    (
        SELECT
                ACCOUNT_ID
            ,   ARRAY_AGG(ACCOUNT_INFO) WITHIN GROUP (ORDER BY ACCOUNT_ID) ACCOUNT_ARRAY
            ,   'WITHDRAWAL_ACCOUNTS' ACCOUNT_LIST
        FROM
            (
                SELECT DISTINCT
                        ACCOUNT_ID
                    ,   CASE
                            WHEN PAYMENT_BRAND IN ('MAZOOMA','ACCOUNT') THEN RIGHT(ACCOUNT_INFO,4)
                            ELSE ACCOUNT_INFO
                        END ACCOUNT_INFO
                FROM
                    Q13a
                WHERE
                    STATUS IN ('WITHDRAWAL_COMPLETED')
            )
            Q13a
        GROUP BY
            ACCOUNT_ID
    )
,   Q13c AS
    (
        SELECT
                Q13b_1.ACCOUNT_ID
            ,   Q13b_1.ACCOUNT_ARRAY ACCOUNT_LIST_DEPOSITS
            ,   Q13b_2.ACCOUNT_ARRAY ACCOUNT_LIST_WITHDRAWALS
            ,   ARRAY_INTERSECTION(Q13b_1.ACCOUNT_ARRAY,Q13b_2.ACCOUNT_ARRAY) INTERSECTION
            -- --PAYPAL
            -- ,   D_PAYPAL
            -- ,   W_PAYPAL
            -- ,   CASE WHEN D_PAYPAL = W_PAYPAL THEN 'MATCH' ELSE 'NO MATCH' END PAYPAL_CHECK
            -- --VENMO
            -- ,   D_VENMO
            -- ,   W_VENMO
            -- ,   CASE WHEN D_VENMO  = W_VENMO  THEN 'MATCH' ELSE 'NO MATCH' END VENMO_CHECK
            -- --BANK
            -- ,   D_BANK
            -- ,   W_BANK
            -- ,   CASE WHEN D_BANK   = W_BANK   THEN 'MATCH' ELSE 'NO MATCH' END BANK_CHECK
        FROM
            Q13b_1
        LEFT JOIN
            Q13B_2 ON Q13b_1.ACCOUNT_ID = Q13b_2.ACCOUNT_ID
        WHERE
                INTERSECTION IS NOT NULL
            AND ACCOUNT_LIST_WITHDRAWALS != []
            AND INTERSECTION = []
    )
,   Q14 AS
    (
        SELECT
            *
        FROM
            Q13a
        WHERE
            ACCOUNT_ID IN (SELECT ACCOUNT_ID FROM Q13c)
    )
        SELECT
                *
            ,   '9. Deposit Is Different Than Withdrawals' RULE
        FROM
            -- Q13c
            Q14