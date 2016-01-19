require 'sqlite3'

class Timetable
  def fetch
    instructors = fetch_instructors()
    classes = fetch_classes(instructors)

    update_instructors instructors
    update_classes classes
  end

  private

  def fetch_instructors
    raise 'Method \'fetch_instructors\' not implemented.'
  end

  def fetch_classes(instructors)
    raise 'Method \'fetch_classes\' not implemented.'
  end

  @@opts = { depth_limit: 0 }
  @@day_id = { Sunday: 0, Monday: 1, Tuesday: 2, Wednesday: 3, Thursday:4, Friday: 5, Saturday: 6 }

  def trim(str)
    japanese_chars = '[\p{Han}\p{Hiragana}\p{Katakana}，．、。ー・]+'
    regexp = Regexp.new('\s*(' + japanese_chars + ')\s*')
    str.strip.gsub(regexp, '\1').to_s
  end

  def update_instructors(instructors)
    query = '
      drop table if exists instructor_temp;

      create temporary table instructor_temp (
        profile_url text not null unique,
        name text not null,
        team text default null
      );

      insert into instructor_temp values
    '
    instructors.each do |value|
      query << sprintf(' ("%s", "%s", "%s"),', value[:profile_url], value[:name], value[:team])
    end
    query.chop! << ';' << '
      update instructor
      set
        name = (select name from instructor_temp where (instructor.profile_url = instructor_temp.profile_url)),
        team = (select team from instructor_temp where (instructor.profile_url = instructor_temp.profile_url))
      where
        profile_url in (select profile_url from instructor_temp);

      insert or ignore into instructor (
        profile_url, name, team
      )
      select
        profile_url, name, team
      from instructor_temp;

      drop table if exists instructor_temp;
      '

    SQLite3::Database.new 'tdp.sqlite3' do |db|
      db.execute_batch query
      db.close
    end
  end

  def update_classes(classes)
    query = '
      drop table if exists class_temp;

      create temporary table class_temp (
          studio text not null,
          day integer not null,
          time text not null,
          genre text not null,
          name text not null,
          instructor_url text not null
      );

      insert into class_temp values
    '
    classes.each do |clazz|
      query << sprintf(' ("%s", "%d", "%s", "%s", "%s", "%s"),',
          clazz[:studio], @@day_id[clazz[:day]], clazz[:time], clazz[:genre], clazz[:name], clazz[:instructor_url])
    end
    query.chop! << ';' << '
      update class
      set exists_at = datetime(\'now\', \'localtime\')
      where id in (
        select id
        from class
        inner join (
          select
            s.id as studio, t.day, t.time, g.id as genre, t.name, i.id as instructor
          from class_temp t
          inner join studio s on (t.studio = s.name)
          inner join genre g on (t.genre = g.name)
          inner join instructor i on (t.instructor_url = i.profile_url)
        ) sub
        on (
          (class.studio = sub.studio) and
          (class.day = sub.day) and
          (class.time = sub.time) and
          (class.genre = sub.genre) and
          (class.name = sub.name) and
          (class.instructor = sub.instructor)
        )
      );

      insert or ignore into class (
        studio, day, time, genre, name, instructor
      )
      select
        s.id, t.day, t.time, g.id, t.name, i.id
      from class_temp t
      inner join studio s on (t.studio = s.name)
      inner join genre g on (t.genre = g.name)
      inner join instructor i on (t.instructor_url = i.profile_url);

      drop table if exists class_temp;
      '

    SQLite3::Database.new 'tdp.sqlite3' do |db|
      db.execute_batch query
      db.close
    end
  end
end
