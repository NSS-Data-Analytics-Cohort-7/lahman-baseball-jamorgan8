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


-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT
    CONCAT(namelast, ', ', namefirst) AS name,
    SUM(salary) AS major_league_salary
FROM people AS p
LEFT JOIN collegeplaying AS c
    ON p.playerid = c.playerid
LEFT JOIN schools AS s1
    ON c.schoolid = s1.schoolid
LEFT JOIN salaries AS s2
    ON p.playerid = s2.playerid
WHERE schoolname = 'Vanderbilt University'
    AND SUM(salary) IS NOT NULL
GROUP BY name
ORDER BY major_league_salary DESC;



    
