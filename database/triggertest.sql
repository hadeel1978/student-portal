
-- 1. Register a student for an unrestricted course.
INSERT INTO Registrations(student, course) VALUES('verlot', 'TIN092');

-- 2. Register the same student for the same course again.
INSERT INTO Registrations(student, course) VALUES('verlot', 'TIN092');

-- 3. Unregister the student from the course.
DELETE FROM Registrations WHERE student = 'verlot' AND course = 'TIN092';

-- 4. Unregister the student again from the same course.
DELETE FROM Registrations WHERE student = 'verlot' AND course = 'TIN092';

-- 5. Register a student for a course that they have already passed.
INSERT INTO Registrations(student, course) VALUES('carpet', 'TIN092');

-- 6. Register a student for a course that they don't have the prerequisites for.
INSERT INTO Registrations(student, course) VALUES('verlot', 'TIN172');

/*
  Expected Output:
  1: 1 rows inserted
  2: ORA-20001: Already registered or waiting
  3: 1 rows deleted
  4: 0 rows deleted
  5: ORA-20002: Already passed course
  6: ORA-20003: Prerequisites not fulfilled
*/
