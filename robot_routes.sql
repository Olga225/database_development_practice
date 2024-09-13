
-- Создаем спецификацию пакета
CREATE OR REPLACE PACKAGE CORD15_PKG 
IS
TYPE rec_point is RECORD(x CORD15.X%TYPE, y CORD15.Y%TYPE); -- Тип координаты
TYPE tab_point IS TABLE OF rec_point; -- Тип массива координат в формате вложенной коллекции
PROCEDURE FIND_SOLUTION(x_init IN CORD15.X%TYPE, y_init IN CORD15.Y%TYPE, direc IN char); -- Процедура нахождения решения
END CORD15_PKG;

/

-- Создаем тело пакета
CREATE OR REPLACE PACKAGE BODY CORD15_PKG 
IS
cords tab_point := tab_point(); -- массив всех имеющихся координат
visited_cords tab_point := tab_point(); -- массив всех уже пройденных вершин
any_found_flag BOOLEAN := false; -- флаг на то, нашлось ли хоть одно решение

PROCEDURE FILL_CORDS;
PROCEDURE SHOW_ANSWER(vis IN tab_point);
FUNCTION CHECK_IN_VISITED(cor IN rec_point, vis IN tab_point) RETURN BOOLEAN;
FUNCTION CLONE_VIS(vis IN tab_point) RETURN tab_point;
FUNCTION CHECK_INIT_CORD(init_cor IN rec_point) RETURN BOOLEAN;


-- Процедура, заполняющая массив всех координат
         PROCEDURE FILL_CORDS IS
tmp rec_point; 
BEGIN
cords.DELETE;
-- Заносим все координаты в таблице как точки в массив cords с помощью цикла
FOR row IN (SELECT X, Y FROM CORD15 ORDER BY ID) LOOP
tmp.x := row.X;
tmp.y := row.Y;
cords.EXTEND;
cords(cords.LAST) := tmp;
END LOOP;
         END FILL_CORDS;

-- Процедура, проверяющая, есть ли начальная точка в таблице. 
-- На вход получает начальную точку. Возвращает истину, если она есть в таблице, иначе ложь
         FUNCTION CHECK_INIT_CORD(init_cor IN rec_point) RETURN BOOLEAN IS
BEGIN
-- Сравниваем все точки в массиве cords с начальной точкой
FOR c IN cords.FIRST..cords.LAST LOOP
IF (init_cor.x = cords(c).x AND init_cor.y = cords(c).y) THEN RETURN true;
END IF;
END LOOP;
RETURN false;
         END CHECK_INIT_CORD;

-- Процедура, отвечающая за вывод ответа в необходимом формате
-- На вход получает массив пройденных вершин для данного решения
         PROCEDURE SHOW_ANSWER(vis IN tab_point) IS
BEGIN
DBMS_OUTPUT.PUT('A N S W E R: ');
any_found_flag := true; -- обозначаем, что хотя бы одно решение найдено
FOR c IN vis.FIRST..vis.LAST-1 LOOP
DBMS_OUTPUT.PUT('('|| vis(c).x || ',' || vis(c).y || ')->');
END LOOP;
DBMS_OUTPUT.PUT('(' || vis(vis.LAST).x || ',' || vis(vis.LAST).y || ')');
DBMS_OUTPUT.PUT_LINE('');

         END SHOW_ANSWER;
         
-- Функция, проверяющая, пройдена ли уже данная точка       
-- На вход получает проверяемую точку и массив пройденных вершин для данного решения. Возвращает истину, если точка еще не пройдена, иначе ложь
         FUNCTION CHECK_IN_VISITED(cor IN rec_point, vis IN tab_point) RETURN BOOLEAN IS
BEGIN
-- Сравниваем все точки в массиве пройденных точек с данной точкой
FOR c IN vis.FIRST..vis.LAST LOOP
IF (cor.x = vis(c).x AND cor.y = vis(c).y) THEN RETURN false;
END IF;
END LOOP;
RETURN true;
         END CHECK_IN_VISITED;

-- Функция, создающая копию данного массива точке
-- На вход получает массив точек, возвращает массив точек
         FUNCTION CLONE_VIS(vis IN tab_point) RETURN tab_point IS
vis_clone tab_point := tab_point();
BEGIN
FOR c IN vis.FIRST..vis.LAST LOOP
vis_clone.EXTEND;
vis_clone(vis_clone.LAST) := vis(c);
END LOOP;
RETURN vis_clone;
         END CLONE_VIS;
         
