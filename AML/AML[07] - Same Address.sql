/*
Department: Anti-Money Laundering
Purpose:    AML Triggers
Requestor:  Olga Carrera
Notes:      Update 04/06/2022
                2 or more players with the same adddress
                Count of Player Accounts for unique address including City
            Update 06/10/2022
                [Talk to Balious about Suite #]
*/
WITH
    Q1  AS
    (
        SELECT DISTINCT
                CHANNEL_CODE
            ,   ACCOUNT_ID
            ,   LAST_LOGIN_TIME
            ,   NVL(HRD_UTILITIES.PUBLIC.HRD_SYNC_DECRYPT_PROD(CONTACT_ADDRESS),'')||
                CASE WHEN HRD_UTILITIES.PUBLIC.HRD_SYNC_DECRYPT_PROD(CONTACT_ADDRESS_2) IS NOT NULL THEN ' Unit ' ELSE '' END||
                NVL(HRD_UTILITIES.PUBLIC.HRD_SYNC_DECRYPT_PROD(CONTACT_ADDRESS_2),'')||' '||
                NVL(HRD_UTILITIES.PUBLIC.HRD_SYNC_DECRYPT_PROD(CONTACT_CITY),'')||', '||
                NVL(HRD_UTILITIES.PUBLIC.HRD_SYNC_DECRYPT_PROD(CONTACT_STATE),'')||' '||
                NVL(HRD_UTILITIES.PUBLIC.HRD_SYNC_DECRYPT_PROD(CONTACT_POSTAL_CODE),'') FULL_ADDRESS--PLAYER_ADDRESS
            ,   LAST_LOGIN_IP
        FROM
            PROD_CLEAN.SPORTSBOOK.ACCOUNTS_HISTORY
        WHERE
                TEST            =   0
            AND LAST_LOGIN_IP   IS NOT NULL
            AND CHANNEL_CODE    !=  'FLORIDA_ONLINE'
            AND MONTH(LAST_LOGIN_TIME) = MONTH(dateadd(MONTH,-2,CURRENT_DATE))
    )
,   Q2a  AS
    (
        SELECT
                LAST_LOGIN_IP
            ,   CHANNEL_CODE
            ,   COUNT(DISTINCT ACCOUNT_ID) COUNT_IP--IP_CNT
        FROM
            Q1
        WHERE
            FULL_ADDRESS != ' ,  '
        GROUP BY
                LAST_LOGIN_IP
            ,   CHANNEL_CODE
        HAVING
            COUNT_IP  >=  5
    )
,   Q2b  AS
    (
        SELECT
                LAST_LOGIN_IP
            ,   CHANNEL_CODE
            ,   COUNT(DISTINCT ACCOUNT_ID) COUNT_IP
        FROM
            Q1
        WHERE
                FULL_ADDRESS != ' ,  '
            AND MONTH(LAST_LOGIN_TIME) = MONTH(dateadd(MONTH,-1,CURRENT_DATE))
        GROUP BY
                LAST_LOGIN_IP
            ,   CHANNEL_CODE
        HAVING
            COUNT_IP  >=  5
    )
,   Q3a  AS
    (
        SELECT DISTINCT
                LAST_LOGIN_IP
            ,   CHANNEL_CODE
            ,   ACCOUNT_ID
            ,   '7. Players With The Same IP Address - 2 Month Look Back' RULES
        FROM
            Q1
        WHERE
            LAST_LOGIN_IP IN (SELECT LAST_LOGIN_IP FROM Q2a)
    )
,   Q3b  AS
    (
        SELECT DISTINCT
                LAST_LOGIN_IP
            ,   CHANNEL_CODE
            ,   ACCOUNT_ID
            ,   '7. Players With The Same IP Address - 1 Month Look Back' RULES
        FROM
            Q1
        WHERE
            LAST_LOGIN_IP IN (SELECT LAST_LOGIN_IP FROM Q2b)
    )
SELECT * FROM Q3a
UNION ALL
SELECT * FROM Q3b