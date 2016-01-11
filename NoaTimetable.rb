require 'nokogiri'
require 'anemone'

require './Timetable'

class NoaTimetable < Timetable
  def fetch
    fetch_noa "http://www.noadance.com/schedule_ikebukuro/"   # 池袋
    fetch_noa "http://www.noadance.com/schedule_toritsudai/"  # 都立大
    fetch_noa "http://www.noadance.com/schedule_shinjuku/"    # 新宿
    fetch_noa "http://www.noadance.com/schedule_shinjuku2/"   # 新宿 ANNEX
    fetch_noa "http://www.noadance.com/schedule_akihabara/"   # 秋葉原
  end

  private

  def fetch_noa(url)
    Anemone.crawl(url, @@opts) do |anemone|
      anemone.on_every_page do |page|

        instructors = {}

        page.doc.xpath("/html/body//table[contains(@class,'schedule_table')]").each do |schedule|
          # スタジオ名
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

        end

        update_instructors instructors

      end
    end
  end

end