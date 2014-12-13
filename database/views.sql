
CREATE OR REPLACE VIEW Students_Following AS
  SELECT id AS student, programme, branch
  FROM Students;

CREATE OR REPLACE VIEW Finished_Courses AS
  SELECT *
  FROM Student_Grades;

CREATE OR REPLACE VIEW Registrations AS
    SELECT student, course, 'registered' AS status
    FROM Students_Courses
  UNION
    SELECT student, course, 'waiting' AS status
    FROM Course_Queues
  ORDER BY student;

CREATE OR REPLACE VIEW Passed_Courses AS
  SELECT student, course, credits
  FROM Finished_Courses
  JOIN Courses ON code = course
  WHERE grade != 'U';

CREATE OR REPLACE VIEW Unread_Mandatory AS
    SELECT student, course
    FROM Students_Following
    NATURAL JOIN Programme_Requirements
  UNION
    SELECT student, course
    FROM Students_Following
    NATURAL JOIN Branch_Requirements
  MINUS
    SELECT student, course
    FROM Passed_Courses
  ORDER BY student;

CREATE OR REPLACE VIEW Path_To_Graduation AS
  WITH Passed_Credits AS (
    SELECT student, SUM(credits) AS passed_credits
    FROM Passed_Courses
    GROUP BY student
  ),
  Remaining_Courses AS (
    SELECT student, COUNT(*) AS remaining_courses
    FROM Unread_Mandatory
    GROUP BY student
  ),
  Passed_Branch_Courses AS (
      SELECT student, course
      FROM Students_Following
      NATURAL JOIN Branch_Requirements
    UNION
      SELECT student, course
      FROM Students_Following
      NATURAL JOIN Branch_Recommendations
    INTERSECT
      SELECT student, course
      FROM Passed_Courses
  ),
  Branch_Credits AS (
    SELECT student, SUM(credits) AS branch_credits
    FROM Passed_Branch_Courses
    JOIN Courses ON course = code
    GROUP BY student
  ),
  Math_Credits AS (
    SELECT student, SUM(credits) AS math_credits
    FROM Passed_Courses
    NATURAL JOIN Course_Classifications
    WHERE classification = 'mathematical'
    GROUP BY student
  ),
  Research_Credits AS (
    SELECT student, SUM(credits) AS research_credits
    FROM Passed_Courses
    NATURAL JOIN Course_Classifications
    WHERE classification = 'research'
    GROUP BY student
  ),
  Passed_Seminars AS (
    SELECT student, COUNT(*) AS passed_seminars
    FROM Passed_Courses
    NATURAL JOIN Course_Classifications
    WHERE classification = 'seminar'
    GROUP BY student
  )
  SELECT student,
    NVL(passed_credits, 0)    AS passed_credits,
    NVL(remaining_courses, 0) AS remaining_courses,
    NVL(branch_credits, 0)    AS branch_credits,
    NVL(math_credits, 0)      AS math_credits,
    NVL(research_credits, 0)  AS research_credits,
    NVL(passed_seminars, 0)   AS passed_seminars,
    CASE
      WHEN
        remaining_courses IS NULL AND
        branch_credits >= 10 AND
        math_credits >= 20 AND
        research_credits >= 20 AND
        passed_seminars >= 1
      THEN 1
      ELSE 0
    END AS graduating
  FROM Students_Following
  NATURAL LEFT OUTER JOIN Passed_Credits
  NATURAL LEFT OUTER JOIN Remaining_Courses
  NATURAL LEFT OUTER JOIN Branch_Credits
  NATURAL LEFT OUTER JOIN Math_Credits
  NATURAL LEFT OUTER JOIN Research_Credits
  NATURAL LEFT OUTER JOIN Passed_Seminars
  ORDER BY student;
