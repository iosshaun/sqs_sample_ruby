# Copyright 2009 JibJab Media, Inc. Licensed under the Apache License, Version
# 2.0 (the "License").
#
# Copyright 2007 Amazon Technologies, Inc.  Licensed under the Apache License,
# Version 2.0 (the "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at:
#
# http://aws.amazon.com/apache2.0
#
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.

module AWS
  module SQS
    class Client
      require 'rubygems'
      require 'net/http'
      require 'openssl'
      require 'base64'
      require 'cgi'
      require 'time'
      require 'xmlsimple'
            
      attr_reader :endpoint
      
      # default options
      DEFAULT_SQS_OPTIONS = { :endpoint => "http://queue.amazonaws.com" }
      
      ##############################################################################      
      # Use hardcoded endpoint (default)
      # AWS::SQS::Client.new(XXXXXXXXXXXXXX,XXXXXXXXXXXXXXXXXXXXX)
      # Specify endpoint
      # AWS::SQS::Client.new(XXXXXXXXXXXXXX,XXXXXXXXXXXXXXXXXXXXX, :endpoint =>
      # 'http://queue.amazonaws.com')
      ##############################################################################      
      def initialize( aws_access_key_id, aws_secret_access_key, options = {} )
        @aws_access_key_id, @aws_secret_access_key = aws_access_key_id, aws_secret_access_key
        opts = DEFAULT_SQS_OPTIONS.merge(options)
        @endpoint = opts[:endpoint]
      end
    
      ##############################################################################
      # Get an array of queues
      ##############################################################################
      def list_queues()
        result = make_request('ListQueues')
        value = result['ListQueuesResult']
        unless value.nil?
          return value
        else
          raise Exception, "Amazon SQS Error Code: " + result['Error'][0]['Code'][0] +
                           "\n" + result['Error'][0]['Message'][0]
        end
      end
    
      ##############################################################################    	
      # Create a new queue
      ##############################################################################
      def create_queue(name)
        params = {}
        params['QueueName'] = name
        result = make_request('CreateQueue', nil, params)

        unless result.include?('Error')
          queue_url = result['CreateQueueResult'][0]['QueueUrl'][0]
          return AWS::SQS::Queue.new(name, queue_url, self)
        else
          raise Exception, "Amazon SQS Error Code: " + result['Error'][0]['Code'][0] +
                           "\n" + result['Error'][0]['Message'][0]
        end
      end
    
      ##############################################################################
      # Send a query request and return a SimpleXML object
      ##############################################################################
      def make_request(action, queue_url = nil, params = {})
        # Add Actions
        params['Action'] = action
        params['Version'] = '2009-02-01'
        params['AWSAccessKeyId'] = @aws_access_key_id
        params['Expires']= (Time.now + 10).gmtime.iso8601
        params['SignatureMethod'] = 'HmacSHA1'
        params['SignatureVersion'] = '2'
    	      
        # Sign the string
        sorted_params = params.sort_by { |key,value| key }
        joined_params = sorted_params.collect { |key, value| "#{CGI.escape(key)}=#{CGI.escape(value)}"}.join("&")

        if queue_url && !queue_url.empty?
          endpoint_uri = URI.parse(queue_url)
        else
          endpoint_uri = URI.parse(self.endpoint)
        end

        endpoint_hostname = endpoint_uri.host
        endpoint_path = endpoint_uri.path

        string_to_sign = "GET\n#{endpoint_hostname}\n#{endpoint_path}\n" + joined_params

        digest = OpenSSL::Digest::Digest.new('sha1')
        hmac = OpenSSL::HMAC.digest(digest, @aws_secret_access_key, string_to_sign)
        params['Signature'] = Base64.encode64(hmac).chomp

        # Construct request
        query = params.collect { |key, value| CGI.escape(key) + "=" + CGI.escape(value) }.join("&")

        if queue_url && !queue_url.empty?
          query = endpoint_uri.path + "?" + query
        else
          query = "/?" + query
        end

        # You should always retry a 5xx error, as some of these are expected
        retry_count = 0
        try_again = true
        uri = URI.parse(self.endpoint)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(query)

        while try_again do
          # Send Amazon SQS query to endpoint
          response = http.start { |http|
            http.request(request)
          }
          # Check if we should retry this request
          if response == Net::HTTPServerError && retry_count <= 5
            retry_count ++
            sleep(retry_count / 4 * retry_count)
          else
            try_again = false
            xml = response.body.to_s
            return XmlSimple.xml_in(xml)
          end
        end
      end
    end # Client
  end # SQS
end # AWS
