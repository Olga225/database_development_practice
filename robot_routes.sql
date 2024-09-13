
-- ������� ������������ ������
CREATE OR REPLACE PACKAGE CORD15_PKG 
IS
TYPE rec_point is RECORD(x CORD15.X%TYPE, y CORD15.Y%TYPE); -- ��� ����������
TYPE tab_point IS TABLE OF rec_point; -- ��� ������� ��������� � ������� ��������� ���������
PROCEDURE FIND_SOLUTION(x_init IN CORD15.X%TYPE, y_init IN CORD15.Y%TYPE, direc IN char); -- ��������� ���������� �������
END CORD15_PKG;

/

-- ������� ���� ������
CREATE OR REPLACE PACKAGE BODY CORD15_PKG 
IS
cords tab_point := tab_point(); -- ������ ���� ��������� ���������
visited_cords tab_point := tab_point(); -- ������ ���� ��� ���������� ������
any_found_flag BOOLEAN := false; -- ���� �� ��, ������� �� ���� ���� �������

PROCEDURE FILL_CORDS;
PROCEDURE SHOW_ANSWER(vis IN tab_point);
FUNCTION CHECK_IN_VISITED(cor IN rec_point, vis IN tab_point) RETURN BOOLEAN;
FUNCTION CLONE_VIS(vis IN tab_point) RETURN tab_point;
FUNCTION CHECK_INIT_CORD(init_cor IN rec_point) RETURN BOOLEAN;


-- ���������, ����������� ������ ���� ���������
         PROCEDURE FILL_CORDS IS
tmp rec_point; 
BEGIN
cords.DELETE;
-- ������� ��� ���������� � ������� ��� ����� � ������ cords � ������� �����
FOR row IN (SELECT X, Y FROM CORD15 ORDER BY ID) LOOP
tmp.x := row.X;
tmp.y := row.Y;
cords.EXTEND;
cords(cords.LAST) := tmp;
END LOOP;
         END FILL_CORDS;

-- ���������, �����������, ���� �� ��������� ����� � �������. 
-- �� ���� �������� ��������� �����. ���������� ������, ���� ��� ���� � �������, ����� ����
         FUNCTION CHECK_INIT_CORD(init_cor IN rec_point) RETURN BOOLEAN IS
BEGIN
-- ���������� ��� ����� � ������� cords � ��������� ������
FOR c IN cords.FIRST..cords.LAST LOOP
IF (init_cor.x = cords(c).x AND init_cor.y = cords(c).y) THEN RETURN true;
END IF;
END LOOP;
RETURN false;
         END CHECK_INIT_CORD;

-- ���������, ���������� �� ����� ������ � ����������� �������
-- �� ���� �������� ������ ���������� ������ ��� ������� �������
         PROCEDURE SHOW_ANSWER(vis IN tab_point) IS
BEGIN
DBMS_OUTPUT.PUT('A N S W E R: ');
any_found_flag := true; -- ����������, ��� ���� �� ���� ������� �������
FOR c IN vis.FIRST..vis.LAST-1 LOOP
DBMS_OUTPUT.PUT('('|| vis(c).x || ',' || vis(c).y || ')->');
END LOOP;
DBMS_OUTPUT.PUT('(' || vis(vis.LAST).x || ',' || vis(vis.LAST).y || ')');
DBMS_OUTPUT.PUT_LINE('');

         END SHOW_ANSWER;
         
-- �������, �����������, �������� �� ��� ������ �����       
-- �� ���� �������� ����������� ����� � ������ ���������� ������ ��� ������� �������. ���������� ������, ���� ����� ��� �� ��������, ����� ����
         FUNCTION CHECK_IN_VISITED(cor IN rec_point, vis IN tab_point) RETURN BOOLEAN IS
BEGIN
-- ���������� ��� ����� � ������� ���������� ����� � ������ ������
FOR c IN vis.FIRST..vis.LAST LOOP
IF (cor.x = vis(c).x AND cor.y = vis(c).y) THEN RETURN false;
END IF;
END LOOP;
RETURN true;
         END CHECK_IN_VISITED;

-- �������, ��������� ����� ������� ������� �����
-- �� ���� �������� ������ �����, ���������� ������ �����
         FUNCTION CLONE_VIS(vis IN tab_point) RETURN tab_point IS
