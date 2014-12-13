
/* Drop Everything */

begin
for c in (select table_name from user_tables) loop
execute immediate ('drop table '||c.table_name||' cascade constraints');
end loop;
end;
/
begin
for c in (select * from user_objects) loop
execute immediate ('drop '||c.object_type||' '||c.object_name);
end loop;
end;
/

/* Create All Tables */

CREATE TABLE Departments (
  abbr VARCHAR(8) PRIMARY KEY,
  name VARCHAR(64) UNIQUE NOT NULL
);

CREATE TABLE Programmes (
  abbr VARCHAR(8) PRIMARY KEY,
  name VARCHAR(64) UNIQUE NOT NULL
);

CREATE TABLE Branches (
  PRIMARY KEY(programme, name),
  programme VARCHAR(8) REFERENCES Programmes,
  name VARCHAR(32)
);

CREATE TABLE Courses (
  code CHAR(6) PRIMARY KEY,
  name VARCHAR(64) UNIQUE NOT NULL,
  credits INT NOT NULL CHECK(credits >= 0),
  department VARCHAR(8) NOT NULL REFERENCES Departments
);

CREATE TABLE Limited_Courses (
  code CHAR(6) PRIMARY KEY REFERENCES Courses,
  capacity INT NOT NULL CHECK(capacity > 0)
);

CREATE TABLE Classifications (
  type VARCHAR(32) PRIMARY KEY
);

CREATE TABLE Students (
  id CHAR(6) PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  programme VARCHAR(8) NOT NULL,
  branch VARCHAR(32) NOT NULL,
  FOREIGN KEY(programme, branch)
    REFERENCES Branches(programme, name)
);

CREATE TABLE Departments_Programmes (
  PRIMARY KEY(department, programme),
  department VARCHAR(8) REFERENCES Departments,
  programme VARCHAR(8) REFERENCES Programmes
);

CREATE TABLE Programme_Requirements (
  PRIMARY KEY(programme, course),
  programme VARCHAR(8) REFERENCES Programmes,
  course CHAR(6) REFERENCES Courses
);

CREATE TABLE Branch_Requirements (
  PRIMARY KEY(programme, branch, course),
  programme VARCHAR(8),
  branch VARCHAR(32),
  course CHAR(6) REFERENCES Courses,
  FOREIGN KEY(programme, branch)
    REFERENCES Branches(programme, name)
);

CREATE TABLE Branch_Recommendations (
  PRIMARY KEY(programme, branch, course),
  programme VARCHAR(8),
  branch VARCHAR(32),
  course CHAR(6) REFERENCES Courses,
  FOREIGN KEY(programme, branch)
    REFERENCES Branches(programme, name)
);

CREATE TABLE Course_Prerequisites (
  PRIMARY KEY(course, prereq),
  course CHAR(6) REFERENCES Courses,
  prereq CHAR(6) REFERENCES Courses
);

CREATE TABLE Course_Classifications (
  PRIMARY KEY(course, classification),
  course CHAR(6) REFERENCES Courses,
  classification VARCHAR(32) REFERENCES Classifications
);

CREATE TABLE Course_Queues (
  PRIMARY KEY(course, student),
  course CHAR(6) REFERENCES Limited_Courses,
  student CHAR(6) REFERENCES Students,
  counter INT NOT NULL CHECK(counter > 0),
  CONSTRAINT Unique_Counter UNIQUE(course, counter)
);

CREATE SEQUENCE Queue_Counter
  START WITH 1
  INCREMENT BY 1;

CREATE TABLE Students_Courses (
  PRIMARY KEY(student, course),
  student CHAR(6) REFERENCES Students,
  course CHAR(6) REFERENCES Courses
);

CREATE TABLE Student_Grades (
  PRIMARY KEY(student, course),
  student CHAR(6) REFERENCES Students,
  course CHAR(6) REFERENCES Courses,
  grade CHAR(1) NOT NULL,
  CONSTRAINT Valid_Grade CHECK(grade IN ('U','3','4','5'))
);
