--1. What range of years for baseball games played does the provided database cover?

SELECT 
    MIN(yearid),
    MAX(yearid)
FROM teams;

--Answer-- 1871-2016 (also found in data dictionary)

--2.Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT
    CONCAT(namelast, ', ', namefirst) AS name,
    height,
    g_all AS num_appearances,
    t.name AS team_name
FROM people AS p
LEFT JOIN appearances AS a
    ON p.playerid = a.playerid
LEFT JOIN teams AS t
    ON a.teamid = t.teamid
WHERE height IS NOT NULL
GROUP BY CONCAT(namelast, ', ', namefirst), g_all, height, team_name
ORDER BY height;

--Answer-- Eddie Gaedel, 43" tall, 1 appearance with St Louis Browns


/*3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?*/
               
             
SELECT
    CONCAT(namelast, ', ', namefirst) AS name,
    CAST(CAST(SUM(salary) AS NUMERIC) AS MONEY) AS major_league_salary
FROM collegeplaying AS c
LEFT JOIN people AS p
    ON c.playerid = p.playerid
LEFT JOIN salaries AS s2
    ON p.playerid = s2.playerid
WHERE schoolid = 'vandy'
GROUP BY name
HAVING SUM(salary) IS NOT NULL
ORDER BY major_league_salary DESC;

--ANSWER-- David Price, $245,553,888.00


/*4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.*/

SELECT
    CASE WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
         WHEN pos = 'P' OR pos = 'C' THEN 'Battery'
         ELSE 'Outfield'
         END AS position,
    SUM(po) AS putouts
FROM people AS p
LEFT JOIN fielding AS f
    ON p.playerid = f.playerid
WHERE f.yearid = 2016
GROUP BY position;

--ANSWER-- Battery= 41,424, Infield = 58,934, Outfield = 29,560
   
   
--5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any 
--trends?
WITH homeruns AS (
                    SELECT
                        yearid,
                        CAST(SUM(hr) AS DECIMAL)/CAST(SUM(g) AS DECIMAL) AS avg_homeruns
                    FROM teams
                    GROUP BY yearid
                  )
            
SELECT
    CASE WHEN sq.decade = 2010 THEN CONCAT(sq.decade, '-', sq.decade+6)
        ELSE CONCAT(sq.decade, '-', sq.decade+9) END AS decade,
    ROUND(AVG(avg_strikeouts),2) AS avg_strikeouts,
    ROUND(AVG(avg_homeruns),2) AS avg_homeruns
FROM(
        SELECT
            CAST(SUM(so) AS DECIMAL)/CAST(SUM(g) AS DECIMAL) AS avg_strikeouts,
            (yearid/10)*10 AS decade,
            yearid
         FROM teams
        WHERE ((yearid/10)*10) >= 1920
        GROUP BY decade, yearid
        ) AS sq
JOIN homeruns AS h
    ON sq.yearid = h.yearid
GROUP BY decade
ORDER BY decade;

/*to find avg strikeouts I divided sum of strikeouts by sum of games. In teams table, strikeouts and games are represented per team. I totaled ALL strikeouts and divided by ALL games to get the average per decade

For homeruns i created a CTE that is functionally the same as the subquery.*/
     
SELECT
    CASE WHEN (yearid/10)*10 = 2010 THEN CONCAT((yearid/10)*10, '-', ((yearid/10)*10)+6)
        ELSE CONCAT((yearid/10)*10, '-', ((yearid/10)*10)+9) END AS decade,
    ROUND(CAST(SUM(so) AS DECIMAL)/CAST(SUM(g)/2 AS DECIMAL), 2) AS avg_strikeouts,
    ROUND(CAST(SUM(hr) AS DECIMAL)/CAST(SUM(g)/2 AS DECIMAL), 2) AS avg_homeruns
FROM teams
WHERE ((yearid/10)*10) >= 1920
GROUP BY decade
ORDER BY decade;

--then i realized I could have done it all in one streamlined query...



--6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base 
--attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.


WITH steals AS 
            (SELECT
                playerid,
                SUM(sb)/CAST((SUM(sb)+SUM(cs)) AS NUMERIC) AS perc_steals
            FROM batting
            WHERE sb IS NOT NULL
                AND cs IS NOT NULL
                AND yearid = 2016
            GROUP BY playerid
            HAVING SUM(sb) + SUM(cs) >= 20
            ORDER BY perc_steals DESC)

