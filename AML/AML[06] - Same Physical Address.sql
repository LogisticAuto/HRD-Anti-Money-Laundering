/*
Department: Anti-Money Laundering
Purpose:    AML Triggers [6]
Requestor:  Olga Carrera
Notes:      
*/
WITH
    Q1  AS
    (
        SELECT DISTINCT
                CHANNEL_CODE
            ,   ACCOUNT_ID
            ,   CREATION_DATE
            ,   NVL(HRD_UTILITIES.PUBLIC.HRD_SYNC_DECRYPT_PROD(CONTACT_ADDRESS),'')||
                CASE WHEN HRD_UTILITIES.PUBLIC.HRD_SYNC_DECRYPT_PROD(CONTACT_ADDRESS_2) IS NOT NULL THEN ' Unit ' ELSE '' END||
                NVL(HRD_UTILITIES.PUBLIC.HRD_SYNC_DECRYPT_PROD(CONTACT_ADDRESS_2),'')||' '||
                NVL(HRD_UTILITIES.PUBLIC.HRD_SYNC_DECRYPT_PROD(CONTACT_CITY),'')||', '||
                NVL(HRD_UTILITIES.PUBLIC.HRD_SYNC_DECRYPT_PROD(CONTACT_STATE),'')||' '||
                NVL(HRD_UTILITIES.PUBLIC.HRD_SYNC_DECRYPT_PROD(CONTACT_POSTAL_CODE),'') FULL_ADDRESS
        FROM
            PROD_CLEAN.SPORTSBOOK.ACCOUNTS_HISTORY
        WHERE
                TEST = 0
    )
,   Q2  AS
    (
        SELECT
            *
        FROM
            Q1
        -- WHERE
        --     MONTH(CREATION_DATE) = MONTH(DATEADD(MONTH,-1,CURRENT_DATE))
        --     AND FULL_ADDRESS != ' ,  '
        --     AND FULL_ADDRESS IS NOT NULL
    )
,   Q3  AS
    (
        SELECT
                CHANNEL_CODE
            ,   FULL_ADDRESS
            ,   COUNT(DISTINCT ACCOUNT_ID) CNT
        FROM
            Q1
        GROUP BY
                CHANNEL_CODE
            ,   FULL_ADDRESS
        -- HAVING
        --     CNT   >=  3
    )
,   Q4  AS
    (
        SELECT
                CHANNEL_CODE
            ,   ACCOUNT_ID
            ,   CREATION_DATE
            ,   FULL_ADDRESS
        FROM
            Q1
        WHERE
                FULL_ADDRESS IN (SELECT FULL_ADDRESS FROM Q2)
            AND FULL_ADDRESS IN (SELECT FULL_ADDRESS FROM Q3)
    )
,   Q5  AS
    (
        SELECT DISTINCT
                CHANNEL_CODE
            ,   ACCOUNT_ID
            ,   FULL_ADDRESS--PLAYER_ADDRESS
            ,   CREATION_DATE
            ,   '6. Players With The Same Address' RULES
        FROM
            Q4
        ORDER BY
                FULL_ADDRESS
            ,   ACCOUNT_ID
    )SELECT * FROM Q5
WHERE
FULL_ADDRESS ILIKE '3851 Chad Lane%' OR
FULL_ADDRESS ILIKE '%7514 Kylan Drive'