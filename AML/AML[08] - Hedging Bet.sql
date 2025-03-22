/*
Department: Anti-Money Laundering
Requestor:  Olga Carrera
Purpose:    AML Triggers
Notes:      Next Steps:
            -   Need to ensure this is capturing TRUE both sides, possible same side differet selection type.
*/
WITH
    Q1  AS
    (
        SELECT
                b.ACCOUNT_ID
            ,   bp.NODE_ID
            ,   bp.EVENT
            ,   bp.MARKET_TYPE
            ,   COUNT(DISTINCT(bp.SELECTION_TYPE))
            ,   LISTAGG(bp.SELECTION, ', ') within GROUP (ORDER BY bp.PLACED_TIME asc) as distinct_selections
            ,   LISTAGG(bp.BET_ID, ', ')    within GROUP (ORDER BY bp.PLACED_TIME asc) as distinct_bet_ids
        FROM
            "PROD_CLEAN"."SPORTSBOOK"."BET_PARTS" bp
        JOIN
            "PROD_CLEAN"."SPORTSBOOK"."BETS" b
            on b.BET_ID = bp.BET_ID
        WHERE
                b.STATUS <> 'REJECTED'
            and b.TEST = 'FALSE'
            and b.BRAND_CODE != 'HRD_RETAIL'
            and b.BET_TYPE = 'SINGLE'
            and b.TOTAL_STAKE >= 500
            and bp.OUTRIGHT = 'FALSE'
            and bp.LIVE_BET = 0
            and bp.MARKET_TYPE in
                (
                    'AMERICAN_FOOTBALL:FTOT:SPRD',
                    'AMERICAN_FOOTBALL:FTOT:ML',
                    'AMERICAN_FOOTBALL:FTOT:OU',
                    'BASKETBALL:FTOT:SPRD',
                    'BASKETBALL:FTOT:ML',
                    'BASKETBALL:FTOT:OU',
                    'ICE_HOCKEY:FTOT:SPRD',
                    'ICE_HOCKEY:FTOT:ML',
                    'ICE_HOCKEY:FTOT:OU',
                    'BASEBALL:FTOT:SPRD',
                    'BASEBALL:FTEI:SPRD',
                    'BASEBALL:FTOT:ML',
                    'BASEBALL:FTEI:ML',
                    'BASEBALL:FTOT:OU',
                    'BASEBALL:FTEI:OU'
                )
            AND MONTH(PLACED_TIME) = MONTH(dateadd(MONTH,-1,CURRENT_DATE))
        GROUP BY
                b.ACCOUNT_ID
            ,   bp.NODE_ID
            ,   bp.EVENT
            ,   bp.MARKET_TYPE
        HAVING
            COUNT(DISTINCT(bp.SELECTION_TYPE)) > 1
        ORDER BY
            COUNT(DISTINCT(bp.SELECTION_TYPE)) DESC
    )
SELECT DISTINCT ACCOUNT_ID,'Same player places bets on both sides of a game' RULE FROM Q1