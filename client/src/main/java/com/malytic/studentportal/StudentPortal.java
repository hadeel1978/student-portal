package com.malytic.studentportal;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;

import oracle.jdbc.OracleDriver;

/**
 * Student Portal
 *
 * @author malytic
 */
public class StudentPortal {

    private static final String URL =
        "jdbc:oracle:thin:@db.student.chalmers.se:1521/kingu.ita.chalmers.se";

    private static final int ALREADY_REGISTERED_EXCEPTION    = 20001;
    private static final int ALREADY_PASSED_COURSE_EXCEPTION = 20002;
    private static final int MISSING_PREREQUISITES_EXCEPTION = 20003;

    public static void main(String[] args) {

        if (args.length < 2) {
            System.err.println("Missing arguments!");
            System.exit(1);
        }

        final String username = args[0];
        final String password = args[1];
        final Scanner scanner = new Scanner(System.in);

        Connection db = null;
        try {
            System.out.println("Connecting to database...");
            DriverManager.registerDriver(new OracleDriver());
            db = DriverManager.getConnection(URL, username, password);
            System.out.println("Successfully connected!");
        } catch (SQLException e) {
            System.err.println("Unable to connect to " + URL);
            System.err.println(e.getMessage());
            System.exit(2);
        }

        String student = null;
        while (true) {
            while (student == null) {
                System.out.println();
                System.out.println("Please login with student ID:");
                System.out.print("> ");
                student = verifyStudent(db, scanner.nextLine().toLowerCase());
            }
            System.out.println();
            System.out.println(" Student Portal ");
            System.out.println("****************");
            System.out.println(" 1) Student information");
            System.out.println(" 2) Register for course");
            System.out.println(" 3) Unregister from course");
            System.out.println(" 0) Logout " + student);
            System.out.println();
            System.out.print("Enter an option: ");
            if (scanner.hasNextInt()) {
                switch (Integer.parseInt(scanner.nextLine())) {
                case 1:
                    getInformation(db, student);
                    break;
                case 2:
                    System.out.println();
                    System.out.println("Register for what course?");
                    System.out.print("> ");
                    register(db, student, scanner.nextLine().toUpperCase());
                    break;
                case 3:
                    System.out.println();
                    System.out.println("Unregister from what course?");
                    System.out.print("> ");
                    unregister(db, student, scanner.nextLine().toUpperCase());
                    break;
                case 0:
                    System.out.println();
                    System.out.println("Successfully logged out " + student);
                    student = null;
                    break;
                default:
                    System.out.println("Unknown option!");
                    break;
                }
            } else {
                System.out.println("Bad input!");
                scanner.nextLine();
            }
            if (student != null) {
                System.out.println();
                System.out.print("Press enter to continue...");
                scanner.nextLine();
            }
        }
    }

    private static String verifyStudent(Connection db, String student) {

        String query = "SELECT * FROM Students_Following " +
                       "WHERE student = '" + student + "'";
        try {
            ResultSet results = db.createStatement().executeQuery(query);
            results.next();
            return results.getString(1);
        } catch (SQLException e) {
            System.out.println("Incorrect student ID!");
            return null;
        }
    }

