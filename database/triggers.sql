
CREATE OR REPLACE VIEW Course_Queue_Positions AS
  SELECT course, student, row_number() OVER
         (PARTITION BY course ORDER BY counter) AS position
  FROM Course_Queues
  ORDER BY course;

CREATE OR REPLACE TRIGGER Course_Registration
  INSTEAD OF INSERT ON Registrations
  REFERENCING NEW AS new
  FOR EACH ROW
    DECLARE
      alreadyReg INT;
      hasPassed INT;
      prereqNum INT;
      isLimited INT;
      currNum INT;
      maxNum INT;
    BEGIN
      SELECT COUNT(*) INTO alreadyReg FROM Registrations
      WHERE student = :new.student AND course = :new.course;
      IF alreadyReg != 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Already registered or waiting');
      END IF;
      SELECT COUNT(*) INTO hasPassed FROM Passed_Courses
      WHERE student = :new.student AND course = :new.course;
      IF hasPassed != 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Already passed course');
      END IF;
      SELECT COUNT(*) INTO prereqNum FROM (
          SELECT prereq AS course
          FROM Course_Prerequisites WHERE course = :new.course
        MINUS
          SELECT course
          FROM Passed_Courses WHERE student = :new.student
      );
      IF prereqNum != 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Prerequisites not fulfilled');
      END IF;
      SELECT COUNT(*) INTO isLimited
      FROM Limited_Courses WHERE code = :new.course;
      IF isLimited != 0 THEN
        SELECT capacity INTO maxNum
        FROM Limited_Courses WHERE code = :new.course;
        SELECT COUNT(*) INTO currNum
        FROM Students_Courses WHERE course = :new.course;
        IF currNum < maxNum THEN
          INSERT INTO Students_Courses VALUES(:new.student, :new.course);
        ELSE
          INSERT INTO Course_Queues
            VALUES(:new.course, :new.student, Queue_Counter.nextval);
        END IF;
      ELSE
        INSERT INTO Students_Courses VALUES(:new.student, :new.course);
      END IF;
    END;
/

CREATE OR REPLACE TRIGGER Course_Unregistration
  INSTEAD OF DELETE ON Registrations
  REFERENCING OLD AS old
  FOR EACH ROW
    DECLARE
      firstInQueue Students.id%TYPE;
      waitingNum INT;
      currNum INT;
      maxNum INT;
    BEGIN
      DELETE FROM Course_Queues
      WHERE student = :old.student AND course = :old.course;
      DELETE FROM Students_Courses
      WHERE student = :old.student AND course = :old.course;
      SELECT COUNT(*) INTO waitingNum
      FROM Course_Queue_Positions WHERE course = :old.course;
      IF waitingNum > 0 THEN
        SELECT capacity INTO maxNum
        FROM Limited_Courses WHERE code = :old.course;
        SELECT COUNT(*) INTO currNum
        FROM Students_Courses WHERE course = :old.course;
        IF currNum < maxNum THEN
          SELECT student INTO firstInQueue
          FROM Course_Queue_Positions
          WHERE position = 1 AND course = :old.course;
          INSERT INTO Students_Courses VALUES(firstInQueue, :old.course);
          DELETE FROM Course_Queues
          WHERE student = firstInQueue AND course = :old.course;
        END IF;
      END IF;
    END;
/
