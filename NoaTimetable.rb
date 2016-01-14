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
    day = [:Monday, :Tuesday, :Wednesday, :Thursday, :Friday, :Saturday, :Sunday]

    instructors = {}
    classes = []

    Anemone.crawl(url, @@opts) do |anemone|
      anemone.on_every_page do |page|


        page.doc.xpath("/html/body//table[contains(@class,'schedule_table')]").each do |schedule|
          studio_name = 'NOA ' << schedule.xpath(".//th/text()").to_s

          schedule.xpath(".//tr").each_with_index do |row, row_index|
            next if (row_index < 2)

            time = trim(row.xpath("./td[@class='back']/text()").to_s)

            row.xpath("./td").each_with_index do |data, column_index|
              next if (column_index < 1)

              class_name = trim(data.xpath("./text()").to_s)
              instructor_name = trim(data.xpath("./a/text()").to_s)
              instructor_team = trim(data.xpath("./a/small/text()").to_s)

              instructors[instructor_name] = instructor_team;

              classes.push(
                {
                  studio: studio_name,
                  day:    day[column_index - 1],
                  time:   time,
                  genre:  '(undefined)',
                  name:   class_name,
                  instructor: instructor_name
                }
              )
            end
          end
        end

        update_instructors instructors
        update_classes classes

      end
    end
  end

end