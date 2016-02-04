require 'nokogiri'
require 'anemone'

require './Timetable'

class WorksTimetable < Timetable

  def fetch_substitute
    days = {
      '月' => :Monday,
      '火' => :Tuesday,
      '水' => :Wednesday,
      '木' => :Thursday,
      '金' => :Friday,
      '土' => :Saturday,
      '日' => :Sunday,
    }
    opts = {
      depth_limit: 0,
    }

    substitutes = []

    Anemone.crawl(@@base_url + "/lesson/cancelsubstitute/", opts) do |anemone|
      anemone.on_every_page do |page|
        dates = page.doc.xpath("/html/body//h4")

        page.doc.xpath("/html/body//table[@class='cstable2']").each_with_index do |table, date_index|
          if /\d{4}\/(\d{2}\/\d{2})（(.{1})）/ =~ dates[date_index].text
            date = $1
            day  = days[$2]
          end

          table.xpath("./tr").each do |sub|
            next unless sub.at_xpath("./td[@class='studio_name']")

            if /\/([^\/]+)$/ =~ sub.at_xpath("./td[@class='instructor_name']").text
              instructor_name = $1
            end

            if /(\d{2}:\d{2})-(\d{2}:\d{2})/ =~ sub.at_xpath("./td[@class='lesson_time']").text
              start_time = $1
              end_time   = $2
            end

            substitutes.push(
              {
                studio: 'Works ' + sub.at_xpath("./td[@class='studio_name']").text,
                date:   date,
                day:    day,
                start_time: start_time,
                end_time:   end_time,
                instructor: trim(instructor_name),
                substitute: trim(sub.at_xpath("./td[@class='cs_cont']").text),
              }
            )
          end
        end
      end
    end

    puts substitutes
  end

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

          profile_url = full_url(data.at_xpath("./dl/dt/a").attribute("href").value)
          name = trim(data.at_xpath("./dl/dt/a").text)

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

              if /(\d{2}:\d{2})-(\d{2}:\d{2})/ =~ node.at_xpath("./dl/dt").text
                start_time = $1
                end_time   = $2
              end

              class_name = trim(node.xpath("./div[@class='csname']").text)
              instructor_url = full_url(node.at_xpath("./dl//a").attribute("href").value)
              instructor_name = (instructors.find { |e| e[:profile_url] == instructor_url })[:name] rescue trim(node.xpath("./dl/dd/span").text)

              classes.push(
                {
                  studio: studio_name[studio_index],
                  day:    day[day_index],
                  start_time: start_time,
                  end_time: end_time,
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
