require 'sqlite3'

class Timetable
  def fetch
  end

  private

  @@opts = {
    depth_limit: 0
  }

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
      unless team.nil? || team == ''
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
    insert_query = 'insert or ignore into class(studio, day, time, genre, name, instructor) values'
    classes.each do |clazz|
      puts clazz
    end
  end

end
