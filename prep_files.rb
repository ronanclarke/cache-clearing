# require_relative 'file_utils.rb'
Dir["./helpers/*.rb"].each { |file| require file }


require "net/http"
require "uri"


class PrepFile

  include FileUtils

  def init()

  end

  def go

    file_name = "brochure-pages.csv"
    urls = read_file_to_array("data/test.csv", false)

    puts "ronan"
    puts urls.size

    output = []
    output << "url,device,country"

    urls.each_with_index do |url, index|


      if (index > 0 && index < 50000)

        arr = url.split(",")

        begin
          output << "#{arr[0]},D,#{arr[3]}"
          output << "#{arr[0]},M,#{arr[3]}"
        rescue
          puts "had issue with #{url}"
        end
      end
    end


    open(file_name, 'w') do |f|
      f.puts output
    end

  end
end

PrepFile.new.go
