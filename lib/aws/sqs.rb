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

$:.unshift(File.dirname(__FILE__))
require 'sqs/client'
require 'sqs/queue'
require 'sqs/version'

module AWS
  module SQS
    # strings are UTF-8 encoded
    if RUBY_VERSION < "1.9"
      $KCODE = "u"
    end
  end
end

