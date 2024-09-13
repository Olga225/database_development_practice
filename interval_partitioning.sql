
CREATE OR REPLACE PACKAGE TASK19_PKG
IS
PROCEDURE SPLIT_INTO_INTERVALS(v_file_A IN VARCHAR2, v_file_B IN VARCHAR2);
END TASK19_PKG;
/
CREATE OR REPLACE PACKAGE BODY TASK19_PKG
IS
TYPE type_help_row IS RECORD(ID_INT NUMBER, ST_INT NUMBER, E_INT NUMBER, CODE_INT VARCHAR(5), FILL_INT BOOLEAN);
TYPE type_help_table IS TABLE OF type_help_row;
TYPE type_res_row IS RECORD(START_INT NUMBER, END_INT NUMBER, CODE VARCHAR(5));
TYPE type_res_table IS TABLE OF type_res_row;
TYPE type_id_list IS TABLE OF NUMBER;

v_help_A type_help_table := type_help_table();
v_help_B type_help_table := type_help_table();

v_res_table type_res_table := type_res_table();

v_last_B NUMBER := 1;
v_last_start NUMBER;

-- Заполняем таблицы файлов, отслеживающие, какие интервалы уже занесены в результат
PROCEDURE FILL_HELP_TABLES 
IS
v_temp_row type_help_row;
BEGIN
   v_help_A.DELETE;
   FOR row IN (SELECT START_INT, END_INT, CODE FROM A ORDER BY START_INT) LOOP
     v_temp_row.ID_INT := 1; v_temp_row.ST_INT := row.START_INT;
     v_temp_row.E_INT := row.END_INT; v_temp_row.CODE_INT := row.CODE;
     v_temp_row.FILL_INT := false;
     v_help_A.EXTEND;
     v_help_A(v_help_A.LAST) := v_temp_row;
     --DBMS_OUTPUT.PUT_LINE('A: ' || row.START_INT || ' ' || row.END_INT || ' '  || row.CODE);
   END LOOP;
   
   v_help_B.DELETE;
   FOR row IN (SELECT START_INT_NEW, END_INT_NEW, CODE_NEW FROM B ORDER BY START_INT_NEW) LOOP
     v_temp_row.ID_INT := 1; v_temp_row.ST_INT := row.START_INT_NEW;
     v_temp_row.E_INT := row.END_INT_NEW; v_temp_row.CODE_INT := row.CODE_NEW;
     v_temp_row.FILL_INT := false;
     v_help_B.EXTEND;
     v_help_B(v_help_B.LAST) := v_temp_row;
   END LOOP;
   
END FILL_HELP_TABLES;

-- Находим все интервалы B, попадающие в интервал A
FUNCTION FIND_B_INTERVALS(v_A_int NUMBER) RETURN type_id_list
IS
i NUMBER := v_last_B;
v_B_int type_id_list := type_id_list();
BEGIN
   IF(i <= v_help_B.LAST) THEN
   WHILE v_help_B(i).ST_INT <= v_help_A(v_A_int).E_INT AND i < v_help_B.LAST LOOP
       
      v_B_int.EXTEND;
      v_B_int(v_B_int.LAST) := i;
      v_last_B := i; v_help_B(i).FILL_INT := true;
      i := i + 1;
    END LOOP;
    IF(i = v_help_B.LAST AND v_help_B(i).ST_INT <= v_help_A(v_A_int).E_INT) THEN 
         v_B_int.EXTEND;
         v_B_int(v_B_int.LAST) := i;
         v_last_B := i; v_help_B(i).FILL_INT := true;
    END IF;
    v_last_B := v_last_B + 1;
    END IF;
    RETURN v_B_int;
END FIND_B_INTERVALS;

FUNCTION INTERVAL_BORDER(v_id_B IN NUMBER) RETURN NUMBER
IS
BEGIN
   IF (v_help_B(v_id_B).ST_INT = v_last_start) THEN RETURN 1;
   ELSE RETURN 0; END IF;
END INTERVAL_BORDER;

