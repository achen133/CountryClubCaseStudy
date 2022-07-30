/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
SELECT 
    name
FROM Facilities
WHERE membercost > 0
ORDER BY membercost DESC;


/* Q2: How many facilities do not charge a fee to members? */
SELECT
    COUNT(*)
FROM Facilities
WHERE membercost = 0; # ANS: 4 facilities


/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT
	facid,
    name,
    membercost,
	monthlymaintenance
FROM Facilities
WHERE membercost < monthlymaintenance * 0.2 AND membercost > 0
ORDER BY membercost DESC;


/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT *
FROM Facilities
WHERE facid IN (1, 5)
ORDER BY facid;


/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT
    name,
	monthlymaintenance,
	CASE WHEN monthlymaintenance <= 100 AND monthlymaintenance >= 0 THEN 'cheap'
		WHEN monthlymaintenance > 100 THEN 'expensive'
		ELSE NULL END AS price_label
FROM Facilities
ORDER BY membercost DESC;


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
SELECT
	CONCAT_WS(' ', firstname, surname) AS fullname
FROM Members
WHERE joindate = (SELECT MAX(joindate) FROM Members);


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
SELECT
    f.name as facilityname,
	CONCAT_WS(" ", m.firstname, m.surname) AS fullname
FROM (
    SELECT DISTINCT facid, memid
	FROM Bookings
	WHERE memid != 0 AND facid IN (SELECT facid FROM Facilities WHERE name LIKE "Tennis Court%")
) AS tennis_bookings
LEFT JOIN Facilities as f
	ON tennis_bookings.facid = f.facid
LEFT JOIN Members as m
	ON tennis_bookings.memid = m.memid
ORDER BY fullname, facilityname;


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */
SELECT
	f.name as facilityname,
	CASE WHEN b.memid = 0 THEN m.firstname 
		ELSE CONCAT_WS(" ", m.firstname, m.surname) END AS fullname,
    CASE WHEN b.memid = 0 THEN ROUND((b.slots*f.guestcost), 2)
        WHEN b.memid > 0 THEN ROUND((b.slots*f.membercost), 2)
		ELSE NULL END AS cost
FROM Bookings as b
LEFT JOIN Facilities as f
	ON b.facid = f.facid
LEFT JOIN Members as m
	ON b.memid = m.memid
WHERE b.starttime LIKE "2012-09-14%"
HAVING cost > 30
ORDER BY cost DESC, fullname;


/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT
	s.name as facilityname,
	CASE WHEN s.memid = 0 THEN m.firstname 
		ELSE CONCAT_WS(" ", m.firstname, m.surname) END AS fullname,
    s.cost
FROM (
    SELECT
    	f.name,
    	b.memid,
    	CASE WHEN b.memid = 0 THEN ROUND((b.slots*f.guestcost), 2)
        WHEN b.memid > 0 THEN ROUND((b.slots*f.membercost), 2)
		ELSE NULL END AS cost
    FROM Bookings as b
	LEFT JOIN Facilities as f
		ON b.facid = f.facid
	WHERE b.starttime LIKE "2012-09-14%") AS s
LEFT JOIN Members as m
	ON s.memid = m.memid
WHERE cost > 30
ORDER BY cost DESC, fullname;

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
SELECT
	s.name as facilityname,
	SUM(s.cost) AS total_revenue
FROM (
    SELECT
    f.name,
    f.facid,
    CASE WHEN b.memid = 0 THEN ROUND((b.slots*f.guestcost), 2)
		WHEN b.memid > 0 THEN ROUND((b.slots*f.membercost), 2)
		ELSE NULL END AS cost
	FROM Bookings as b
	LEFT JOIN Facilities as f
		ON b.facid = f.facid) AS s
GROUP BY s.facid
HAVING total_revenue < 1000
ORDER BY total_revenue;

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
SELECT 
	CONCAT_WS(", ", s.surname, s.firstname) AS member_name,
	CASE WHEN m.memid > 0 THEN CONCAT_WS(", ", m.surname, m.firstname)
		ELSE 'NONE' END AS recommended_by
FROM (
    SELECT
	memid,
	firstname,
	surname,
	recommendedby
    FROM Members) AS s
LEFT JOIN Members as m
	ON s.recommendedby = m.memid
WHERE s.memid > 0
ORDER BY s.surname, s.firstname;


/* Q12: Find the facilities with their usage by member, but not guests */
SELECT
	m.fullname,
	f.facid,
	f.name as facilityname,
	s.hours_used
FROM (
    SELECT
		memid,
		CONCAT_WS(' ', firstname, surname) AS fullname
	FROM Members
	WHERE memid > 0) as m
LEFT JOIN (
    SELECT
		memid,
		facid,
		SUM(slots * 0.5) as hours_used
	FROM Bookings
	WHERE memid > 0
	GROUP BY memid, facid) AS s
	ON m.memid = s.memid
LEFT JOIN Facilities as f
	ON f.facid = s.facid
ORDER BY s.hours_used DESC;

/* Q13: Find the facilities usage by month, but not guests */
SELECT
	starttime,
	memid,
	facid,
	SUM(slots * 0.5) as hours_used
FROM Bookings
GROUP BY EXTRACT(MONTH FROM starttime), facid;