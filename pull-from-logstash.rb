
require "net/http"
require "uri"
require "json"

class PullFromLogStash

  def init

    cmd = "curl -XPOST 'http://prod.log.whatclinic.com/elasticsearch/logstash-2015.10.15/_search?pretty' -d '#{get_query}' "
    response = `#{cmd}`

    puts "----------------"
    json = JSON.parse(response)



    puts json["hits"]["hits"].size

    urls = json["hits"]["hits"]
    puts urls.first["_source"]["xVarnishRequestUrl"]

    urls.each_with_index do |url,index|
       puts "#{url["_source"]["xVarnishRequestUrl"]}"
    end

  end

  def get_query

    return '{"query": {
        "filtered": {
        "query": {
        "bool": {
        "should": [
        {
            "query_string": {
        "query": "logsource.raw:\"dublin.en.prod.varnish\" AND (paginated)"
    }
    },
        {
            "query_string": {
        "query": "logsource.raw:\"singapore.en.prod.varnish\" AND (paginated)"
    }
    },
        {
            "query_string": {
        "query": "logsource.raw:\"sydney.en.prod.varnish\" AND (paginated)"
    }
    },
        {
            "query_string": {
        "query": "logsource.raw:\"virginia.en.prod.varnish\" AND (paginated)"
    }
    },
        {
            "query_string": {
        "query": "logsource.raw:\"california.en.prod.varnish\" AND (paginated)"
    }
    }
    ]
    }
    },
        "filter": {
        "bool": {
        "must": [
        {
            "terms": {
        "appSource": [
        "varnish"
    ]
    }
    },
        {
            "range": {
        "@timestamp": {
        "from": 1444879079259,
        "to": 1444900679259
    }
    }
    },
        {
            "terms": {
        "appSource": [
        "access_log"
    ]
    }
    },
        {
            "terms": {
        "appSource": [
        "prod"
    ]
    }
    },
        {
            "terms": {
        "appSource": [
        "en"
    ]
    }
    }
    ]
    }
    }
    }
    },
        "highlight": {
        "fields": {},
        "fragment_size": 2147483647,
        "pre_tags": [
        "@start-highlight@"
    ],
        "post_tags": [
        "@end-highlight@"
    ]
    },
        "size": 500,
        "sort": [
        {
            "@timestamp": {
        "order": "desc",
        "ignore_unmapped": true
    }
    }
    ]
    }'


  end
end

PullFromLogStash.new.init