SELECT
    CONCAT(namelast, ', ', namefirst) AS player_name,
    ROUND(perc_steals, 3) AS steal_perc
FROM people AS p
JOIN steals AS s
    ON p.playerid = s.playerid
ORDER BY steal_perc DESC;

--ANSWER-- Chris Owings, .913

-- 7.From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world 
--series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the --problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?


--most wins without winning world series
SELECT 
    yearid,
    teamid,
    w AS wins,
    wswin AS world_series_win
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
    AND wswin = 'N'
ORDER BY wins DESC;

--least wins and winning world series
SELECT 
    yearid,
    teamid,
    w AS wins,
    wswin AS world_series_win
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
    AND wswin = 'Y'
ORDER BY wins;

--Query to find teams that had the most wins AND won WS           
SELECT
    t.yearid,
    name,
    t.w AS num_wins,
    wswin AS world_series_win
FROM teams AS t
INNER JOIN
    (SELECT --most wins per year, join to teams table
        yearid,
        MAX(w) AS max_wins
     FROM teams
     GROUP BY yearid) AS sq
ON t.yearid = sq.yearid
GROUP BY t.yearid, max_wins, t.w, wswin, name
HAVING t.w = max_wins
    AND t.yearid <> 1981
    AND t.yearid BETWEEN 1970 AND 2016
    AND wswin = 'Y'
ORDER BY yearid;


WITH most_wins AS 
               (SELECT
                    t.yearid,
                    name,
                    t.w AS num_wins,
                    wswin AS world_series_win
                FROM teams AS t
                INNER JOIN
                    (SELECT --most wins per year, join to teams table
                        yearid,
                        MAX(w) AS max_wins
                     FROM teams
                     GROUP BY yearid) AS sq
                ON t.yearid = sq.yearid
                GROUP BY t.yearid, max_wins, t.w, wswin, name
                HAVING t.w = max_wins
                    AND t.yearid <> 1981
                    AND t.yearid BETWEEN 1970 AND 2016
                    AND wswin = 'Y'
                ORDER BY yearid)

SELECT
   ROUND(100*COUNT(mw.yearid)::NUMERIC/(SELECT COUNT(DISTINCT yearid) 
                                          FROM teams
                                         WHERE yearid BETWEEN 1970 AND 2016), 2) AS perc_wins 
FROM most_wins AS mw;


--ANSWER-- Seattle Mariners had 116 wins, but didn't win the World Series in 2001 . LA Dodgers has 63 wins and won the World Series in 1981. The small number of games was due to a players strike. Only 103-111 official games were played that year



--8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined --as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat --for the lowest 5 average attendance.


SELECT
    team,
    p.park_name,
    attendance/games AS avg_attendance
FROM homegames AS h
LEFT JOIN parks AS p
    ON h.park = p.park
WHERE year = 2016
    AND games >= 10
ORDER BY avg_attendance;


--ANSWER--
/*HIGHEST
"LAN"	"Dodger Stadium"	45719
"SLN"	"Busch Stadium III"	42524
"TOR"	"Rogers Centre"	41877
"SFN"	"AT&T Park"	41546
"CHN"	"Wrigley Field"	39906

LOWEST
"TBA"	"Tropicana Field"	15878
"OAK"	"Oakland-Alameda County Coliseum"	18784
"CLE"	"Progressive Field"	19650
"MIA"	"Marlins Park"	21405
"CHA"	"U.S. Cellular Field"	21559 */


--9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were
--managing when they won the award.


WITH nl AS
        (SELECT 
            a.playerid,
            COUNT(a.lgid),
            a.awardid,
            m.teamid
        FROM awardsmanagers AS a
        JOIN managers AS m
            ON a.yearid = m.yearid AND a.playerid = m.playerid
        WHERE a.awardid LIKE 'TSN%'
            AND a.lgid = 'NL'
        GROUP BY a.playerid, a.lgid, a.awardid, m.teamid),
    
    al AS
        (SELECT 
            a.playerid,
            COUNT(a.lgid),
            a.awardid,
            m.teamid
        FROM awardsmanagers AS a
        JOIN managers AS m
            ON a.yearid = m.yearid AND a.playerid = m.playerid
        WHERE a.awardid LIKE 'TSN%'
            AND a.lgid = 'AL'
        GROUP BY a.playerid, a.lgid, a.awardid, m.teamid)
