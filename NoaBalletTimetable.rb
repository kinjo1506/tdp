require 'nokogiri'
require 'anemone'

require './Timetable'

class NoaBalletTimetable < Timetable
  def fetch
    fetch_noaballet "http://www.noaballet.jp/schedule_toritsu/"   # 都立大
    fetch_noaballet "http://www.noaballet.jp/schedule_shinjuku/"  # 新宿
  end

  private

  def fetch_noaballet(url)
    Anemone.crawl(url, @@opts) do |anemone|
      anemone.on_every_page do |page|

        instructors = {}

        page.doc.xpath("/html/body//div[contains(@class,'elementBox')]/table").each_with_index do |schedule, schedule_index|
          break if (schedule_index >= 2)

          # スタジオ名
          puts schedule.xpath(".//th/text()").to_s

          # timetable[曜日][クラス]
          timetable = Array.new(7) { Array.new() }

          schedule.xpath(".//tr").each_with_index do |row, row_index|
            next if (row_index < 2)

            time = row.xpath("./td[contains(@class,'timeTable')]/big/text()").to_s

            row.xpath("./td").each_with_index do |data, data_index|
              next if (data_index < 1)

              instructor_name = trim(data.xpath("./a/text()").to_s)
              instructors[instructor_name] = ''

              timetable[data_index - 1].push({
                  time: time,
                  classname: data.xpath("./text()").to_s,
                  instructor: data.xpath("./a/text()").to_s,
                })
            end
          end

          day = ["mon","tue","wed","thu","fri","sat","sun"]
          timetable.each_with_index do |classes, day_index|
            puts day[day_index]
            classes.each do |clazz|
              puts "    ---"
              puts "    " + clazz[:time]
              puts "    " + clazz[:classname]
              puts "    " + clazz[:instructor]
            end
            puts "    ---"
          end

        end

        #update_instructors instructors

      end
    end
  end

end