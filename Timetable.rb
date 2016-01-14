require 'sqlite3'

class Timetable
  def fetch
  end

  private

  @@opts = { depth_limit: 0 }
  @@day_id = { Sunday: 0, Monday: 1, Tuesday: 2, Wednesday: 3, Thursday:4, Friday: 5, Saturday: 6 }

  def trim(str)
    japanese_chars = '[\p{Han}\p{Hiragana}\p{Katakana}，．、。ー・]+'
    regexp = Regexp.new('\s*(' + japanese_chars + ')\s*')
    str.strip.gsub(regexp, '\1').to_s
  end

  def update_instructors(instructors)
    update_query = 'update instructor set team = case name'
    update_names = ''
    insert_query = 'insert or ignore into instructor(name, team) values'

    instructors.each do |name, team|
      next if (name.nil? || name.empty?)

      unless team.nil? || team.empty?
        update_query << sprintf(' when "%s" then "%s"', name, team)
        update_names << sprintf('"%s",', name)
      end

      insert_query << sprintf(' ("%s", "%s"),', name, team)
    end

    update_query << ' else "" end where (team is null or team = "") and (name in (' << update_names.chop << '));'
    insert_query.chop! << ';'

    SQLite3::Database.new 'tdp.sqlite3' do |db|
      unless update_names.empty?
        db.execute update_query
      end

      db.execute insert_query
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
          instructor text not null,
          note text
      );

      insert into class_temp values
    '
    classes.each do |clazz|
      query << sprintf(' ("%s", "%d", "%s", "%s", "%s", "%s", "%s"),',
          clazz[:studio], @@day_id[clazz[:day]], clazz[:time], clazz[:genre], clazz[:name], clazz[:instructor], '')
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
          inner join instructor i on (t.instructor = i.name)
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
        studio, day, time, genre, name, instructor, note
      )
      select
        s.id, t.day, t.time, g.id, t.name, i.id, t.note
      from class_temp t
      inner join studio s on (t.studio = s.name)
      inner join genre g on (t.genre = g.name)
      inner join instructor i on (t.instructor = i.name);

      drop table if exists class_temp;
      '

    SQLite3::Database.new 'tdp.sqlite3' do |db|
      db.execute_batch query
      db.close
    end
  end
end
