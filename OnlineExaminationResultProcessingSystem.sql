/*
ONLINE EXAMINATION RESULT PROCESSING SYSTEM

1. TABLE 
*/

CREATE TABLE exam_students (
    student_id   NUMBER PRIMARY KEY,
    student_name VARCHAR2(100),
    dob          DATE,
    course       VARCHAR2(50)
);

CREATE TABLE exam_subjects (
    subject_id   NUMBER PRIMARY KEY,
    subject_name VARCHAR2(50),
    max_marks    NUMBER
);

CREATE TABLE student_marks (
    student_id NUMBER,
    subject_id NUMBER,
    marks_obtained NUMBER,
    CONSTRAINT fk_stu FOREIGN KEY (student_id)
        REFERENCES exam_students(student_id),
    CONSTRAINT fk_sub FOREIGN KEY (subject_id)
        REFERENCES exam_subjects(subject_id)
);

CREATE TABLE exam_results (
    student_id NUMBER PRIMARY KEY,
    total_marks NUMBER,
    grade       VARCHAR2(2),
    result_status VARCHAR2(10),
    rank_no     NUMBER
);


/*
2. FUNCTION : GRADE CALCULATION
*/

CREATE OR REPLACE FUNCTION compute_grade (
    p_total NUMBER
)
RETURN VARCHAR2
IS
BEGIN
    IF p_total >= 450 THEN
        RETURN 'A';
    ELSIF p_total >= 350 THEN
        RETURN 'B';
    ELSIF p_total >= 250 THEN
        RETURN 'C';
    ELSE
        RETURN 'D';
    END IF;
END;
/
    

/*
3. PROCEDURE : PROCESS RESULTS
*/

CREATE OR REPLACE PROCEDURE generate_results
IS
    CURSOR c_students IS
        SELECT student_id, SUM(marks_obtained) total
        FROM student_marks
        GROUP BY student_id;

    v_grade VARCHAR2(2);
    v_status VARCHAR2(10);
BEGIN
    FOR rec IN c_students LOOP

        v_grade := compute_grade(rec.total);

        IF rec.total >= 200 THEN
            v_status := 'PASS';
        ELSE
            v_status := 'FAIL';
        END IF;

        INSERT INTO exam_results (
            student_id,
            total_marks,
            grade,
            result_status,
            rank_no
        )
        VALUES (
            rec.student_id,
            rec.total,
            v_grade,
            v_status,
            NULL
        );

    END LOOP;

    COMMIT;
END;
/
    

/*
4. PROCEDURE : RANK GENERATION
   (Cursor Based)
*/

CREATE OR REPLACE PROCEDURE assign_rank
IS
    CURSOR c_rank IS
        SELECT student_id
        FROM exam_results
        ORDER BY total_marks DESC;

    v_rank NUMBER := 0;
BEGIN
    FOR r IN c_rank LOOP
        v_rank := v_rank + 1;

        UPDATE exam_results
        SET rank_no = v_rank
        WHERE student_id = r.student_id;
    END LOOP;

    COMMIT;
END;
/
    

/*
5. TRIGGER : AUTO RESULT UPDATE
*/

CREATE OR REPLACE TRIGGER trg_result_check
BEFORE INSERT ON exam_results
FOR EACH ROW
BEGIN
    IF :NEW.total_marks < 200 THEN
        :NEW.result_status := 'FAIL';
    END IF;
END;
/
    

/*
6. EXCEPTION HANDLING EXAMPLE
*/

CREATE OR REPLACE PROCEDURE fetch_student_result (
    p_student_id IN NUMBER
)
IS
    v_total NUMBER;
    v_grade VARCHAR2(2);
BEGIN
    SELECT total_marks, grade
    INTO v_total, v_grade
    FROM exam_results
    WHERE student_id = p_student_id;

    DBMS_OUTPUT.PUT_LINE(
        'Total Marks: ' || v_total || ' Grade: ' || v_grade
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Result not available');
END;
/
    

/*
7. SAMPLE DATA & TESTING
*/

-- Students
INSERT INTO exam_students VALUES (1, 'Naman Kumar', DATE '2002-05-12', 'BSc');
INSERT INTO exam_students VALUES (2, 'abc efg', DATE '2001-11-22', 'BSc');

-- Subjects
INSERT INTO exam_subjects VALUES (101, 'Maths', 100);
INSERT INTO exam_subjects VALUES (102, 'Physics', 100);
INSERT INTO exam_subjects VALUES (103, 'Chemistry', 100);

-- Marks
INSERT INTO student_marks VALUES (1, 101, 85);
INSERT INTO student_marks VALUES (1, 102, 78);
INSERT INTO student_marks VALUES (1, 103, 80);

INSERT INTO student_marks VALUES (2, 101, 60);
INSERT INTO student_marks VALUES (2, 102, 55);
INSERT INTO student_marks VALUES (2, 103, 50);

COMMIT;

-- Process results
EXEC generate_results;

-- Generate ranks
EXEC assign_rank;

-- View results
SELECT * FROM exam_results;

-- Fetch individual result
EXEC fetch_student_result(1);
