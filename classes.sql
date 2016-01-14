select
s.name as studio, c.day, c.time, g.name as genre, c.name as class, i.name as instructor, i.team, c.note
from class c
inner join studio s on (c.studio = s.id)
inner join genre g on (c.genre = g.id)
inner join instructor i on (c.instructor = i.id);
