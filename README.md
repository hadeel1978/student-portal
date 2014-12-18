Student Portal
==============
This is a laboration in designing, constructing and using Oracle RDBMS for a database course at Chalmers. The database handles students and courses at a university.

Design
------
The E-R diagram is based on [this domain description](design/README.md). It has then been translated, using mechanical translation rules, into a database schema and functional dependencies.

![diagram](design/diagram.png?raw=true)

Database
--------
Run `setup.sql` to set up the database with tables, views, triggers and example data. It is then possible to test the triggers with `triggertest.sql`. The Oracle system used for the laboration does unfortunately not allow use of privileges, they are therefore only imagined in the client.

Client
------
The client is intended for students of the university. It's a basic CLI that connects to the Oracle database using JDBC. A student can simply "login" to the Student Portal using a student ID, the student can then register and unregister from courses etc.
