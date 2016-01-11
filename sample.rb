# 必要なgemを読み込み。読み込み方やその意味はrubyの基本をおさらいして下さい。
require 'nokogiri'
require 'anemone'

require './Timetable'
require './NoaTimetable'
require './NoaBalletTimetable'
require './WorksTimetable'
require './WorksCancelSchedule'

# NoaBalletTimetable.new.fetch
WorksTimetable.new.fetch
