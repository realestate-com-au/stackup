require "console_logger"
require "spec_helper"

describe Stackup::Stack do

  let(:cf_client) do
    client_options = { :stub_responses => true }
    if ENV.key?("AWS_DEBUG")
      client_options[:logger] = ConsoleLogger.new(STDOUT, true)
      client_options[:log_level] = :debug
    end
    Aws::CloudFormation::Client.new(client_options)
  end

  let(:stack_name) { "stack_name" }
  let(:unique_stack_id) { "ID:#{stack_name}" }

  subject(:stack) { described_class.new(stack_name, cf_client) }

  before do
    cf_client.stub_responses(:describe_stacks, *describe_stacks_responses)
    allow(stack).to receive(:sleep).at_most(5).times
    # partial stubbing, to support spying
    allow(cf_client).to receive(:create_stack).and_call_original
    allow(cf_client).to receive(:delete_stack).and_call_original
    allow(cf_client).to receive(:update_stack).and_call_original
    allow(cf_client).to receive(:cancel_update_stack).and_call_original
  end

  def validation_error(message)
    {
      :status_code => 400,
      :headers => {},
      :body => "<ErrorResponse><Error><Code>ValidationError</Code><Message>#{message}</Message></Error></ErrorResponse>"
    }
  end

  def stack_does_not_exist
    validation_error("Stack with id #{stack_name} does not exist")
  end

  def no_update_required
    validation_error("No updates are to be performed.")
  end

  def stack_description(stack_status)
    {
      :stacks => [
        {
          :creation_time => Time.now - 100,
          :stack_id => unique_stack_id,
          :stack_name => stack_name,
          :stack_status => stack_status
        }
      ]
    }
  end

  context "before stack exists" do

    let(:describe_stacks_responses) do
      [
        stack_does_not_exist
      ]
    end

    describe "#exists?" do
      it "is false" do
        expect(stack.exists?).to be false
      end
    end

    describe "#status" do
      it "raises a NoSuchStack error" do
        expect { stack.status }.to raise_error(Stackup::NoSuchStack)
      end
    end

    describe "#delete" do
      it "returns nil" do
        expect(stack.delete).to be_nil
      end
    end

    describe "#create_or_update" do

      let(:template) { "stack template" }

      def create_or_update
        stack.create_or_update(template)
      end

      context "successful" do

        let(:describe_stacks_responses) do
          super() + [
            stack_description("CREATE_IN_PROGRESS"),
            stack_description("CREATE_COMPLETE")
          ]
        end

        it "calls :create_stack" do
          expected_args = {
            :stack_name => stack_name,
            :template_body => template
          }
          create_or_update
          expect(cf_client).to have_received(:create_stack)
            .with(hash_including(expected_args))
        end

        it "returns :created" do
          expect(create_or_update).to eq(:created)
        end

      end

      context "unsuccessful" do

        let(:describe_stacks_responses) do
          super() + [
            stack_description("CREATE_IN_PROGRESS"),
            stack_description("CREATE_FAILED")
          ]
        end

        it "raises a StackUpdateError" do
          expect { create_or_update }
            .to raise_error(Stackup::StackUpdateError)
        end

      end

    end

  end

  context "with existing stack" do

    let(:stack_status) { "CREATE_COMPLETE" }

    let(:describe_stacks_responses) do
      [
        stack_description(stack_status)
      ]
    end

    describe "#exists?" do
      it "is true" do
        expect(stack.exists?).to be true
      end
    end

    describe "#status" do
      it "returns the stack status" do
        expect(stack.status).to eq(stack_status)
      end
    end

    describe "#delete" do

      context "if successful" do

        let(:describe_stacks_responses) do
          super() + [
            stack_description("DELETE_IN_PROGRESS"),
            stack_description("DELETE_COMPLETE")
          ]
        end

        it "calls delete_stack" do
          stack.delete
          expect(cf_client).to have_received(:delete_stack)
            .with(hash_including(:stack_name => unique_stack_id))
        end

        it "returns :deleted" do
          expect(stack.delete).to eq(:deleted)
        end

      end

      context "if unsuccessful" do

        let(:describe_stacks_responses) do
          super() + [
            stack_description("DELETE_IN_PROGRESS"),
            stack_description("DELETE_FAILED")
          ]
        end

        it "raises a StackUpdateError" do
          expect { stack.delete }.to raise_error(Stackup::StackUpdateError)
        end

      end

    end

    describe "#create_or_update" do

      let(:template) { "stack template" }

      def create_or_update
        stack.create_or_update(template)
      end

      context "successful" do

        let(:describe_stacks_responses) do
          super() + [
            stack_description("UPDATE_IN_PROGRESS"),
            stack_description("UPDATE_COMPLETE")
          ]
        end

        it "calls :update_stack" do
          expected_args = {
            :stack_name => stack_name,
            :template_body => template
          }
          create_or_update
          expect(cf_client).to have_received(:update_stack)
            .with(hash_including(expected_args))
        end

        it "returns :updated" do
          expect(create_or_update).to eq(:updated)
        end

        context "if no updates are required" do

          before do
            cf_client.stub_responses(:update_stack, no_update_required)
          end

          it "returns nil" do
            expect(create_or_update).to be_nil
          end

        end

      end

      context "unsuccessful" do

        let(:describe_stacks_responses) do
          super() + [
            stack_description("UPDATE_IN_PROGRESS"),
            stack_description("UPDATE_ROLLBACK_COMPLETE")
          ]
        end

        it "raises a StackUpdateError" do
          expect { create_or_update }.to raise_error(Stackup::StackUpdateError)
        end

      end

    end

    %w(CREATE_FAILED ROLLBACK_COMPLETE).each do |initial_status|
      context "when status is #{initial_status}" do

        let(:stack_status) { initial_status }

        describe "#create_or_update" do

          let(:template) { "stack template" }

          def create_or_update
            stack.create_or_update(template)
          end

          let(:describe_stacks_responses) do
            super() + [
              stack_description("DELETE_IN_PROGRESS"),
              stack_does_not_exist,
              stack_description("CREATE_IN_PROGRESS"),
              stack_description("CREATE_COMPLETE")
            ]
          end

          before do
            cf_client.stub_responses(:update_stack, stack_does_not_exist)
          end

          it "calls :delete_stack, then :create_stack first" do
            create_or_update
            expect(cf_client).to have_received(:delete_stack)
            expect(cf_client).to have_received(:create_stack)
          end

        end

      end
    end

    context "when status is stable" do

      before do
        cf_client.stub_responses :cancel_update_stack,
          validation_error("that cannot be called from current stack status")
      end

      describe "#cancel_update" do

        it "returns nil" do
          expect(stack.cancel_update).to be_nil
        end

      end

    end

    context "when status is UPDATE_IN_PROGRESS" do

      let(:stack_status) { "UPDATE_IN_PROGRESS" }

      describe "#cancel_update" do

        let(:describe_stacks_responses) do
          super() + [
            stack_description("UPDATE_ROLLBACK_IN_PROGRESS"),
            stack_description("UPDATE_ROLLBACK_COMPLETE")
          ]
        end

        it "calls :cancel_update_stack" do
          expected_args = {
            :stack_name => stack_name
          }
          stack.cancel_update
          expect(cf_client).to have_received(:cancel_update_stack)
            .with(hash_including(expected_args))
        end

        it "returns :update_cancelled" do
          expect(stack.cancel_update).to eq(:update_cancelled)
        end

      end

    end

  end

end
