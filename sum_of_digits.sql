DEFINE ST = 't29h8n3m7l88g799999999999927'

WITH NUM_ONL AS (SELECT NVL(REGEXP_REPLACE('&ST', '\D+', ''),'0') ST
FROM DUAL), --убираем все нецифровые символы, чтобы получить число, которое далее будет обрабатываться

NUM_REP AS 
(
SELECT *
FROM NUM_ONL
MODEL -- -1 строка используется для служебной информации, с которой начинается расчет
DIMENSION BY(CAST (-1 AS NUMBER(7)) ID)
MEASURES(ST, CAST (0 AS NUMBER(7)) SU, 0 FL, CAST (-1 AS NUMBER(7)) CONT, CAST (0 AS NUMBER(7)) SIGN)

-- Здесь ID – идентификатор строки, отсчёт начинается с -1
-- ST – в служебной строке хранит обрабатываемое на данном цикле число, в промежуточных строках цикла – рассматриваемую сейчас цифру
-- SU – текущая сумма цифр (обнуляется при повторном подсчете)
-- FL – сигнализирует о конце обработки данного числа
-- CONT – указывает на номер строки со служебной информацией об обрабатываемом числе
-- SIGN – сигнализирует о необходимости повторного повторения цикла или окончания цикла. Если нужно вновь посчитать сумму в новом числе, у соответствующей строки выставляется 1. Если цикл завершен, в -1 строке выставляется 1

RULES ITERATE(100) UNTIL (SIGN[-1] = 1) (
CONT[ITERATION_NUMBER] = CONT[ITERATION_NUMBER-1], -- В начале итерации всегда считается равной значению предыдущей строки
FL[ITERATION_NUMBER] = CASE WHEN SIGN[ITERATION_NUMBER-1] = 0 THEN FL[ITERATION_NUMBER-1] + 1
                            ELSE 0 END, -- Обнуляем в начале нового цикла, увеличиваем на один в текущем
ST[ITERATION_NUMBER] = CASE WHEN SIGN[ITERATION_NUMBER-1] = 0 THEN REGEXP_SUBSTR(ST[CONT[ITERATION_NUMBER]], '.', 1, FL[ITERATION_NUMBER])
                            ELSE TO_CHAR(SU[ITERATION_NUMBER-1]) END, -- Рассматриваем получившуюся сумму предыдущего цикла как новое обрабатываемое число в начале нового цикла, берем следующую цифру обрабатываемого числа в текущем
SU[ITERATION_NUMBER] = CASE WHEN SIGN[ITERATION_NUMBER-1] = 0 THEN SU[ITERATION_NUMBER-1] + ST[ITERATION_NUMBER]
                            ELSE 0 END, -- Обнуляем сумму в начале нового цикла, прибавляем к ней рассматриваемую цифру в текущем
CONT[ITERATION_NUMBER] = CASE WHEN FL[ITERATION_NUMBER] = LENGTH(ST[CONT[ITERATION_NUMBER-1]]) AND SU[ITERATION_NUMBER] >= 10 THEN ITERATION_NUMBER+1 ELSE CONT[ITERATION_NUMBER-1] END, -- Если рассмотрены все цифры обрабатываемого числа и сумма все еще больше 9, берем за номер новой служебной строки следующую строку (так как на следующей итерации будет занесена вся служебная информация обновления цикла), иначе принимаем то же значение, что и на предыдущей итерации
SIGN[ITERATION_NUMBER] = CASE WHEN FL[ITERATION_NUMBER] = LENGTH(ST[CONT[ITERATION_NUMBER-1]]) AND SU[ITERATION_NUMBER] >= 10 THEN 1 ELSE 0 END, -- Если рассмотрены все цифры обрабатываемого числа и сумма все еще больше 9, задаем значение 1, иначе 0
SIGN[-1] = CASE WHEN FL[ITERATION_NUMBER] = LENGTH(ST[CONT[ITERATION_NUMBER-1]]) AND SU[ITERATION_NUMBER] < 10 THEN 1 ELSE SIGN[-1] END -- Если рассмотрены все цифры обрабатываемого числа и сумма меньше 10, задаем -1 строке значение 1, иначе оставляем прежним

)
)

-- Выводим получившийся результат (итоговая сумма будет посчитана в последней (имеющей максимальный идентификатор) строке)
SELECT '&ST' "Исходная строка",  SU "Результат"
FROM NUM_REP
WHERE ID = (SELECT MAX(ID) FROM NUM_REP);
