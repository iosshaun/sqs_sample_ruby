module AWS
  module SQS
    module VERSION
      MAJOR = '0'
      MINOR = '1'
      TINY = '1'
    end

    Version = [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY].compact * '.'
  end
end