-- Процедура, совершающая шаг на следующую точку, таким образом рекурсивно строя путь
-- На вход получает точку, в которой сейчас стоит работ, его направление и массив уже пройденных вершин
         PROCEDURE STEPTO(cur_c IN rec_point, direc IN char, vis_last IN tab_point) IS
nearest_c rec_point; -- Ближайшая к текущей точка
vis_move tab_point; -- Массив уже пройденных вершин
end_flag BOOLEAN := false; -- Отслеживает, было ли достигнут конец выполнения
BEGIN

vis_move := CLONE_VIS(vis_last); -- Создаем копию массива уже пройденных вершин
vis_move.EXTEND; -- Добавляем в массив еще один элемент
vis_move(vis_move.LAST) := cur_c; -- Добавем в массив пройденных точек текущую вершину

-- Если впервые достигнуто нужное число пройденных вершин, выходим из цикла
IF(vis_move.COUNT >= cords.COUNT) THEN 
IF(end_flag = false) THEN end_flag := true; SHOW_ANSWER(vis_move); END IF;
RETURN;
ELSE

-- Если направление вверх или вниз
IF(direc = 'U' OR direc = 'D') THEN
       -- Находим ближайщую вершину справа
       FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (cur_c.y = cords(c).y) AND 
                (nearest_c.x IS NULL OR nearest_c.x > (cords(c).x - cur_c.x)) AND
                (cur_c.x < cords(c).x) AND
                CHECK_IN_VISITED(cords(c), vis_move) ) THEN
                       nearest_c.x := cords(c).x;
            END IF;
      END LOOP;
      nearest_c.y := cur_c.y;
      -- Если справа есть вершина, шагаем на нее
      IF(nearest_c.x IS NOT NULL) THEN
      STEPTO(nearest_c, 'R', vis_move); END IF;
      
      -- Обнуляем ближайшую точку
      nearest_c.x := null; nearest_c.y := null;
      
      -- Находим ближайщую вершину слева
      FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (cur_c.y = cords(c).y) AND 
                (nearest_c.x IS NULL OR nearest_c.x > (cur_c.x - cords(c).x)) AND
                (cur_c.x > cords(c).x) AND
                CHECK_IN_VISITED(cords(c), vis_move) ) THEN
                       nearest_c.x := cords(c).x;
            END IF;
      END LOOP;
      nearest_c.y := cur_c.y;
      -- Если слева есть вершина, шагаем на нее
      IF(nearest_c.x IS NOT NULL) THEN
      STEPTO(nearest_c, 'L', vis_move); END IF;
      
      nearest_c.x := null; nearest_c.y := null;
END IF;

-- Если направление вправо или влево
IF(direc = 'R' OR direc = 'L') THEN

       -- Находим ближайщую вершину сверху
       FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (cur_c.x = cords(c).x) AND 
                (nearest_c.y IS NULL OR nearest_c.y > (cords(c).y - cur_c.y)) AND
                (cur_c.y < cords(c).y) AND
                CHECK_IN_VISITED(cords(c), vis_move) ) THEN
                       nearest_c.y := cords(c).y;
            END IF;
      END LOOP;
      nearest_c.x := cur_c.x;
      -- Если сверху есть вершина, шагаем на нее
      IF(nearest_c.y IS NOT NULL) THEN
      STEPTO(nearest_c, 'U', vis_move); END IF;
      
      nearest_c.x := null; nearest_c.y := null;
      
      -- Находим ближайщую вершину снизу
      FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (cur_c.x = cords(c).x) AND 
                (nearest_c.y IS NULL OR nearest_c.y > (cur_c.y - cords(c).y)) AND
                (cur_c.y > cords(c).y) AND
                CHECK_IN_VISITED(cords(c), vis_move) ) THEN
                       nearest_c.y := cords(c).y;
            END IF;
      END LOOP;
      nearest_c.x := cur_c.x;
      -- Если снизу есть вершина, шагаем на нее
      IF(nearest_c.y IS NOT NULL) THEN
      STEPTO(nearest_c, 'D', vis_move); END IF;
      
      nearest_c.x := null; nearest_c.y := null;
END IF;
END IF;
         END STEPTO;