vis_clone tab_point := tab_point();
BEGIN
FOR c IN vis.FIRST..vis.LAST LOOP
vis_clone.EXTEND;
vis_clone(vis_clone.LAST) := vis(c);
END LOOP;
RETURN vis_clone;
         END CLONE_VIS;
         
-- ���������, ����������� ��� �� ��������� �����, ����� ������� ���������� ����� ����
-- �� ���� �������� �����, � ������� ������ ����� �����, ��� ����������� � ������ ��� ���������� ������
         PROCEDURE STEPTO(cur_c IN rec_point, direc IN char, vis_last IN tab_point) IS
nearest_c rec_point; -- ��������� � ������� �����
vis_move tab_point; -- ������ ��� ���������� ������
end_flag BOOLEAN := false; -- �����������, ���� �� ��������� ����� ����������
BEGIN

vis_move := CLONE_VIS(vis_last); -- ������� ����� ������� ��� ���������� ������
vis_move.EXTEND; -- ��������� � ������ ��� ���� �������
vis_move(vis_move.LAST) := cur_c; -- ������� � ������ ���������� ����� ������� �������

-- ���� ������� ���������� ������ ����� ���������� ������, ������� �� �����
IF(vis_move.COUNT >= cords.COUNT) THEN 
IF(end_flag = false) THEN end_flag := true; SHOW_ANSWER(vis_move); END IF;
RETURN;
ELSE

-- ���� ����������� ����� ��� ����
IF(direc = 'U' OR direc = 'D') THEN
       -- ������� ��������� ������� ������
       FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (cur_c.y = cords(c).y) AND 
                (nearest_c.x IS NULL OR nearest_c.x > (cords(c).x - cur_c.x)) AND
                (cur_c.x < cords(c).x) AND
                CHECK_IN_VISITED(cords(c), vis_move) ) THEN
                       nearest_c.x := cords(c).x;
            END IF;
      END LOOP;
      nearest_c.y := cur_c.y;
      -- ���� ������ ���� �������, ������ �� ���
      IF(nearest_c.x IS NOT NULL) THEN
      STEPTO(nearest_c, 'R', vis_move); END IF;
      
      -- �������� ��������� �����
      nearest_c.x := null; nearest_c.y := null;
      
      -- ������� ��������� ������� �����
      FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (cur_c.y = cords(c).y) AND 
                (nearest_c.x IS NULL OR nearest_c.x > (cur_c.x - cords(c).x)) AND
                (cur_c.x > cords(c).x) AND
                CHECK_IN_VISITED(cords(c), vis_move) ) THEN
                       nearest_c.x := cords(c).x;
            END IF;
      END LOOP;
      nearest_c.y := cur_c.y;
      -- ���� ����� ���� �������, ������ �� ���
      IF(nearest_c.x IS NOT NULL) THEN
      STEPTO(nearest_c, 'L', vis_move); END IF;
      
      nearest_c.x := null; nearest_c.y := null;
END IF;

-- ���� ����������� ������ ��� �����
IF(direc = 'R' OR direc = 'L') THEN

       -- ������� ��������� ������� ������
       FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (cur_c.x = cords(c).x) AND 
                (nearest_c.y IS NULL OR nearest_c.y > (cords(c).y - cur_c.y)) AND
                (cur_c.y < cords(c).y) AND
                CHECK_IN_VISITED(cords(c), vis_move) ) THEN
                       nearest_c.y := cords(c).y;
            END IF;
      END LOOP;
      nearest_c.x := cur_c.x;
      -- ���� ������ ���� �������, ������ �� ���
      IF(nearest_c.y IS NOT NULL) THEN
      STEPTO(nearest_c, 'U', vis_move); END IF;
      
      nearest_c.x := null; nearest_c.y := null;
      
      -- ������� ��������� ������� �����
      FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (cur_c.x = cords(c).x) AND 
                (nearest_c.y IS NULL OR nearest_c.y > (cur_c.y - cords(c).y)) AND
                (cur_c.y > cords(c).y) AND
                CHECK_IN_VISITED(cords(c), vis_move) ) THEN
                       nearest_c.y := cords(c).y;
            END IF;
      END LOOP;
      nearest_c.x := cur_c.x;
      -- ���� ����� ���� �������, ������ �� ���
      IF(nearest_c.y IS NOT NULL) THEN
      STEPTO(nearest_c, 'D', vis_move); END IF;
      
      nearest_c.x := null; nearest_c.y := null;
END IF;
END IF;
         END STEPTO;

