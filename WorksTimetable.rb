require 'nokogiri'
require 'anemone'

require './Timetable'

class WorksTimetable < Timetable

  private

  @@base_url = "http://danceworks.jp"

  def full_url(url)
    unless url.start_with? @@base_url
      url = @@base_url + url
    end
    url
  end

  def fetch_instructors
    opts = {
      depth_limit: 0
    }

    instructors = []

    Anemone.crawl(@@base_url + "/instructor/", opts) do |anemone|
      anemone.on_every_page do |page|
        page.doc.xpath("/html/body//div[@class='instructor_list']").each do |data|

          profile_url = full_url(data.at_xpath("./dl//a").attribute("href").value)
          name = trim(data.at_xpath("./dl//a/text()").to_s)

          instructors.push(
            {
              profile_url: profile_url,
              name: name
            }
          )
        end
      end
    end

    instructors
  end

  def fetch_classes(instructors)
    studio_name = [
      "Works 渋谷松濤校",
      "Works 渋谷宇田川校A",
      "Works 渋谷宇田川校B",
      "Works 渋谷シアター校"
    ]
    day = [:Monday, :Tuesday, :Wednesday, :Thursday, :Friday, :Saturday, :Sunday]

    classes = []

    Anemone.crawl("http://danceworks.jp/lesson/", @@opts) do |anemone|
      anemone.on_every_page do |page|
        page.doc.xpath("/html/body//div[contains(@class,'tabcont')]").each_with_index do |studio, studio_index|
          studio.xpath("./table/tr[2]/td").each_with_index do |timetable, day_index|
            timetable.xpath("./div[@class='instructor']").each do |node|

              time = trim(node.xpath("./dl/dt/text()").to_s)
              class_name = trim(node.xpath("./div[@class='csname']/text()").to_s)
              instructor_url = full_url(node.at_xpath("./dl//a").attribute("href").value)
              instructor_name = (instructors.find { |e| e[:profile_url] == instructor_url })[:name] rescue trim(node.xpath("./dl/dd/span/text()").to_s)

              classes.push(
                {
                  studio: studio_name[studio_index],
                  day:    day[day_index],
                  time:   time,
                  genre:  '(undefined)',
                  name:   class_name,
                  instructor_url: instructor_url,
                  instructor_name: instructor_name
                }
              )
            end
          end
        end
      end
    end

    classes
  end
end
