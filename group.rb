# Couch wrapper from http://wiki.apache.org/couchdb/Getting_started_with_Ruby
require 'rubygems'
require 'net/http'

module Couch

  class Server
    def initialize(host, port, options = nil)
      @host = host
      @port = port
      @options = options
    end

    def delete(uri)
      request(Net::HTTP::Delete.new(uri))
    end

    def get(uri)
      request(Net::HTTP::Get.new(uri))
    end

    def put(uri, json)
      req = Net::HTTP::Put.new(uri)
      req["content-type"] = "application/json"
      req.body = json
      request(req)
    end

    def post(uri, json)
      req = Net::HTTP::Post.new(uri)
      req["content-type"] = "application/json"
      req.body = json
      request(req)
    end

    def request(req)
      res = Net::HTTP.start(@host, @port) { |http|http.request(req) }
      unless res.kind_of?(Net::HTTPSuccess)
        handle_error(req, res)
      end
      res
    end

    private

    def handle_error(req, res)
      e = RuntimeError.new("#{res.code}:#{res.message}\nMETHOD:#{req.method}\nURI:#{req.path}\n#{res.body}")
      raise e
    end
  end
end
# end Couch wrapper

require 'json'

COUCH = "your couch url here"
DB = "group"
@server = Couch::Server.new(COUCH, "5984")

def save(number)
  doc = <<-JSON
  {"type":"contact","number":"#{number}"}
  JSON
  @server.post("/#{DB}", doc)
end

def getView(view)
  server = Couch::Server.new("localhost", "5984")
  res = @server.get("/#{DB}/_design/group/_view/#{view}")
  JSON.parse(res.body)
end

number = $currentCall.callerID.to_s
numbers = getView('numbers')['rows'].map{|row| row['value']['number'].to_s}
save(number) unless numbers.include? number

def send(message, numbers)
  numbers.each do |number|
    message(message, {
      :to => number,
      :network => "SMS",
      :callerID => $currentCall.calledID.to_s
    })
  end
  
  say message
end

send($currentCall.initialText, numbers)