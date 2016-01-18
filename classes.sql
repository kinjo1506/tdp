-- classes

select
s.name as studio, c.day, c.time, g.name as genre, c.name as class, i.name as instructor, i.team, c.note
from class c
inner join studio s on (c.studio = s.id)
inner join genre g on (c.genre = g.id)
inner join instructor i on (c.instructor = i.id);


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

