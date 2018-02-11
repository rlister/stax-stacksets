require 'stax/stacksets/aws/cfn'
require 'stax/aws/sts'

module Stax
  module Cmd
    class Stackset < SubCommand
      COLORS = {
        ACTIVE:     :green,
        DELETED:    :red,
        CURRENT:    :green,
        OUTDATED:   :yellow,
        INOPERABLE: :red,
      }

      desc 'create', 'create a stackset'
      def create
        debug("Creating stackset #{my.stack_set_name}")
        Aws::Cfn.client.create_stack_set(
          stack_set_name: my.stack_set_name,
          template_body: my.stack_template,
        )&.stack_set_id.tap(&method(:puts))
        Aws::Cfn.client.create_stack_instances(
          stack_set_name: my.stack_set_name,
          accounts: my.stack_set_accounts,
          regions: my.stack_set_regions,
        )&.operation_id.tap(&method(:puts))
      rescue ::Aws::CloudFormation::Errors::NameAlreadyExistsException => e
        warn(e.message)
      end

      desc 'delete', 'delete stackset and instances'
      method_option :accounts, aliases: '-a', type: :array,   default: nil,   desc: 'accounts to delete instances'
      method_option :regions,  aliases: '-r', type: :array,   default: nil,   desc: 'regions to delete instances'
      method_option :retain,   aliases: '-R', type: :boolean, default: false, desc: 'retain stacks'
      def delete
        ## delete stack instances
        accounts = options[:accounts] || my.stack_set_accounts
        regions  = options[:regions]  || my.stack_set_regions
        if yes? "Really delete stack instances for #{my.stack_set_name} #{accounts.join(',')} #{regions.join(',')}", :yellow
          op = Aws::Cfn.client.delete_stack_instances(
            stack_set_name: my.stack_set_name,
            accounts: accounts,
            regions: regions,
            retain_stacks: options[:retain],
          )&.operation_id.tap(&method(:puts))
        end

        loop do
          r = Aws::Cfn.client.describe_stack_set_operation(stack_set_name: my.stack_set_name, operation_id: op)&.stack_set_operation
          fail_task(r.status) if r.status == 'FAILED'
          break if r.status == 'SUCCEEDED'
          puts "#{r.action} is #{r.status}, waiting ..."
          sleep(3)
        end

        ## delete stack set
        if yes? "Really delete stackset #{my.stack_set_name}?", :yellow
          Aws::Cfn.client.delete_stack_set(stack_set_name: my.stack_set_name)
        end
      end

      desc 'instances', 'list stack instances for set'
      def instances
        print_table Aws::Cfn.stack_instances(stack_set_name: my.stack_set_name).map { |i|
          [i.account, i.region, i.stack_id&.split('/')[-2], color(i.status, COLORS), i.status_reason]
        }
      end

      desc 'ls', 'list stack sets'
      method_option :status, aliases: '-s', type: :string, default: 'ACTIVE', desc: 'list ACTIVE or DELETED'
      def ls
        print_table Aws::Cfn.stack_sets(status: options[:status].upcase).map { |s|
          [s.stack_set_name, s.stack_set_id, color(s.status, COLORS), s.description]
        }
      end
    end
  end

  class Stack < Base

    no_commands do
      def stack_set_name
        stack_name
      end

      def stack_set_accounts
        [Aws::Sts.id.account]
      end

      def stack_set_regions
        [ENV['AWS_REGION']]
      end

      def stack_template
        capture_stdout { cfer_generate }
      end
    end

    desc 'stackset', 'stackset'
    subcommand :stackset, Cmd::Stackset

  end

end