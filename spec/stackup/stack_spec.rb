require "spec_helper"

describe Stackup::Stack do

  let(:cf_client) do
    client_options = { :stub_responses => true }
    if ENV.key?("AWS_DEBUG")
      client_options[:logger] = Logger.new(STDOUT)
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
  end

  def service_error(code, message)
    {
      :status_code => 400,
      :headers => {},
      :body => "<ErrorResponse><Error><Code>#{code}</Code><Message>#{message}</Message></Error></ErrorResponse>"
    }
  end

  def stack_does_not_exist
    service_error("ValidationError", "Stack with id #{stack_name} does not exist")
  end

  def no_update_required
    service_error("ValidationError", "No updates are to be performed.")
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

    describe "#deploy" do

      let(:template) { "stack template" }

      def deploy
        stack.deploy(template)
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
          deploy
          expect(cf_client).to have_received(:create_stack)
            .with(hash_including(expected_args))
        end

        it "returns :created" do
          expect(deploy).to eq(:created)
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
          expect { deploy }
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
            stack_does_not_exist
          ]
        end

        it "calls delete_stack" do
          stack.delete
          expect(cf_client).to have_received(:delete_stack)
            .with(hash_including(:stack_name => stack_name))
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

    describe "#deploy" do

      let(:template) { "stack template" }

      def deploy
        stack.deploy(template)
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
          deploy
          expect(cf_client).to have_received(:update_stack)
            .with(hash_including(expected_args))
        end

        it "returns :updated" do
          expect(deploy).to eq(:updated)
        end

        context "if no updates are required" do

          before do
            cf_client.stub_responses(:update_stack, no_update_required)
          end

          it "returns nil" do
            expect(deploy).to be_nil
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
          expect { deploy }.to raise_error(Stackup::StackUpdateError)
        end

      end

    end

  end

end