PROCEDURE MAIN_TASK
IS
v_idlist type_id_list := type_id_list();
temp_row type_res_row;
BEGIN
   FILL_HELP_TABLES();
   FOR i IN 1..v_help_A.LAST LOOP
          --DBMS_OUTPUT.PUT_LINE('For A int ' || i || ' '  || v_help_A(i).ST_INT);
       v_last_start := v_help_A(i).ST_INT;
       v_idlist := FIND_B_INTERVALS(i);
       IF (v_idlist.COUNT > 0) THEN
       FOR c IN v_idlist.FIRST..v_idlist.LAST LOOP
       --DBMS_OUTPUT.PUT_LINE('    For B int ' || c || ' : ' || v_help_B(v_idlist(c)).ST_INT);
            -- Интервал B совпадает с концом прошлого интервала
            IF(INTERVAL_BORDER(v_idlist(c)) = 1) THEN
                --DBMS_OUTPUT.PUT_LINE('           int match ' || v_help_B(v_idlist(c)).ST_INT || ' ' || v_help_B(v_idlist(c)).E_INT);
                temp_row.START_INT := v_help_B(v_idlist(c)).ST_INT;
                temp_row.END_INT := v_help_B(v_idlist(c)).E_INT;
                temp_row.CODE := v_help_B(v_idlist(c)).CODE_INT;
                v_res_table.EXTEND;
                v_res_table(v_res_table.LAST) := temp_row;
                v_last_start := v_help_B(v_idlist(c)).E_INT;
            -- Не свопадает
            ELSE 
                IF(v_last_start = v_help_A(i).ST_INT) THEN temp_row.START_INT := v_last_start;
                ELSE temp_row.START_INT := v_last_start + 1; END IF;
                temp_row.END_INT := v_help_B(v_idlist(c)).ST_INT - 1;
                temp_row.CODE := v_help_A(i).CODE_INT;
                v_res_table.EXTEND;
                v_res_table(v_res_table.LAST) := temp_row;
                
                
                temp_row.START_INT := v_help_B(v_idlist(c)).ST_INT;
                temp_row.END_INT := v_help_B(v_idlist(c)).E_INT;
                temp_row.CODE := v_help_B(v_idlist(c)).CODE_INT;
                v_res_table.EXTEND;
                v_res_table(v_res_table.LAST) := temp_row;
                v_last_start := v_help_B(v_idlist(c)).E_INT;
            END IF;
        END LOOP;
        IF(v_last_start != v_help_A(i).E_INT) THEN
            temp_row.START_INT := v_last_start + 1;
            temp_row.END_INT := v_help_A(i).E_INT;
            temp_row.CODE := v_help_A(i).CODE_INT;
            v_res_table.EXTEND;
            v_res_table(v_res_table.LAST) := temp_row;
        END IF;
        v_help_A(i).FILL_INT := true;
    END IF;
    END LOOP;
    
    FOR i IN 1..v_help_A.LAST LOOP
        IF(v_help_A(i).FILL_INT = false) THEN
            temp_row.START_INT := v_help_A(i).ST_INT;
            temp_row.END_INT := v_help_A(i).E_INT;
            temp_row.CODE := v_help_A(i).CODE_INT;
            v_res_table.EXTEND;
            v_res_table(v_res_table.LAST) := temp_row;
            v_help_A(i).FILL_INT := true;
        END IF;
    END LOOP;
END MAIN_TASK;

PROCEDURE INFO_FROM_FILE(v_file_A IN VARCHAR2, v_file_B IN VARCHAR2)
IS
v_file UTL_FILE.FILE_TYPE;
v_buffer VARCHAR2(500);
v_start VARCHAR(20);
v_end VARCHAR(20);
v_code VARCHAR(20);
BEGIN
    v_file := UTL_FILE.FOPEN('STUD_PLSQL', v_file_A, 'R');
    DELETE FROM A;
    LOOP
      BEGIN
        UTL_FILE.GET_LINE(v_file, v_buffer);
        v_start := TRIM(REGEXP_SUBSTR(v_buffer, '(^| )[^ ]+', 1, 1));
        v_end := TRIM(REGEXP_SUBSTR(v_buffer, '(^| )[^ ]+', 1, 2));
        v_code := TRIM(REGEXP_SUBSTR(v_buffer, '(^| )[^ ]+', 1, 3));
        INSERT INTO A VALUES (TO_NUMBER(v_start), TO_NUMBER(v_end), v_code);
        EXCEPTION WHEN NO_DATA_FOUND THEN EXIT;
      END;
    END LOOP;
    
    v_file := UTL_FILE.FOPEN('STUD_PLSQL', v_file_B, 'R');
    DELETE FROM B;
    LOOP
      BEGIN
        UTL_FILE.GET_LINE(v_file, v_buffer);
        v_start := TRIM(REGEXP_SUBSTR(v_buffer, '(^| )[^ ]+', 1, 1));
        v_end := TRIM(REGEXP_SUBSTR(v_buffer, '(^| )[^ ]+', 1, 2));
        v_code := TRIM(REGEXP_SUBSTR(v_buffer, '(^| )[^ ]+', 1, 3));
        INSERT INTO B VALUES (TO_NUMBER(v_start), TO_NUMBER(v_end), v_code);
        EXCEPTION WHEN NO_DATA_FOUND THEN EXIT;
      END;
    END LOOP;
    
END INFO_FROM_FILE;

PROCEDURE SPLIT_INTO_INTERVALS(v_file_A IN VARCHAR2, v_file_B IN VARCHAR2)
IS
BEGIN
     v_last_B := 1;
     v_res_table.DELETE();
     INFO_FROM_FILE(v_file_A, v_file_B);
     MAIN_TASK();
     DELETE FROM A;
     FOR i IN v_res_table.FIRST..v_res_table.LAST LOOP
         DBMS_OUTPUT.PUT_LINE(v_res_table(i).START_INT || ' ' || v_res_table(i).END_INT || ' ' || v_res_table(i).CODE);
         INSERT INTO A VALUES(v_res_table(i).START_INT, v_res_table(i).END_INT, v_res_table(i).CODE);
     END LOOP;
     COMMIT;
END SPLIT_INTO_INTERVALS;

END TASK19_PKG;
/
EXECUTE TASK19_PKG.SPLIT_INTO_INTERVALS('task19_morozovaoa_A', 'task19_morozovaoa_B');
/
SELECT * FROM A;



