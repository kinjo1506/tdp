require 'nokogiri'
require 'anemone'

require './Timetable'

class NoaTimetable < Timetable
  def fetch
    fetch_classes(fetch_instructors())
  end

  private

  @@base_url = "http://www.noadance.com"

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

    instructors = {}

    Anemone.crawl(@@base_url + "/dancer/", opts) do |anemone|
      anemone.on_every_page do |page|
        page.doc.xpath("/html/body//div[@class='dancer_box']").each do |data|
          instructors[full_url(data.at_xpath(".//li/a").attribute("href").value)] = {
            name: trim(data.at_xpath(".//li[@class='dancername']/text()").to_s),
            team: trim(data.at_xpath(".//li[@class='dancerteam']/text()").to_s)
          }
        end
      end
    end

    instructors
  end

  def fetch_classes(instructors)
    day = [:Monday, :Tuesday, :Wednesday, :Thursday, :Friday, :Saturday, :Sunday]

    opts = {
      depth_limit: 1
    }

    classes = []

    Anemone.crawl(@@base_url + "/schedule/", opts) do |anemone|
      anemone.on_pages_like(/schedule_\w+/) do |page|
        page.doc.xpath("/html/body//table[contains(@class,'schedule_table')]").each do |schedule|
          studio_name = 'NOA ' << schedule.xpath(".//th/text()").to_s

          schedule.xpath(".//tr").each_with_index do |row, row_index|
            next if (row_index < 2)

            time = trim(row.xpath("./td[@class='back']/text()").to_s)

            row.xpath("./td").each_with_index do |data, column_index|
              next if (column_index < 1)
              next unless data.at_xpath("./a")

              key = full_url(data.at_xpath("./a").attribute("href").value)

              class_name = trim(data.xpath("./text()").to_s)
              instructor_name = instructors[key][:name] rescue trim(data.xpath("./a/text()").to_s)
              instructor_team = instructors[key][:team] rescue trim(data.xpath("./a/small/text()").to_s)

              # instructors[instructor_name] = instructor_team;

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
      end
    end

    p classes
    # update_instructors instructors
    # update_classes classes

  end
end
