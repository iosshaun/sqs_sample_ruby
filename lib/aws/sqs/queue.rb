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
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

module AWS
  module SQS
    class Queue  
      attr_reader :name, :url
  
      def initialize(name, url, sqs_client)
        @name, @url, @sqs_client = name, url, sqs_client
      end

      def push(body)
        send_message(body)
      end

      def pop()
        # Lock for 10 seconds.
        msg = receive_messages(1, 10)

        if msg[0].empty?
          return nil
        end

        @receipt_handle = msg[0]["Message"][0]["ReceiptHandle"][0]
        if delete_message(@receipt_handle)
          return msg[0]["Message"][0]["Body"]
        else
          return nil
        end
      end
  
      ##############################################################################
      # Send a message to your queue
      ##############################################################################
      def send_message(body)
        params = {}
        params['MessageBody'] = body
        result = @sqs_client.make_request('SendMessage', self.url, params)

        unless result.include?('Error')
          return result['SendMessageResult'][0]['MessageId'][0].to_s
        else
          raise Exception, "Amazon SQS Error Code: " + result['Error'][0]['Code'][0] +
                           "\n" + result['Error'][0]['Message'][0]
        end
      end
  
      ##############################################################################
      # Get a message(s) from your queue
      ##############################################################################
      def receive_messages(max_number_of_messages = -1, visibility_timeout = -1)
        # Convert these params to strings so CGI escaping won't freak out.
        params = {}
        params['MaxNumberOfMessages'] = max_number_of_messages.to_s if max_number_of_messages > -1
        params['VisibilityTimeout'] = visibility_timeout.to_s if visibility_timeout > -1
        result = @sqs_client.make_request('ReceiveMessage', self.url, params)
        unless result.include?('Error')
          return result['ReceiveMessageResult']
        else
          raise Exception, "Amazon SQS Error Code: " + result['Error'][0]['Code'][0] +
    			                 "\n" + result['Error'][0]['Message'][0]
        end
      end

      ##############################################################################
      # Delete a message
      ##############################################################################
      def delete_message(receipt_handle)
        params = {}
        params['ReceiptHandle'] = receipt_handle
        result = @sqs_client.make_request('DeleteMessage', self.url, params)
        unless result.include?('Error')
          return true
        else
          raise Exception, "Amazon SQS Error Code: " + result['Error'][0]['Code'][0] +
                           "\n" + result['Error'][0]['Message'][0]
        end
      end
    	
      ##############################################################################
      # Get a queue attribute
      ##############################################################################
      def get_queue_attributes(attribute)
        params = {}
        params['AttributeName'] = attribute
        result = @sqs_client.make_request('GetQueueAttributes', self.url, params)
        unless result.include?('Error')
          return result['GetQueueAttributesResult'][0]['Attribute'][0]["Value"][0]
        else
          raise Exception, "Amazon SQS Error Code: " + result['Error'][0]['Code'][0] +
                           "\n" + result['Error'][0]['Message'][0]
        end
      end

      ######################################################################### 
      # Delete the specified queue
      #
      # Note: this will delete ALL messages in your queue, so use this function
      # with caution!
      #########################################################################
      def delete_queue()
        result = @sqs_client.make_request('DeleteQueue', self.url)
        unless result.include?('Error')
          return true
        else
          raise Exception, "Amazon SQS Error Code: " + result['Error'][0]['Code'][0] +
                           "\n" + result['Error'][0]['Message'][0]
        end
      end # delete_queue
    end # Queue
  end # SQS
end # AWS
