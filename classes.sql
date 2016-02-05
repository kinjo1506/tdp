-- classes

select
c.exists_at, s.name as studio, case c.day when 0 then "Sun" when 1 then "Mon" when 2 then "Tue" when 3 then "Wed" when 4 then "Thu" when 5 then "Fri" when 6 then "Sat" end, c.start_time, c.end_time, g.name as genre, c.name as class, i.name as instructor, i.team
from class c
inner join studio s on (c.studio = s.id)
inner join genre g on (c.genre = g.id)
inner join instructor i on (c.instructor = i.id)
order by c.exists_at, c.studio, c.day, c.start_time;


-- substitute

select
sub.updated_at, sub.date, case c.day when 0 then "Sun" when 1 then "Mon" when 2 then "Tue" when 3 then "Wed" when 4 then "Thu" when 5 then "Fri" when 6 then "Sat" end, c.start_time, s.name as studio, g.name as genre, c.name as class, i.name as instructor, i.team, sub.substitute
from substitute sub
inner join class c on (sub.class = c.id)
inner join studio s on (c.studio = s.id)
inner join genre g on (c.genre = g.id)
inner join instructor i on (c.instructor = i.id)
order by sub.date, c.studio, c.start_time;


-- instructor

select * from instructor order by name collate nocase;


-- instructor 重複チェック

select i.id, i.name, i.team, i.profile_url
from instructor i
inner join (
    select name, count(*) as count
    from instructor
    group by name collate nocase
    having count > 1
) s
on (i.name = s.name collate nocase)
order by i.name collate nocase, i.id;

