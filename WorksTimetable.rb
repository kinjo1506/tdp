require 'nokogiri'
require 'anemone'

require './Timetable'

class WorksTimetable < Timetable

  def fetch
    fetch_works
  end

  private

  def fetch_works
    studio_name = [
      "Works 渋谷松濤校",
      "Works 渋谷宇田川校A",
      "Works 渋谷宇田川校B",
      "Works 渋谷シアター校"
    ]
    day = [:Monday, :Tuesday, :Wednesday, :Thursday, :Friday, :Saturday, :Sunday]

    instructors = {}
    classes = []

    Anemone.crawl("http://danceworks.jp/lesson/", @@opts) do |anemone|
      anemone.on_every_page do |page|
        page.doc.xpath("/html/body//div[contains(@class,'tabcont')]").each_with_index do |studio, studio_index|
          studio.xpath("./table/tr[2]/td").each_with_index do |timetable, day_index|
            timetable.xpath("./div[@class='instructor']").each do |node|

              time = node.xpath("./dl/dt/text()").to_s
              class_name = node.xpath("./div[@class='csname']/text()").to_s
              instructor_name = trim(node.xpath("./dl/dd/span/text()").to_s)

              instructors[instructor_name] = nil

              classes.push(
                {
                  studio: studio_name[studio_index],
                  day:    day[day_index],
                  time:   time,
                  genre:  '(undefined)',
                  class:  class_name,
                  instructor: instructor_name
                }
              )
            end
          end
        end
      end
    end

    update_classes classes

  end
end
