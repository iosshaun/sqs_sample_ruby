#!/usr/bin/ruby

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

require "lib/aws/sqs.rb"
require "lib/aws/sqs/client.rb"
require "lib/aws/sqs/queue.rb"

require 'cgi'

AWS_ACCESS_KEY_ID = ''
AWS_SECRET_ACCESS_KEY = ''
ENDPOINT = 'http://queue.amazonaws.com/'
AMAZON_SQS_TEST_QUEUE = "SQS-Test-Queue-Ruby"
SQS_TEST_MESSAGE = 'This is a test message.'

begin
  client = AWS::SQS::Client.new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, :endpoint => ENDPOINT)

  ##############################################################################
  # Create our Queue...
  # Note: If the queue has recently been deleted, the application needs to wait for 60 seconds before
  # a queue with the same name can be created again.
  ##############################################################################

  try_again = true
  while try_again
    begin
      try_again = false
      queue = client.create_queue(AMAZON_SQS_TEST_QUEUE)
      puts "1) Queue Created: " + queue.url
    rescue => err
      ##############################################################################
      # Was the queue recently deleted?
      ##############################################################################
      if err == 'AWS.SimpleQueueService.QueueDeletedRecently'
        ##############################################################################
        # Yes - wait 60 seconds and retry (propagation delay)
        ##############################################################################
        puts '1a) AWS.SimpleQueueService.QueueDeletedRecently -- waiting 60 seconds...'
        sleep(60)
        try_again = true
      else
        puts err.to_s 
      end
    end
  end
  
  ##############################################################################
  # Retrieve our queues - verify our queue exists...
  ##############################################################################
  retry_count = 0
  try_again = true
  while try_again
    queues = client.list_queues
    ##############################################################################
  	# Does our queue exist yet?
    ##############################################################################
    if queues.to_s =~ /\/#{AMAZON_SQS_TEST_QUEUE}/
      retry_count = 0
      try_again = false
      puts "2) Queue Found"
    else
      try_again = true
      retry_count += 1
      sleep(1)
      puts("2a) Queue not available yet - keep polling (" + retry_count.to_s + ")")
    end
  end
  
  ##############################################################################	
  # Send a message...
  ##############################################################################
  message_id = queue.send_message(CGI.escape(SQS_TEST_MESSAGE))
  puts "3) Message Sent"
  puts "message id: " + message_id

  ##############################################################################	
  # Get Approximate Queue Count...
  # Since distributed system, the count may not be accurate.
  ##############################################################################	
  attribute = queue.get_queue_attributes("ApproximateNumberOfMessages")
  puts "4) Approximate Number of Messages: " + attribute

  ##############################################################################	
  # Receive the message...
  # If SQS returns empty, the message is not available yet.  We keep retrying 
  # until message is delivered.
  ##############################################################################	
  try_again = true
  while try_again
    begin
      try_again = false
      messages = queue.receive_messages
      if messages.empty?
        puts 'No messages available - keep polling...'
        try_again = true
        sleep(1)
      ##############################################################################	
  		# Message received...
      ##############################################################################	
      else
        messages.each do |message| 
          message_id = message["Message"][0]["MessageId"][0]
          puts "5) Message Received"
          puts "message id: " + message_id
          @receipt_handle = message["Message"][0]["ReceiptHandle"][0]
          puts "receipt handle: " + @receipt_handle
          body = message["Message"][0]["Body"][0]
          puts "message: " + CGI.unescape(body)
        end
      end
    rescue Exception
      puts 'Test message not available - keep polling...'
      try_again = true
      sleep(1)
    end
  end
  
  ##############################################################################	
  # Delete message...
  ##############################################################################	
  if queue.delete_message(@receipt_handle)
    puts "6) Message deleted"
  end

  ##############################################################################	
  # Delete queue...
  ##############################################################################	
  if queue.delete_queue()
    puts "7) Queue deleted"
  end

##############################################################################	
# General exception - exit and report error...
##############################################################################	
rescue Exception => err
  puts "Exception occurred: " + err.to_s 
end
