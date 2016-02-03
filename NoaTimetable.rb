require 'nokogiri'
require 'anemone'

require './Timetable'

class NoaTimetable < Timetable

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
      depth_limit: 1,
    }

    substitutes = []

    Anemone.crawl(@@base_url + "/close/", opts) do |anemone|
      anemone.on_pages_like(/close_\w+/) do |page|
        studio_name = 'NOA ' << page.doc.xpath("/html/head/title/text()").to_s.match(/(.+校)/)[1]
        month = Date.today.strftime('%m')

        page.doc.xpath("/html/body//table[@class='close_table']/tr").each do |row|
          data = row.xpath("./td")

          if /(\d+)\/(\d+)/ =~ data[0].text
            month = ('0' + $1)[-2, 2]
            date  = ('0' + $2)[-2, 2]
          else
            date = ('0' + data[0].text)[-2, 2]
          end

          data[2].text.split("\n").each do |sub|
            if /(.+)\((.+)\)(\d{1,2}:\d{1,2})[~～〜]\p{blank}?(.+)/ =~ sub
              substitutes.push(
                {
                  studio: studio_name + ' ' + $2,
                  date:   sprintf('%s/%s', month, date),
                  day:    days[data[1].text],
                  start_time:   $3,
                  instructor: trim($1),
                  substitute: trim($4),
                }
              )
            end
          end
        end
      end
    end

    puts substitutes
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

    instructors = []

    Anemone.crawl(@@base_url + "/dancer/", opts) do |anemone|
      anemone.on_every_page do |page|
        page.doc.xpath("/html/body//div[@class='dancer_box']").each do |data|

          profile_url = full_url(data.at_xpath(".//li/a").attribute("href").value)
          name = trim(data.at_xpath(".//li[@class='dancername']/text()").to_s)
          team = trim(data.at_xpath(".//li[@class='dancerteam']/text()").to_s)

          instructors.push(
            {
              profile_url: profile_url,
              name: name,
              team: team
            }
          )
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
            if /(\d{2}:\d{2})[-~〜～](\d{2}:\d{2})/ =~ row.xpath("./td[@class='back']/text()").to_s
              row_start_time = $1
              row_end_time   = $2
            end

            row.xpath("./td").each_with_index do |data, column_index|
              next unless data.at_xpath("./a")

              if /(\d{2}:\d{2})[-~〜～](\d{2}:\d{2}).*※(.+)/ =~ data.xpath("./text()").to_a.join(' ')
                start_time = $1
                end_time   = $2
                class_name = trim($3)
              else
                start_time = row_start_time
                end_time   = row_end_time
                class_name = trim(data.xpath("./text()").to_a.join(' '))
              end

              instructor_url = full_url(data.at_xpath("./a").attribute("href").value)
              instructor_name = (instructors.find { |e| e[:profile_url] == instructor_url })[:name] rescue trim(data.xpath("./a/text()").to_s)
              instructor_team = (instructors.find { |e| e[:profile_url] == instructor_url })[:team] rescue trim(data.xpath("./a/small/text()").to_s)

              classes.push(
                {
                  studio: studio_name,
                  day:    day[column_index - 1],
                  start_time: start_time,
                  end_time: end_time,
                  genre:  '(undefined)',
                  name:   class_name,
                  instructor_url: instructor_url,
                  instructor_name: instructor_name,
                  instructor_team: instructor_team
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
