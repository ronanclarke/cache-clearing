
require "net/http"
require "uri"
require "json"

class PullFromLogStash

  def init

    cmd = "curl -XPOST 'http://prod.log.whatclinic.com/elasticsearch/logstash-2015.09.21/_search?pretty' -d '#{get_query}' "
    response = `#{cmd}`

    puts "----------------"
    json = JSON.parse(response)
    puts json["hits"]["hits"].size

    urls = json["hits"]["hits"]
    puts urls.first["_source"]["xVarnishRequestUrl"]

    urls.each_with_index do |url,index|
       puts "#{index} #{url["_source"]["xVarnishRequestUrl"]}"
    end

  end

  def get_query

    return '{
  "query": {
    "filtered": {
      "query": {
        "bool": {
          "should": [
            {
              "query_string": {
                "query": "logsource.raw:\"dublin.en.prod.varnish\" AND (*)"
              }
            },
            {
              "query_string": {
                "query": "logsource.raw:\"virginia.en.prod.varnish\" AND (*)"
              }
            },
            {
              "query_string": {
                "query": "logsource.raw:\"california.en.prod.varnish\" AND (*)"
              }
            },
            {
              "query_string": {
                "query": "logsource.raw:\"singapore.en.prod.varnish\" AND (*)"
              }
            },
            {
              "query_string": {
                "query": "logsource.raw:\"sydney.en.prod.varnish\" AND (*)"
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
                  "from": 1442834572100,
                  "to": 1442838172101
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
            },
{
              "fquery": {
                "query": {
                  "query_string": {
                    "query": "clientProxyStage:(\"Proxy\")"
                  }
                },
                "_cache": true
              }
            },
            {
              "terms": {
                "pageType": [
                  "brochure"
                ]
              }
            }
          ]
        }
      }
    }
  },
  "highlight": {
    "fields": {
      "requestUrl": {}
    },
    "fragment_size": 2147483647,
    "pre_tags": [
      "@start-highlight@"
    ],
    "post_tags": [
      "@end-highlight@"
    ]
  },
  "size": 50000,
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