-- ���������, ������� ���������� ����� �������, ����� ������ ���
-- �������� �� ���� ���������� x, ���������� y � ����������� ������
         PROCEDURE FIND_SOLUTION(x_init IN CORD15.X%TYPE, y_init IN CORD15.Y%TYPE, direc IN char) IS
nearest_c rec_point; -- ��������� ����� � �������
st rec_point; -- ��������� ����� ��������
end_flag BOOLEAN; -- �����������, ���� �� ��������� ����� ����������
BEGIN

visited_cords.DELETE;
nearest_c.x := null; nearest_c.y := null;
FILL_CORDS(); -- ��������� ������ ���� ��������� �����

-- ������������� ��������� ����� � ������������ � ������� ������������
st.x := x_init;
st.y := y_init;

any_found_flag := false;

-- ���� ��������� ����� ��� � �������, ������� ��������� ������������ � ������� �� ���������
IF(CHECK_INIT_CORD(st) = false) THEN DBMS_OUTPUT.PUT_LINE('Uncorrect first point'); RETURN; 
END IF;

-- ��������� � ������ ��� ���������� ����� ��������� �����
visited_cords.EXTEND;
visited_cords(visited_cords.LAST) := st;

-- ���������, �� ��������� �� ��� ������� ������ ���� �����: ���� ��, ������� ����� � �������
IF(visited_cords.COUNT >= cords.COUNT) THEN end_flag := true; SHOW_ANSWER(visited_cords); RETURN;
ELSE

-- ���� ����� �������� �����
IF(direc = 'U') THEN
      -- ������� ��������� ������� ������
      FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (st.x = cords(c).x) AND 
                (nearest_c.y IS NULL OR nearest_c.y > (cords(c).y - st.y)) AND
                (st.y < cords(c).y)) THEN
                       nearest_c.y := cords(c).y;
            END IF;
      END LOOP;
      nearest_c.x := st.x;
      IF(nearest_c.y IS NOT NULL) THEN
      -- ���� ������ ���� �������, ������ �� ���
      STEPTO(nearest_c, 'U', visited_cords);  nearest_c.x := null; nearest_c.y := null; END IF;
END IF;

-- ���� ����� �������� ����
IF(direc = 'D') THEN
      -- ������� ��������� ������� �����
      FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (st.x = cords(c).x) AND 
                (nearest_c.y IS NULL OR nearest_c.y > (st.y - cords(c).y)) AND
                (st.y > cords(c).y)) THEN
                       nearest_c.y := cords(c).y;
            END IF;
      END LOOP;
      nearest_c.x := st.x;
      -- ���� ����� ���� �������, ������ �� ���
      IF(nearest_c.y IS NOT NULL) THEN
      STEPTO(nearest_c, 'D', visited_cords);  nearest_c.x := null; nearest_c.y := null; END IF;
END IF;

-- ���� ����� �������� ������
IF(direc = 'R') THEN
      -- ������� ��������� ������� ������
      FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (st.y = cords(c).y) AND 
                (nearest_c.x IS NULL OR nearest_c.x > (cords(c).x - st.x)) AND
                (st.x < cords(c).x)) THEN
                       nearest_c.x := cords(c).x;
            END IF;
      END LOOP;
      nearest_c.y := st.y;
      -- ���� ������ ���� �������, ������ �� ���
      IF(nearest_c.x IS NOT NULL) THEN
      STEPTO(nearest_c, 'R', visited_cords);  nearest_c.x := null; nearest_c.y := null; END IF;
END IF;

-- ���� ����� �������� �����
IF(direc = 'L') THEN
      -- ������� ��������� ������� �����
      FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (st.y = cords(c).y) AND 
                (nearest_c.x IS NULL OR nearest_c.x > (st.x - cords(c).x)) AND
                (st.x > cords(c).x)) THEN
                       nearest_c.x := cords(c).x;
            END IF;
      END LOOP;
      nearest_c.y := st.y;
      -- ���� ����� ���� �������, ������ �� ���
      IF(nearest_c.x IS NOT NULL) THEN
      STEPTO(nearest_c, 'L', visited_cords);  nearest_c.x := null; nearest_c.y := null; END IF;
END IF;

-- ���� �� ������� �� ������ ������� ����� ���������� ���� �������, ������� ���������, ��� �������� ���
IF(any_found_flag = false) THEN DBMS_OUTPUT.PUT_LINE('No such way'); END IF;

END IF;
         END FIND_SOLUTION;
         
END CORD15_PKG;

