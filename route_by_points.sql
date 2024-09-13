WITH HIER_T AS (SELECT 2 AS CHILD_ID, 1 AS PARENT_ID , 2 AS AMOUNT_N
                FROM DUAL
                UNION ALL
                SELECT 5, 1, 2 FROM DUAL
                UNION ALL
                SELECT 3, 2, 1 FROM DUAL
                UNION ALL
                SELECT 4, 2, 2 FROM DUAL
                UNION ALL
                SELECT 4, 6, 2 FROM DUAL
                UNION ALL
                SELECT 6, 5, 3 FROM DUAL
                UNION ALL
                SELECT 4, 3, 2 FROM DUAL),

--�������� ���������. ������ ������� ���� ��������� � ������������ �����, ��������������� �� ���������
MAI AS (SELECT CONNECT_BY_ROOT PARENT_ID || SYS_CONNECT_BY_PATH(CHILD_ID, '->') "PAT", --������� 
SYS_CONNECT_BY_PATH(AMOUNT_N, '+') "AM" --������������ �������� ��������
FROM HIER_TREE
WHERE CONNECT_BY_ISCYCLE = 0
CONNECT BY NOCYCLE PRIOR CHILD_ID = PARENT_ID), 

-- ���������, ����������� ������ ������������ �������� �� ������� � ���������������� �������.
VAL_D_R AS (SELECT DISTINCT REGEXP_SUBSTR(AM, '[^+]+', 1, LEVEL) "VAL", PAT, AM, LEVEL L 
               FROM MAI
               CONNECT BY LEVEL <= REGEXP_COUNT(AM, '\+')),

--���������, �������������� ������������ ���� �������� �� ���� ��������
PROD AS (SELECT FLOOR(EXP(SUM(LN(VAL)))) "VAL_P", PAT
         FROM VAL_D_R
         GROUP BY (PAT)),
         
--���������, ��������� ��������� � �������� ������� ����
F_L_MAI AS (SELECT REGEXP_SUBSTR(PAT, '^[^->]+') "FIR", REGEXP_SUBSTR(PAT, '[^->]+$') "LAS", PAT
          FROM MAI),

--���������, ��������� ���������� ����� ����� ���������� ��������� � �������� ���������
CNT_R AS (SELECT COUNT(*) "CNT", FIR, LAS
          FROM F_L_MAI
          GROUP BY (FIR, LAS)),

--���������, ��������� ����� ������������ �������� ���� ����� ����� ����� ����������� ������ ��������� � �������� ������
S_P_VAL AS (SELECT SUM(PROD.VAL_P) SV, F_L_MAI.FIR FIR, F_L_MAI.LAS LAS
            FROM PROD JOIN F_L_MAI
            ON (PROD.PAT = F_L_MAI.PAT)
            GROUP BY (F_L_MAI.FIR, F_L_MAI.LAS))

--�������� ������. ��������� ����������, ������ ������������� ���������
SELECT DISTINCT CNT_R.FIR "��������� �������", CNT_R.LAS "�������� �������", CNT_R.CNT "���������� �����", S_P_VAL.SV "����� ������������"
FROM CNT_R JOIN S_P_VAL
ON CNT_R.FIR = S_P_VAL.FIR AND CNT_R.LAS = S_P_VAL.LAS
WHERE CNT_R.FIR <> CNT_R.LAS
ORDER BY CNT_R.FIR, CNT_R.LAS;
