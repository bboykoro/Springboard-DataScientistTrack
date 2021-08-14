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
Username:
Password: 

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
*/

SELECT name FROM Facilities WHERE membercost <> 0;

/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT(*) FROM Facilities WHERE membercost = 0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance FROM Facilities WHERE membercost < monthlymaintenance * 0.2;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT F.*, B.bookid, B.starttime, B.slots, M.*
FROM Facilities AS F
LEFT JOIN Bookings AS B
ON F.facid = B.facid
LEFT JOIN Members AS M
ON B.memid = M.memid 
WHERE F.facid IN (1, 5) AND B.facid IN (1, 5) AND M.memid IN (SELECT memid FROM Bookings WHERE facid IN (1, 5))
ORDER BY F.facid, M.memid;

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance, CASE WHEN monthlymaintenance > 1000 THEN 'very expensive' WHEN monthlymaintenance > 100 THEN 'expensive' ELSE 'cheap' END AS cost_label
FROM Facilities
ORDER BY facid;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname, joindate FROM Members
WHERE joindate = (SELECT MAX(joindate) FROM Members)

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT CONCAT(M.firstname, ' ', M.surname, ' used tennis court.') AS Who_used_Tenniscourt
FROM Facilities AS F
LEFT JOIN Bookings AS B
ON F.facid = B.facid
LEFT JOIN Members AS M
ON B.memid = M.memid
WHERE F.facid = B.facid AND B.memid = M.memid AND F.name LIKE 'Tennis%'
ORDER BY M.firstname;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT CASE WHEN M.firstname <> M.surname THEN CONCAT(M.firstname, ' ', M.surname, ' used ', F.name) 
			ELSE CONCAT(M.firstname, ' (Booking#:', B.bookid, ')', ' used ', F.name) END AS facility_usage_2012_09_14, 
	   CASE WHEN B.memid <> 0 THEN F.membercost * B.slots + 30 
			ELSE F.guestcost * B.slots + 30 END AS cost_USD
FROM Facilities AS F
LEFT JOIN Bookings AS B
ON F.facid = B.facid
LEFT JOIN Members AS M
ON B.memid = M.memid
WHERE F.facid = B.facid AND B.memid = M.memid AND B.starttime LIKE '2012-09-14%'
ORDER BY cost_USD DESC;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT CASE WHEN s.firstname <> s.surname THEN CONCAT(s.firstname, ' ', s.surname, ' used ', s.name) 
	   ELSE CONCAT(s.firstname, ' (Booking#:', s.bookid, ')', ' used ', s.name) END AS facility_usage_2012_09_14,
	   CASE WHEN s.memid <> 0 THEN s.membercost * s.slots + 30 
	   ELSE s.guestcost * s.slots + 30 END AS cost_USD
FROM (
    SELECT 
    M.firstname, M.surname, F.name, B.bookid, B.memid, B.slots, F.membercost, F.guestcost 
    FROM Facilities AS F
    LEFT JOIN Bookings AS B
    ON F.facid = B.facid
    LEFT JOIN Members AS M
    ON B.memid = M.memid
    WHERE F.facid = B.facid AND B.memid = M.memid AND B.starttime LIKE '2012-09-14%') AS s
ORDER BY cost_USD DESC;

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
*/

with engine.connect() as con:
    rs = con.execute("WITH Summary AS (SELECT F.name, SUM(CASE WHEN B.memid <> 0 THEN F.membercost * B.slots ELSE 0 END) + SUM(CASE WHEN B.memid = 0 THEN F.guestcost * B.slots ELSE 0 END) - F.initialoutlay - (AVG(F.monthlymaintenance) * (strftime('%m', MAX(starttime)) - strftime('%m', MIN(starttime)) + 1)) AS total_revenue FROM Facilities AS F LEFT JOIN Bookings AS B ON F.facid = B.facid GROUP BY F.name) SELECT name, total_revenue FROM Summary AS S WHERE S.total_revenue < 1000 ORDER BY total_revenue;")    
    df = pd.DataFrame(rs.fetchall())
    df.columns = rs.keys()
print(df)

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

with engine.connect() as con:
    rs = con.execute("WITH m1 AS (SELECT memid, 'ID#'||memid||': '||surname||', '|| firstname AS recommended_by FROM Members) SELECT m.memid, m.surname, m.firstname, m.address, m.zipcode, m.telephone, m.joindate, CASE WHEN m.recommendedby <> 0 THEN m1.recommended_by ELSE NULL END AS recommender_ID_surname_firstname FROM Members AS m LEFT JOIN m1 ON m.recommendedby = m1.memid ORDER BY m.surname, m.firstname;")    
    df = pd.DataFrame(rs.fetchall())
    df.columns = rs.keys()
print(df)

/* Q12: Find the facilities with their usage by member, but not guests */

with engine.connect() as con:
    rs = con.execute("SELECT f.name, COUNT(bookid) AS usage_by_member, MIN(strftime('%Y/%m/%d', starttime))||' - '||MAX(strftime('%Y/%m/%d', starttime)) AS period FROM Facilities AS f LEFT JOIN Bookings AS b ON f.facid = b.facid WHERE memid <> 0 GROUP BY f.name;")    
    df = pd.DataFrame(rs.fetchall())
    df.columns = rs.keys()
print(df)

/* Q13: Find the facilities usage by month, but not guests */
with engine.connect() as con:
    rs = con.execute("WITH usage7 AS (SELECT facid, COUNT(starttime) AS July FROM Bookings WHERE strftime('%m', starttime) = '07' AND memid <> 0 GROUP BY facid), usage8 AS (SELECT facid, COUNT(*) AS August FROM Bookings WHERE strftime('%m', starttime) = '08' AND memid <> 0 GROUP BY facid), usage9 AS (SELECT facid, COUNT(*) AS September FROM Bookings WHERE strftime('%m', starttime) = '09' AND memid <> 0 GROUP BY facid), main AS (SELECT f.facid, f.name FROM Facilities AS f LEFT JOIN Bookings AS b ON f.facid = b.facid WHERE b.memid <> 0 GROUP BY f.facid) SELECT ma.name, u7.July AS usage_Jul, u8.August AS usage_Aug, u9.September AS usage_Sep FROM main AS ma LEFT JOIN usage7 AS u7 ON ma.facid = u7.facid LEFT JOIN usage8 AS u8 ON ma.facid = u8.facid LEFT JOIN usage9 AS u9 ON ma.facid = u9.facid")    
    df = pd.DataFrame(rs.fetchall())
    df.columns = rs.keys()
print(df)