SELECT
    namelast || ', ' || namefirst AS name,
    al.teamid || '/' || nl.teamid AS teams
FROM people AS p
JOIN nl
    ON p.playerid = nl.playerid
LEFT JOIN al
    ON p.playerid = al.playerid
WHERE nl.playerid = al.playerid
GROUP BY name, al.teamid, nl.teamid;

--ANSWER--
/*"Johnson, Davey"	"BAL/WAS"
"Leyland, Jim"	"DET/PIT"*/


--10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least --one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

WITH max_homers AS 
               (SELECT
                    playerid,
                    MAX(hr) AS career_highest
                FROM batting
                GROUP BY playerid
                ORDER BY career_highest DESC)

SELECT
    p.namelast || ', ' || p.namefirst AS name,
    SUM(hr) AS homeruns
FROM batting AS b
LEFT JOIN people AS p
    ON b.playerid = p.playerid
JOIN max_homers AS m
    ON b.playerid = m.playerid
WHERE hr >= 1
    AND yearid = 2016
    AND debut :: DATE <= '2006-12-31'
    AND b.hr = m.career_highest
GROUP BY name
ORDER BY homeruns DESC;

--ANSWER--
/*
"Encarnacion, Edwin"	42
"Cano, Robinson"	39
"Napoli, Mike"	34
"Davis, Rajai"	12
"Pagan, Angel"	12
"Wainwright, Adam"	2
"Liriano, Francisco"	1
"Colon, Bartolo"	1
*/


--11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries --across the whole league tend to increase together, so you may want to look on a year-by-year basis.

--Query to look at team salaries
WITH salaries_2000 AS (SELECT yearid, teamid, SUM(salary)::NUMERIC::MONEY AS team_salary -- CTE to calculate total team salary (combined player salaries)
                         FROM salaries
                        GROUP BY yearid, teamid
                        ORDER BY yearid)
SELECT s.yearid,
       s.teamid,
       team_salary,
       w AS wins
FROM   salaries_2000 AS s
LEFT JOIN teams AS t
    ON s.yearid = t.yearid
     AND s.teamid = t.teamid
WHERE  s.yearid >= 2000
    AND s.teamid = 'MIN'
GROUP BY s.teamid, s.yearid, team_salary, wins
ORDER BY yearid, team_salary;

--team salary does appear to be loosely tied to wins. Teams with a generally consistent record tend to show and upwards curve where teams with an inconsistent record tend to --have ups in downs in salary that is loosely tied to their wins

 
--this query totales overal league salary by year 
WITH salaries_2000 AS (SELECT yearid, teamid, SUM(salary)::NUMERIC::MONEY AS team_salary 
                         FROM salaries
                        GROUP BY yearid, teamid
                        ORDER BY yearid)
SELECT s.yearid,
       SUM(team_salary)
FROM   salaries_2000 AS s
LEFT JOIN teams AS t
  ON s.yearid = t.yearid
  AND s.teamid = t.teamid
WHERE  s.yearid >= 2000
GROUP BY s.yearid
ORDER BY yearid;


/* Year by year the league salary trends upwards. The total league salary has more than doubled since 2000
2000	"$1,666,135,102.00"
2001	"$1,960,663,313.00"
2002	"$2,024,077,522.00"
2003	"$2,128,262,128.00"
2004	"$2,070,665,943.00"
2005	"$2,188,713,398.00"
2006	"$2,321,472,617.00"
2007	"$2,476,688,987.00"
2008	"$2,684,858,670.00"
2009	"$2,664,726,994.00"
2010	"$2,721,359,865.00"
2011	"$2,784,505,291.00"
2012	"$2,932,741,192.00"
2013	"$3,034,525,648.00"
2014	"$3,192,317,623.00"
2015	"$3,514,142,569.00"
2016	"$3,750,137,392.00" */

