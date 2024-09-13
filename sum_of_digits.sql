DEFINE ST = 't29h8n3m7l88g799999999999927'

WITH NUM_ONL AS (SELECT NVL(REGEXP_REPLACE('&ST', '\D+', ''),'0') ST
FROM DUAL), --������� ��� ���������� �������, ����� �������� �����, ������� ����� ����� ��������������

NUM_REP AS 
(
SELECT *
FROM NUM_ONL
MODEL -- -1 ������ ������������ ��� ��������� ����������, � ������� ���������� ������
DIMENSION BY(CAST (-1 AS NUMBER(7)) ID)
MEASURES(ST, CAST (0 AS NUMBER(7)) SU, 0 FL, CAST (-1 AS NUMBER(7)) CONT, CAST (0 AS NUMBER(7)) SIGN)

-- ����� ID � ������������� ������, ������ ���������� � -1
-- ST � � ��������� ������ ������ �������������� �� ������ ����� �����, � ������������� ������� ����� � ��������������� ������ �����
-- SU � ������� ����� ���� (���������� ��� ��������� ��������)
-- FL � ������������� � ����� ��������� ������� �����
-- CONT � ��������� �� ����� ������ �� ��������� ����������� �� �������������� �����
-- SIGN � ������������� � ������������� ���������� ���������� ����� ��� ��������� �����. ���� ����� ����� ��������� ����� � ����� �����, � ��������������� ������ ������������ 1. ���� ���� ��������, � -1 ������ ������������ 1

RULES ITERATE(100) UNTIL (SIGN[-1] = 1) (
CONT[ITERATION_NUMBER] = CONT[ITERATION_NUMBER-1], -- � ������ �������� ������ ��������� ������ �������� ���������� ������
FL[ITERATION_NUMBER] = CASE WHEN SIGN[ITERATION_NUMBER-1] = 0 THEN FL[ITERATION_NUMBER-1] + 1
                            ELSE 0 END, -- �������� � ������ ������ �����, ����������� �� ���� � �������
ST[ITERATION_NUMBER] = CASE WHEN SIGN[ITERATION_NUMBER-1] = 0 THEN REGEXP_SUBSTR(ST[CONT[ITERATION_NUMBER]], '.', 1, FL[ITERATION_NUMBER])
                            ELSE TO_CHAR(SU[ITERATION_NUMBER-1]) END, -- ������������� ������������ ����� ����������� ����� ��� ����� �������������� ����� � ������ ������ �����, ����� ��������� ����� ��������������� ����� � �������
SU[ITERATION_NUMBER] = CASE WHEN SIGN[ITERATION_NUMBER-1] = 0 THEN SU[ITERATION_NUMBER-1] + ST[ITERATION_NUMBER]
                            ELSE 0 END, -- �������� ����� � ������ ������ �����, ���������� � ��� ��������������� ����� � �������
CONT[ITERATION_NUMBER] = CASE WHEN FL[ITERATION_NUMBER] = LENGTH(ST[CONT[ITERATION_NUMBER-1]]) AND SU[ITERATION_NUMBER] >= 10 THEN ITERATION_NUMBER+1 ELSE CONT[ITERATION_NUMBER-1] END, -- ���� ����������� ��� ����� ��������������� ����� � ����� ��� ��� ������ 9, ����� �� ����� ����� ��������� ������ ��������� ������ (��� ��� �� ��������� �������� ����� �������� ��� ��������� ���������� ���������� �����), ����� ��������� �� �� ��������, ��� � �� ���������� ��������
SIGN[ITERATION_NUMBER] = CASE WHEN FL[ITERATION_NUMBER] = LENGTH(ST[CONT[ITERATION_NUMBER-1]]) AND SU[ITERATION_NUMBER] >= 10 THEN 1 ELSE 0 END, -- ���� ����������� ��� ����� ��������������� ����� � ����� ��� ��� ������ 9, ������ �������� 1, ����� 0
SIGN[-1] = CASE WHEN FL[ITERATION_NUMBER] = LENGTH(ST[CONT[ITERATION_NUMBER-1]]) AND SU[ITERATION_NUMBER] < 10 THEN 1 ELSE SIGN[-1] END -- ���� ����������� ��� ����� ��������������� ����� � ����� ������ 10, ������ -1 ������ �������� 1, ����� ��������� �������

)
)

-- ������� ������������ ��������� (�������� ����� ����� ��������� � ��������� (������� ������������ �������������) ������)
SELECT '&ST' "�������� ������",  SU "���������"
FROM NUM_REP
WHERE ID = (SELECT MAX(ID) FROM NUM_REP);
