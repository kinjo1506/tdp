# 必要なgemを読み込み。読み込み方やその意味はrubyの基本をおさらいして下さい。
require 'nokogiri'
require 'anemone'
require 'sqlite3'

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
    # update
    unless team.nil? || team == ''
      update_query << sprintf(' when "%s" then "%s"', name, team)
      update_names << sprintf('"%s",', name)
    end

    # insert
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

# 後述。
opts = {
    depth_limit: 0
}

# Works タイムテーブル
# Anemone.crawl("http://danceworks.jp/lesson/", opts) do |anemone|
#   anemone.on_every_page do |page|
#     studio_name = ["渋谷松濤校","渋谷宇田川校A","渋谷宇田川校B","渋谷シアター校"]
#     day = ["mon","tue","wed","thu","fri","sat","sun"]

#     instructors = {}

#     page.doc.xpath("/html/body//div[contains(@class,'tabcont')]").each_with_index do |studio, studio_index|

#       # puts studio_name[studio_index]

#       studio.xpath("./table/tr[2]/td").each_with_index do |timetable, day_index|

#         # puts "  " + day[day_index]

#         timetable.xpath("./div[@class='instructor']").each do |node|

#           instructor_name = trim(node.xpath("./dl/dd/span/text()").to_s)
#           instructors[instructor_name] = nil

#           time = node.xpath("./dl/dt/text()").to_s
#           instructor = node.xpath("./dl/dd/span/text()").to_s
#           classname = node.xpath("./div[@class='csname']/text()").to_s
#           # puts "    ---"
#           # puts "    " + time
#           # puts "    " + classname
#           # puts "    " + instructor
#         end
#         # puts "    ---"
#       end
#     end # node終わり

#     update_instructors(instructors)

#   end # page終わり
# end # Anemone終わり

# Works 休講代講
# Anemone.crawl("http://danceworks.jp/lesson/cancelsubstitute/", opts) do |anemone|
#   anemone.on_every_page do |page|
#     studio_name = ["渋谷松濤校","渋谷宇田川校A","渋谷宇田川校B","渋谷シアター校"]

#     schedule = page.doc.xpath("/html/body//div[contains(@class,'maincont')]/section/article[2]")
#     date = schedule.xpath("./h4/text()")

#     schedule.xpath("./table[@class='cstable2']").each_with_index do |timetable, date_index|
#       puts "---"
#       puts date[date_index].to_s

#       timetable.xpath("./tr").each_with_index do |clazz, index|
#         next if (index == 0)

#         puts "    ---"
#         puts "    " + clazz.xpath("./td[@class='studio_name']/text()").to_s
#         puts "    " + clazz.xpath("./td[@class='lesson_time']/text()").to_s
#         puts "    " + clazz.xpath("./td[@class='instructor_name']/text()").to_s
#         puts "    " + clazz.xpath("./td[@class='cs_cont']/span/text()").to_s
#       end
#       puts "    ---"

#     end # node終わり
#   end # page終わり
# end # Anemone終わり

# NOA 新宿 タイムテーブル
Anemone.crawl("http://www.noadance.com/schedule_shinjuku2/", opts) do |anemone|
  anemone.on_every_page do |page|

    instructors = {}

    page.doc.xpath("/html/body//table[contains(@class,'schedule_table')]").each do |schedule|
      puts schedule.xpath(".//th/text()").to_s

      # timetable[曜日][クラス]
      timetable = Array.new(7) { Array.new() }

      schedule.xpath(".//tr").each_with_index do |row, row_index|
        next if (row_index < 2)

        time = row.xpath("./td[@class='back']/text()").to_s

        row.xpath("./td").each_with_index do |data, data_index|
          next if (data_index < 1)

          instructor_name = trim(data.xpath("./a/text()").to_s)
          instructor_team = trim(data.xpath("./a/small/text()").to_s)

          instructors[instructor_name] = instructor_team;

          timetable[data_index - 1].push({
              time: time,
              classname: data.xpath("./text()").to_s,
              instructor: data.xpath("./a/text()").to_s,
              team: data.xpath("./a/small/text()").to_s
            })
        end
      end

      # day = ["mon","tue","wed","thu","fri","sat","sun"]
      # timetable.each_with_index do |classes, day_index|
      #   puts day[day_index]
      #   classes.each do |clazz|
      #     puts "    ---"
      #     puts "    " + clazz[:time]
      #     puts "    " + clazz[:classname]
      #     puts "    " + clazz[:instructor] + " ( " + clazz[:team] + " )"
      #   end
      #   puts "    ---"
      # end

    end # node終わり

    update_instructors instructors

  end # page終わり
end # Anemone終わり

# NOA Ballet 新宿 タイムテーブル
# Anemone.crawl("http://www.noaballet.jp/schedule_toritsu/", opts) do |anemone|
#   anemone.on_every_page do |page|

#     instructors = {}

#     page.doc.xpath("/html/body//div[contains(@class,'elementBox')]/table").each_with_index do |schedule, schedule_index|
#       break if (schedule_index >= 2)

#       puts schedule.xpath(".//th/text()").to_s

#       # timetable[曜日][クラス]
#       timetable = Array.new(7) { Array.new() }

#       schedule.xpath(".//tr").each_with_index do |row, row_index|
#         next if (row_index < 2)

#         time = row.xpath("./td[contains(@class,'timeTable')]/big/text()").to_s

#         row.xpath("./td").each_with_index do |data, data_index|
#           next if (data_index < 1)

#           instructor_name = trim(data.xpath("./a/text()").to_s)
#           instructors[instructor_name] = ''

#           timetable[data_index - 1].push({
#               time: time,
#               classname: data.xpath("./text()").to_s,
#               instructor: data.xpath("./a/text()").to_s,
#             })
#         end
#       end

#       # day = ["mon","tue","wed","thu","fri","sat","sun"]
#       # timetable.each_with_index do |classes, day_index|
#       #   puts day[day_index]
#       #   classes.each do |clazz|
#       #     puts "    ---"
#       #     puts "    " + clazz[:time]
#       #     puts "    " + clazz[:classname]
#       #     puts "    " + clazz[:instructor]
#       #   end
#       #   puts "    ---"
#       # end

#     end # node終わり

#     instructors = instructors.sort_by { |name, team| name }

#     instructors.each do |name, team|
#       puts name + " => " + team
#     end

#   end # page終わり
# end # Anemone終わり
