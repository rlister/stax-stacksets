require 'stax/aws/cfn'

module Stax
  module Aws
    class Cfn < Sdk

      class << self
        def stack_sets(opt)
          paginate(:summaries) do |token|
            client.list_stack_sets(opt.merge(next_token: token))
          end
        end

        def stack_instances(opt)
          paginate(:summaries) do |token|
            client.list_stack_instances(opt.merge(next_token: token))
          end
        end
      end

    end
  end
end