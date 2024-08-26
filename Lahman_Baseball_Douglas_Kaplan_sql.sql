--1. What range of years for baseball games played does the provided database cover?

select 
	min(year) as first_year
	, max(year) as last_year
	, count (distinct year) num_years
from homegames h;

-- 2. Find the name and height of the shortest player in the database. peope
--How many games did he play in? 
--What is the name of the team for which he played?

select 
	s.namefirst,
	s.namelast,
	t.name,
	s.minHeight,
	a.g_all
from appearances a
inner join 
	(
		select
			namefirst,
			namelast,
			playerid,
			min(height) as minHeight
		from people p
		group by 1,2,3
		having  min(height) > 0
		order by minHeight 
		limit 1
	) s
	on a.playerid = s.playerid
inner join 
	(
		select
			teamid,
			yearid,
			name
		from teams
	) t
	on a.teamid = t.teamid
	and a.yearid = t.yearid;

select
	p.namefirst,
	p.namelast,
	a.g_all as games_played,
	t.name
from people p
inner join appearances a
	on p.playerid = a.playerid 
inner join teams t
	on a.teamid = t.teamid
	and a.yearid = t.yearid
where height in (
	select
	 min(height)
	from people p );

--3. Find all players in the database who played at Vanderbilt University. 
--Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
--Sort this list in descending order by the total salary earned. 
--Which Vanderbilt player earned the most money in the majors?
	
select
	p.namefirst,
	p.namelast,
	sum(s.salary) as total_salary
from people p
inner join 
(
	select
		distinct playerid,
		schoolid
	from collegeplaying
	where schoolid = 'vandy'
) vandy
	on p.playerid = vandy.playerid
inner join salaries s
	on p.playerid = s.playerid 
group by 
	p.namefirst,
	p.namelast
order by total_salary desc

select
	p.namefirst,
	p.namelast,
	sum(s.salary) as total_salary
from people p
inner join salaries s
	on p.playerid = s.playerid 
where p.playerid in 
(
	select
		distinct playerid
	from collegeplaying
	where schoolid = 'vandy'
)
group by 
	p.namefirst,
	p.namelast
order by total_salary desc;

select
	c.playerid,
	c.yearid,
	s.salary 
from collegeplaying c
inner join salaries s
	on c.playerid = s.playerid
where c.playerid = 'priceda01';

select * from salaries where playerid = 'priceda01'

-- 4. Using the fielding table, group players into three groups based on their position: 
	-- label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
	-- Determine the number of putouts made by each of these three groups in 2016.

select
 case
 	when pos in ('OF') then 'outfield'
 	when pos in ('SS', '1B', '2B', '3B') then 'infield'
 	else 'battery'
 end as position,
sum(po) sumPutouts
from fielding
where yearid = 2016
group by 1;

-- 5. Find the average number of strikeouts per game by decade since 1920. 
-- Round the numbers you report to 2 decimal places. 
-- Do the same for home runs per game. Do you see any trends?

select 
	yearid / 10 * 10 as decade,-- * 10 as decade,
	round(sum(so::numeric)/(sum(g::numeric)/2),2) as avg_so,
	round(sum(hr::numeric)/(sum(g::numeric)/2),2) as avg_hr
from teams
where yearid >= 1920
group by 1
order by decade desc;


-- 6. Find the player who had the most success stealing bases in 2016, 
-- where __success__ is measured as the percentage of stolen base attempts which are successful. 
--(A stolen base attempt results either in a stolen base or being caught stealing.) 
-- Consider only players who attempted _at least_ 20 stolen bases.

select 
	p.namefirst,
	p.namelast,
	Round(sb.sb_success, 2) as sb_success
from people p
inner join
(
	select
	playerid,
	 (sum(sb::numeric) / sum(sb::numeric + cs::numeric) * 100) as sb_success
	from batting
	where yearid = 2016
	group by 1
	having sum(sb + cs) > 19
	order by sb_success desc
	limit 1
) sb
	on p.playerid = sb.playerid;
	
	
	select * from batting;

SELECT 
	CONCAT(p.namefirst, ' ', p.namelast) AS full_name,
	(SB::numeric/(SB::numeric+CS::numeric)) * 100 AS Success_percentage
FROM batting AS b
INNER JOIN people AS p
USING (playerid)
WHERE SB + CS >=20 AND yearid = 2016
ORDER BY Success_percentage DESC;
-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
-- What is the smallest number of wins for a team that did win the world series? 
-- Doing this will probably result in an unusually small number of wins for a world series champion 
-- determine why this is the case. Then redo your query, excluding the problem year. 
-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
-- What percentage of the time?
	
select
	yearid,
	wswin,
	name,
	w
from teams t1
where yearid > 1969
	and wsWin = 'N'
order by w desc
limit 1;
	
--============================================

select
	yearid,
	wswin,
	teamid,
	w
from teams t1
where yearid > 1969
	and wsWin = 'Y'
order by w
limit 1;

	
--======================================
select
	sum(
		case 
			when wswin = 'Y' then 1 
			else 0 
		end
	)::numeric as occurences,
	count(*) as ws,
	round(
		sum(
			case 
				when wswin = 'Y'  then 1 else 0 end
			)::numeric / count(*)::numeric*100,2
	) as percentage