-- Процедура, которая инициирует поиск решения, делая первый шаг
-- Получает на вход координату x, координату y и направление робота
         PROCEDURE FIND_SOLUTION(x_init IN CORD15.X%TYPE, y_init IN CORD15.Y%TYPE, direc IN char) IS
nearest_c rec_point; -- Ближайшая точка к текущей
st rec_point; -- Начальная точка движения
end_flag BOOLEAN; -- Отслеживает, было ли достигнут конец выполнения
BEGIN

visited_cords.DELETE;
nearest_c.x := null; nearest_c.y := null;
FILL_CORDS(); -- Заполняем массив всех имеющихся точек

-- Устанавливаем начальную точку в соответствии с данными координатами
st.x := x_init;
st.y := y_init;

any_found_flag := false;

-- Если начальной точки нет в массиве, выводим сообщение пользователю и выходим из процедуры
IF(CHECK_INIT_CORD(st) = false) THEN DBMS_OUTPUT.PUT_LINE('Uncorrect first point'); RETURN; 
END IF;

-- Добавляем в массив уже пройденных точек начальную точку
visited_cords.EXTEND;
visited_cords(visited_cords.LAST) := st;

-- Проверяем, не выполнено ли уже условие обхода всех точек: если да, выводим ответ и выходим
IF(visited_cords.COUNT >= cords.COUNT) THEN end_flag := true; SHOW_ANSWER(visited_cords); RETURN;
ELSE

-- Если робот направен вверх
IF(direc = 'U') THEN
      -- Находим ближайщую вершину сверху
      FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (st.x = cords(c).x) AND 
                (nearest_c.y IS NULL OR nearest_c.y > (cords(c).y - st.y)) AND
                (st.y < cords(c).y)) THEN
                       nearest_c.y := cords(c).y;
            END IF;
      END LOOP;
      nearest_c.x := st.x;
      IF(nearest_c.y IS NOT NULL) THEN
      -- Если сверху есть вершина, шагаем на нее
      STEPTO(nearest_c, 'U', visited_cords);  nearest_c.x := null; nearest_c.y := null; END IF;
END IF;

-- Если робот направен вниз
IF(direc = 'D') THEN
      -- Находим ближайщую вершину снизу
      FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (st.x = cords(c).x) AND 
                (nearest_c.y IS NULL OR nearest_c.y > (st.y - cords(c).y)) AND
                (st.y > cords(c).y)) THEN
                       nearest_c.y := cords(c).y;
            END IF;
      END LOOP;
      nearest_c.x := st.x;
      -- Если снизу есть вершина, шагаем на нее
      IF(nearest_c.y IS NOT NULL) THEN
      STEPTO(nearest_c, 'D', visited_cords);  nearest_c.x := null; nearest_c.y := null; END IF;
END IF;

-- Если робот направен вправо
IF(direc = 'R') THEN
      -- Находим ближайщую вершину справа
      FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (st.y = cords(c).y) AND 
                (nearest_c.x IS NULL OR nearest_c.x > (cords(c).x - st.x)) AND
                (st.x < cords(c).x)) THEN
                       nearest_c.x := cords(c).x;
            END IF;
      END LOOP;
      nearest_c.y := st.y;
      -- Если справа есть вершина, шагаем на нее
      IF(nearest_c.x IS NOT NULL) THEN
      STEPTO(nearest_c, 'R', visited_cords);  nearest_c.x := null; nearest_c.y := null; END IF;
END IF;

-- Если робот направен влево
IF(direc = 'L') THEN
      -- Находим ближайщую вершину слева
      FOR c IN cords.FIRST..cords.LAST LOOP
            IF( (st.y = cords(c).y) AND 
                (nearest_c.x IS NULL OR nearest_c.x > (st.x - cords(c).x)) AND
                (st.x > cords(c).x)) THEN
                       nearest_c.x := cords(c).x;
            END IF;
      END LOOP;
      nearest_c.y := st.y;
      -- Если слева есть вершина, шагаем на нее
      IF(nearest_c.x IS NOT NULL) THEN
      STEPTO(nearest_c, 'L', visited_cords);  nearest_c.x := null; nearest_c.y := null; END IF;
END IF;

-- Если не найдено ни одного решения после простройки всех решений, выводим сообщение, что маршрута нет
IF(any_found_flag = false) THEN DBMS_OUTPUT.PUT_LINE('No such way'); END IF;

END IF;
         END FIND_SOLUTION;
         
END CORD15_PKG;

