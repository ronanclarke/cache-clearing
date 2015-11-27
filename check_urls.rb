# require_relative 'file_utils.rb'
Dir["./helpers/*.rb"].each { |file| require file }


require "net/http"
require "uri"


class ClearCache

  include FileUtils

  def init()

  end

  def go
    errors = read_file_to_array("data/whitelist.db", true)


    errors.each do |error|


      uri = URI.parse("http://www.whatclinic.com/#{error}")
      response = Net::HTTP.get_response(uri)
      if(response.code != "200")
        puts "got #{response.code} for #{error}"
        log_to_file("error-", error, false)
      end

      log_to_file("done-", error, false)

    end


  end
end

ClearCache.new.go