from (
select
	yearid,
	wswin,
	teamid,
	row_number() over(partition by yearid order by w desc) as maxWin
from teams t1
where yearid > 1969
order by maxWin) a
where maxWin = 1 and yearid not in ( 1981 );


-- ====================================================================


select
	sum(case when wswin = 'Y' then 1 else 0 end)::numeric as occurences,
	count(*) as ws,
	round(sum(case when wswin = 'Y' then 1 else 0 end)::numeric / count(*)::numeric*100,2) as percentage
from (
select
	yearid,
	wswin,
	teamid,
	row_number() over(partition by yearid order by w desc) as maxWin
from teams t1
where yearid > 1969
order by maxWin) a
where maxWin = 1 and yearid not in ( 1981, 1994 );


-- 8) Using the attendance figures from the homegames table, 
-- find the teams and parks which had the top 5 average attendance per game in 2016 
-- (where average attendance is defined as total attendance divided by number of games). 
-- Only consider parks where there were at least 10 games played. 
-- Report the park name, team name, and average attendance. 
-- Repeat for the lowest 5 average attendance.*/

with high as (select 
	homegames.park,
	teams.name,
	parks.park_name,
	'high' as "high/low",
	round(sum(homegames.attendance)::numeric / sum(homegames.games)::numeric,2) as avg_attendance
from homegames
inner join parks
using(park)
inner join teams
on homegames.team = teams.teamid 
	and homegames.year = teams.yearid 
where games > 10 and year = 2016
group by 1,2,3
order by avg_attendance desc
limit 5),

low as (select 
	homegames.park,
	teams.name,
	parks.park_name,
	'low' as "high/low",
	round(sum(homegames.attendance)::numeric / sum(homegames.games)::numeric,2) as avg_attendance
from homegames
inner join parks
using(park)
inner join teams
on homegames.team = teams.teamid 
	and homegames.year = teams.yearid 
where games > 10 and year = 2016
group by 1,2,3
order by avg_attendance 
limit 5)

select 
	*
from high
union
select
	*
from low
order by "high/low", avg_attendance desc;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.
select 
	distinct concat(p.namefirst,' ', p.namelast) as full_name,
	t.name as team_Name ,
	a.lgid
from awardsmanagers a
inner join people p
	on a.playerid = p.playerid 
inner join managers m
	on a.playerid = m.playerid 
	and a.yearid = m.yearid
inner join teams t
	on m.teamid = t.teamid 
	and m.yearid = t.yearid 
where a.playerid in 
(
	select 
		playerid
	from awardsmanagers
	where awardid = 'TSN Manager of the Year'
	and lgid in ('AL', 'NL')
	group by 1
	having count(distinct lgid) > 1
)


select * from awardssharemanagers;

--===================================================


WITH nl AS(
SELECT
	a.playerid AS nl_manager,
	a.awardid,
	a.lgid,
	a.yearid
FROM awardsmanagers a
WHERE awardid LIKE 'TSN Manager of the Year'
 	AND a.lgid LIKE 'NL'
),
al AS(
SELECT
	a.playerid AS al_manager,
	a.awardid,
	a.lgid,
	a.yearid
FROM awardsmanagers a
WHERE awardid LIKE 'TSN Manager of the Year'
 	AND a.lgid LIKE 'AL'
	ORDER BY yearid
)
SELECT
	DISTINCT(namefirst || ' '|| namelast) AS manager_name,
	a.lgid,
	t.name AS team_name
FROM awardsmanagers a
INNER JOIN al
	ON a.playerid = al.al_manager
INNER JOIN nl
	ON a.playerid = nl.nl_manager
INNER JOIN people p
	USING (playerid)
INNER JOIN managers m
	using (playerid)
INNER JOIN teams t
	on t.teamid = m.teamid AND t.yearid = a.yearid
WHERE al_manager=nl_manager
	AND a.yearid = m.yearid
	
--=========================================================================================

-- 10. Find all players who hit their career highest number of home runs in 2016. 
-- Consider only players who have played in the league for at least 10 years, 
-- and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
	
select 
*
from (
select 
	p.namefirst
	, p.namelast 
	, yearid
	, hr
	, row_number() over(partition by b.playerid order by hr desc, yearid desc) maxHr
from batting b
inner join people p
	on b.playerid = p.playerid 
where b.playerid in (
	select
		playerid
	from people
		where playerid in (
			select
				playerid
			from batting
			where hr > 0 and yearid = 2016)
	group by 1
	having EXTRACT(YEAR FROM age(finalgame::date, debut::date)) >= 10
	)
)x
where maxhr = 1 and yearid = 2016;

--===========================================================
-- if you go by finalgame and debut you will not get justin upton as he doesn't quite hit 10 years between the two
-- you may not get edwin encarnacion or justin upton depending on the query because 2016 is a tie for their career most homeruns
--===========================================================

select 
namefirst,
namelast,
yearid,
hr
from (
	select
		p.namefirst,
		p.namelast,
		b.yearid,
		b.hr,
		row_number() over(partition by b.playerid order by b.hr desc, b.yearid desc) maxHr
	from batting b
	inner join people p
		on b.playerid = p.playerid 
	where b.playerid in 
		(
			select
				playerid
			from batting
			where hr > 0 and yearid = 2016
		)
		and b.playerid in
		(
			select
				playerid
			from batting
			group by 1
			having count(distinct yearid) >=10
		)
)sq
where sq.maxHr = 1 and sq.yearid = 2016;


