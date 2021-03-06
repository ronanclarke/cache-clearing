# require_relative 'file_utils.rb'
Dir["./helpers/*.rb"].each { |file| require file }

class ClearCache

  include FileUtils

  def init()
    @dry_run = false
    # munge_data
    #ban_urls_from_white_list

    ban_search_objects_by_build_from_all_caches(false)
    ban_brochure_objects_by_build_from_all_caches(false)

  end

  def munge_data
    # brochure_urls_with_countries = read_file_to_array("data/BrochurePagesCut.csv", true)
    # brochure_urls_with_countries.each do |url|
    #   puts url
    # end

    CSV.foreach("data/BrochurePagesCut.csv") do |row|

      puts row
    end
  end

  def ban_urls_from_white_list

    puts "--- reading urls ---"
    urls_with_countries = read_file_to_array("data/urls_to_clear.db", true)
    urls_with_countries = urls_with_countries[37..1000]

    puts "--- splitting urls ---"

    thread_count = 3
    threads = []
    holder = Array.new(thread_count) { |i| [] }

    # round robin the urls into a set per thread
    urls_with_countries.each_with_index do |url, index|
      holder[index % (thread_count)] << url
    end

    puts "--- starting #{thread_count} threads ---"

    # make a thread for each set and kick it off
    thread_count.times do |thread_id|
      threads[thread_id] = Thread.new {
        @thread_id = thread_id
        refresh_and_ban_urls(holder[thread_id])
      }
    end

    threads.each { |t| t.join }


  end

  def execute_cmd(cmd)

    if @dry_run
      puts "DRY RUN:: #{cmd[0..255]}"
    else
      system(cmd)
    end


  end

  # def refresh_and_ban_urls(urls)
  #
  #
  #   urls.each do |url|
  #     puts "#{Thread.current.object_id} #{url}"
  #   end
  #
  # end

  def refresh_and_ban_urls(urls_with_countries)

    time_started = Time.now
    interval = Time.now

    counter = 0
    urls_with_countries.each do |url_with_country|
      url_with_country.strip!

      # hacky parsing of urls in file .. sometimes countries are in an array ... sometimes not
      if(!url_with_country.include?("\""))
        parts = url_with_country.split(",")
        url = parts[0]
        countries = parts[1].split(",")
      else
        url =url_with_country.split(",")[0]
        countries = url_with_country.split("\"")[1].split(",")
      end

      # put the newest version of the url from all popular countries in the cache
      refresh_url(url, countries)

      log_to_file("urls-cleared-#{Thread.current.object_id}", url_with_country, false)

      # this is just timing and output stuff
      counter = counter + 1
      if (counter % 100 == 0)
        time_per_100 = (Time.now - interval).round(2)
        puts "#{@thread_id} :: #{counter} urls completed - #{time_per_100}s/100" if counter % 100 == 0
        interval = Time.now
      end
    end


  end

  def ban_url_from_edge_servers(url)
    edge_servers = ["virginia", "california", "sydney", "singapore"] # => virginia.en.prod.varnish.whatclinic.com etc

    edge_servers.each do |server|
      curl_to_ban = "curl -s -S -f -X POST 'http://#{server}.en.prod.varnish.whatclinic.com/varnish/api/v2/ban/by-page/#{url}'"
      execute_cmd(curl_to_ban)
    end
  end

  #
  # hits the url pretending to a google bot
  #
  def refresh_url(url, countries)

    url.sub!("/","") # remove leading slash
    country = url.split(/\/|\?/)[1]

    # add the home country if it's not there already

    home_country_code = get_country_mapping[country];
    countries.push(home_country_code).uniq!

    edge_servers = ["california", "sydney"]
    edge_servers.each do |edge_server|
      full_url = "http://#{edge_server}.en.prod.varnish.whatclinic.com/#{url}"
      countries.each do |country|
        puts "#{url} #{edge_server} #{country}"
        execute_cmd(build_refresh_cmd(full_url, country, "D"))
        execute_cmd(build_refresh_cmd(full_url, country, "M"))

      end

    end

    puts "#{ Thread.current.object_id} completed #{url}"

  end

  def build_refresh_cmd(url, country, device)

    force_header =  "-H 'X-Varnish-Refresh: true'"
    "curl #{url} -o /dev/null -s -H 'Host: www.whatclinic.com' -H 'Cookie: cc=#{country};cd=#{device}' -A 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)' #{force_header} -H 'Accept-Encoding: gzip'"
  end


  def ban_brochure_objects_by_build_from_all_caches(dublin_only=true)

    # builds_to_ban = "29c0|00a0|107f|3d3d|33d2|0b74|dae2|fcc9|5248|b2ce|b734|104c|e982|4841|f8b3|fa59|b059|bd86"
    # builds_to_ban = "d34b|b43a|7d8b|04f1|76d8|461a"
    #builds_to_ban = "18ca|b631"
    # builds_to_ban = "d60e"
    # builds_to_ban = "3b20"
    # builds_to_ban = "6c6e"
    # builds_to_ban = "a930"
    # builds_to_ban = "d052"
    # builds_to_ban = "51d4"
    # builds_to_ban = "a067"
    builds_to_ban = "5261"
    ban_objects_by_build_from_all_caches(builds_to_ban, "brochure", dublin_only)

  end

  def ban_search_objects_by_build_from_all_caches(dublin_only=true)

    # builds_to_ban = "29c0|00a0|107f|3d3d|33d2|0b74|dae2|fcc9|5248|b2ce|b734|104c|e982|4841|f8b3|fa59|b059|bd86"
    # builds_to_ban = "d34b|b43a|7d8b|04f1|76d8|461a"
    #builds_to_ban = "18ca|b631"
    # builds_to_ban = "d60e"
    # builds_to_ban = "3b20"
    # builds_to_ban = "6c6e"
    # builds_to_ban = "a930"
    # builds_to_ban = "d052"
    # builds_to_ban = "51d4"
    # builds_to_ban = "a067"
    builds_to_ban = "5261"


    ban_objects_by_build_from_all_caches(builds_to_ban, "search", dublin_only)

  end

  def ban_objects_by_build_from_all_caches(builds_to_ban, object_type, dublin_only=true)

    if (dublin_only)
      servers = ["dublin"]
    else
      servers = ["dublin", "virginia", "california", "sydney", "singapore"]
    end

    puts "banning (#{builds_to_ban}) for #{object_type} from #{servers.join(",")}"

    servers.each do |server|
      cmd = "curl -X POST 'http://#{server}.en.prod.varnish.whatclinic.com/varnish/api/v2/ban/by-header/X-WCC-Tags/with-value/(|.*,)buildNumber=(#{builds_to_ban}),.*pageType=#{object_type}(,.*|)'"
      system(cmd)

    end
  end


  def get_country_mapping
    return {
        'uk' => 'GB', # daily occurence: 675735
        'ireland' => 'IE', # daily occurence: 175153
        'india' => 'IN', # daily occurence: 97870
        'australia' => 'AU', # daily occurence: 62191
        'philippines' => 'PH', # daily occurence: 56729
        'malaysia' => 'MY', # daily occurence: 53377
        'singapore' => 'SG', # daily occurence: 48206
        'canada' => 'CA', # daily occurence: 46373
        'mexico' => 'US', # daily occurence: 46136     rewritten from: MX
        'thailand' => 'TH', # daily occurence: 33414
        'turkey' => 'TR', # daily occurence: 32840
        'south-africa' => 'ZA', # daily occurence: 31915
        'united-arab-emirates' => 'AE', # daily occurence: 22687
        'spain' => 'ES', # daily occurence: 19140
        'poland' => 'PL', # daily occurence: 14108
        'egypt' => 'EG', # daily occurence: 12794
        'hungary' => 'HU', # daily occurence: 11543
        'us' => 'US', # daily occurence: 10223
        'south-korea' => 'KR', # daily occurence: 10183
        'cyprus' => 'CY', # daily occurence: 8688
        'romania' => 'RO', # daily occurence: 8479
        'indonesia' => 'ID', # daily occurence: 8267
        'belgium' => 'BE', # daily occurence: 6839
        'costa-rica' => 'US', # daily occurence: 6788      rewritten from: CR
        'czech-republic' => 'CZ', # daily occurence: 6641
        'new-zealand' => 'NZ', # daily occurence: 6500
        'vietnam' => 'VN', # daily occurence: 6167
        'switzerland' => 'CH', # daily occurence: 5701
        'greece' => 'GR', # daily occurence: 5620
        'germany' => 'DE', # daily occurence: 5311
        'bulgaria' => 'BG', # daily occurence: 5216
        'croatia' => 'HR', # daily occurence: 4829
        'malta' => 'MT', # daily occurence: 3938
        'hong-kong-sar' => 'HK', # daily occurence: 3915
        'lebanon' => 'LB', # daily occurence: 3690
        'dominican-republic' => 'DO', # daily occurence: 3275
        'macedonia' => 'MK', # daily occurence: 3229
        'brazil' => 'BR', # daily occurence: 2977
        'italy' => 'IT', # daily occurence: 2842
        'argentina' => 'AR', # daily occurence: 2755
        'serbia' => 'RS', # daily occurence: 2374
        'panama' => 'PA', # daily occurence: 2297
        'israel' => 'IL', # daily occurence: 2171
        'france' => 'FR', # daily occurence: 2108
        'latvia' => 'LV', # daily occurence: 2091
        'jordan' => 'JO', # daily occurence: 2032
        'nepal' => 'NP', # daily occurence: 2014
        'peru' => 'PE', # daily occurence: 2004
        'russia' => 'RU', # daily occurence: 1934
        'netherlands' => 'NL', # daily occurence: 1787
        'albania' => 'AL', # daily occurence: 1785
        'lithuania' => 'LT', # daily occurence: 1770
        'portugal' => 'PT', # daily occurence: 1727
        'ukraine' => 'UA', # daily occurence: 1491
        'guatemala' => 'GT', # daily occurence: 1481
        'pakistan' => 'PK', # daily occurence: 1383
        'tunisia' => 'TN', # daily occurence: 1188
        'estonia' => 'EE', # daily occurence: 1175
        'china' => 'CN', # daily occurence: 1094
        'colombia' => 'CO', # daily occurence: 1072
        'oman' => 'OM', # daily occurence: 978
        'saudi-arabia' => 'SA', # daily occurence: 954
        'slovakia' => 'SK', # daily occurence: 880
        'austria' => 'AT', # daily occurence: 871
        'georgia' => 'GE', # daily occurence: 854
        'japan' => 'JP', # daily occurence: 816
        'armenia' => 'AM', # daily occurence: 644
        'cambodia' => 'KH', # daily occurence: 600
        'syria' => 'SY', # daily occurence: 579
        'chile' => 'CL', # daily occurence: 557
        'cuba' => 'CU', # daily occurence: 552
        'tanzania' => 'TZ', # daily occurence: 550
        'mauritius' => 'MU', # daily occurence: 481
        'qatar' => 'QA', # daily occurence: 450
        'ecuador' => 'EC', # daily occurence: 375
        'slovenia' => 'SI', # daily occurence: 359
        'nicaragua' => 'NI', # daily occurence: 343
        'libya' => 'LY', # daily occurence: 294
        'isle-of-man' => 'IM', # daily occurence: 287
        'uruguay' => 'UY', # daily occurence: 286
        'bosnia-and-herzegovina' => 'BA', # daily occurence: 259
        'finland' => 'FI', # daily occurence: 250
        'iraq' => 'IQ', # daily occurence: 245
        'uganda' => 'UG', # daily occurence: 240
        'kenya' => 'KE', # daily occurence: 206
        'venezuela' => 'VE', # daily occurence: 201
        'montenegro' => 'ME', # daily occurence: 200
        'antarctica' => 'AQ', # daily occurence: 193
        'moldova' => 'MD', # daily occurence: 181
        'denmark' => 'DK', # daily occurence: 153
        'barbados' => 'BB', # daily occurence: 150
        'iran' => 'IR', # daily occurence: 143
        'bangladesh' => 'BD', # daily occurence: 127
        'sweden' => 'SE', # daily occurence: 122
        'liechtenstein' => 'LI', # daily occurence: 116
        'palestinian-authority' => 'PS', # daily occurence: 107
        'azerbaijan' => 'AZ', # daily occurence: 107
        'guernsey' => 'GG', # daily occurence: 107
        'gibraltar' => 'GI', # daily occurence: 102
        'ghana' => 'GH', # daily occurence: 86
        'st-lucia' => 'LC', # daily occurence: 80
        'puerto-rico' => 'PR', # daily occurence: 76
        'morocco' => 'MA', # daily occurence: 67
        'nigeria' => 'NG', # daily occurence: 62
        'haiti' => 'HT', # daily occurence: 44
        'norway' => 'NO', # daily occurence: 44
        'jersey' => 'JE', # daily occurence: 41
        'taiwan' => 'TW', # daily occurence: 39
        'kuwait' => 'KW', # daily occurence: 32
        'sri-lanka' => 'LK', # daily occurence: 24
        'trinidad-and-tobago' => 'TT', # daily occurence: 23
        'belarus' => 'BY', # daily occurence: 19
        'san-marino' => 'SM', # daily occurence: 18
        'martinique' => 'MQ', # daily occurence: 17
        'seychelles' => 'SC', # daily occurence: 9
        'el-salvador' => 'SV', # daily occurence: 8
        'mali' => 'ML', # daily occurence: 2
        'mongolia' => 'MN', # daily occurence: 2
        'united-states-minor-outlying-islands' => 'UM', # daily occurence: 2
        'yemen' => 'YE', # daily occurence: 1
        'kyrgyzstan' => 'KG', # daily occurence: 1
        'samoa' => 'WS', # daily occurence: 0
        'iceland' => 'IS', # daily occurence: 0
        'namibia' => 'NA', # daily occurence: 0
        'cameroon' => 'CM', # daily occurence: 0
        'afghanistan' => 'AF', # daily occurence: 0
    }

  end

end

ClearCache.new.init