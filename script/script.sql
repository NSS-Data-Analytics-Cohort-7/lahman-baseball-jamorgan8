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

SELECT
    CASE WHEN sq.decade = 2010 THEN CONCAT(sq.decade, '-', sq.decade+6)
        ELSE CONCAT(sq.decade, '-', sq.decade+9) END AS decade,
    ROUND(AVG(avg_strikeouts), 2) AS avg_strikeouts
FROM(
        SELECT
            CAST(SUM(so) AS DECIMAL)/CAST(SUM(g) AS DECIMAL) AS avg_strikeouts,
            (yearid/10)*10 AS decade,
            g/2 AS num_games,
            COUNT(teamid) AS team
        FROM teams
        WHERE ((yearid/10)*10) >= 1920
        GROUP BY decade, num_games
    ) AS sq
GROUP BY decade
ORDER BY decade;

/*to find avg strikeouts I divided sum of strikeouts by sum of games. In teams table, strikeouts and games are represented per team. I totaled ALL strikeouts and divided by ALL games to get the average per decade*/