    private static void getInformation(Connection db, String student) {

        try {
            System.out.println();
            System.out.println("-------------------------------");
            System.out.println("Student information for " + student);
            System.out.println("-------------------------------");

            String getStudent = "SELECT * FROM Students_Following " +
                                "WHERE student = '" + student + "'";
            ResultSet students = db.createStatement().executeQuery(getStudent);
            students.next();
            String studentName = students.getString(2);
            String progAbbr = students.getString(3);
            String progName = students.getString(4);
            String branch = students.getString(5);
            System.out.println("Name:   " + studentName);
            System.out.println("Line:   " + progName + " (" + progAbbr + ")");
            System.out.println("Branch: " + branch);

            String getCourses = "SELECT * FROM Finished_Courses " +
                                "WHERE student = '" + student + "'";
            ResultSet courses = db.createStatement().executeQuery(getCourses);
            if (courses.isBeforeFirst()) {
                System.out.println();
                System.out.println("Finished courses:");
            }
            while (courses.next()) {
                String courseCode = courses.getString(2);
                String grade = courses.getString(3);
                String getCourse = "SELECT * FROM Courses " +
                                   "WHERE code = '" + courseCode + "'";
                ResultSet course = db.createStatement().executeQuery(getCourse);
                course.next();
                String courseName = course.getString(2);
                String credits = course.getString(3);

                System.out.println("- " + courseCode + " " + courseName +
                                   ", " + credits + "p: " + grade);
            }

            String getRegs = "SELECT * FROM Registrations " +
                             "WHERE student = '" + student + "'";
            ResultSet regs = db.createStatement().executeQuery(getRegs);
            if (regs.isBeforeFirst()) {
                System.out.println();
                System.out.println("Registered courses:");
            }
            while (regs.next()) {
                String courseCode = regs.getString(2);
                String regStatus = regs.getString(3);
                String getCourse = "SELECT * FROM Courses " +
                                   "WHERE code = '" + courseCode + "'";
                ResultSet course = db.createStatement().executeQuery(getCourse);
                course.next();
                String courseName = course.getString(2);
                String credits = course.getString(3);

                if (regStatus.equals("waiting")) {
                    String getPos = "SELECT * FROM Course_Queue_Positions " +
                                    "WHERE course = '" + courseCode + "'" +
                                    " AND student = '" + student + "'";
                    ResultSet pos = db.createStatement().executeQuery(getPos);
                    if (pos.next()) {
                        int position = pos.getInt(3);
                        regStatus = "waiting as nr " + position;
                    }
                }
                System.out.println("- " + courseCode + " " + courseName +
                                   ", " + credits + "p: " + regStatus);
            }

            String getGradPath = "SELECT * FROM Path_To_Graduation " +
                                 "WHERE student = '" + student + "'";
            ResultSet paths = db.createStatement().executeQuery(getGradPath);
            paths.next();
            int passed_credits = paths.getInt(2);
            int remaining_courses = paths.getInt(3);
            int branch_credits = paths.getInt(4);
            int math_credits = paths.getInt(5);
            int research_credits = paths.getInt(6);
            int passed_seminars = paths.getInt(7);
            int graduating = paths.getInt(8);
            String qualified = graduating == 1 ? "yes" : "no";
            System.out.println();
            System.out.println("Remaining courses:        " + remaining_courses);
            System.out.println("Branch credits taken:     " + branch_credits);
            System.out.println("Seminar courses taken:    " + passed_seminars);
            System.out.println("Math credits taken:       " + math_credits);
            System.out.println("Research credits taken:   " + research_credits);
            System.out.println("Total credits taken:      " + passed_credits);
            System.out.println("Qualified for graduation: " + qualified);
            System.out.println("-------------------------------");

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            System.exit(2);
        }
    }

    private static void register(Connection db, String student, String course) {

        String courseName = null;
        try {
            String getCourse = "SELECT * FROM Courses " +
                               "WHERE code = '" + course + "'";
            ResultSet courseInfo = db.createStatement().executeQuery(getCourse);
            courseInfo.next();
            courseName = courseInfo.getString(2);
        } catch (SQLException e) {
            System.out.println("Unknown course code!");
            return;
        }

        try {
            String insertReg = "INSERT INTO Registrations(student, course) " +
                               "VALUES('" + student + "', '" + course + "')";
            int response = db.createStatement().executeUpdate(insertReg);
            System.out.println();
            if (response == 1) {
                String getPos = "SELECT * FROM Course_Queue_Positions " +
                                "WHERE course = '" + course + "'" +
                                " AND student = '" + student + "'";
                ResultSet pos = db.createStatement().executeQuery(getPos);
                if (pos.next()) {
                    int position = pos.getInt(3);
                    System.out.println("Course " + course + " " + courseName +
                                       " is full, " + student);
                    System.out.println("is put on the waiting list as" +
                                       " number " + position);
                } else {
                    System.out.println("Successfully registered " + student);
                    System.out.println("to course " + course + " " + courseName);
                }
            } else {
                System.err.println("Unknown error!");
                System.exit(3);
            }
        } catch (SQLException e) {
            System.out.println();
            switch (e.getErrorCode()) {
            case ALREADY_REGISTERED_EXCEPTION:
                System.out.println(student + " is already registered");
                System.out.println("to course " + course + " " + courseName);
                break;
            case ALREADY_PASSED_COURSE_EXCEPTION:
                System.out.println(student + " has already passed");
                System.out.println("course " + course + " " + courseName);
                break;
            case MISSING_PREREQUISITES_EXCEPTION:
                System.out.println(student + " doesn't fulfill the prerequisites");
                System.out.println("for course " + course + " " + courseName);
                break;
            default:
                System.err.println(e.getMessage());
                System.exit(2);
            }
        }
    }

    private static void unregister(Connection db, String student, String course) {

        String courseName = null;
        try {
            String getCourse = "SELECT * FROM Courses " +
                               "WHERE code = '" + course + "'";
            ResultSet courseInfo = db.createStatement().executeQuery(getCourse);
            courseInfo.next();
            courseName = courseInfo.getString(2);
        } catch (SQLException e) {
            System.out.println("Unknown course code!");
            return;
        }

        try {
            String deleteReg = "DELETE FROM Registrations " +
                               "WHERE course = '" + course + "'" +
                               " AND student = '" + student + "'";
            int response = db.createStatement().executeUpdate(deleteReg);
            System.out.println();
            if (response == 1) {
                System.out.println("Successfully unregistered " + student);
                System.out.println("from course " + course + " " + courseName);
            } else {
                System.out.println(student + " is not registered to");
                System.out.println("course " + course + " " + courseName);
            }
        } catch (SQLException e) {
            System.err.println(e.getMessage());
            System.exit(2);
        }
    }
}
