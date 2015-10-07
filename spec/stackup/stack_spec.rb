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
    # partial stubbing, to support spying
    allow(cf_client).to receive(:create_stack).and_call_original
    allow(cf_client).to receive(:delete_stack).and_call_original
    allow(stack).to receive(:sleep)
  end

  before do
    cf_client.stub_responses(:describe_stacks, *describe_stacks_responses)
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
      it "returns false" do
        expect(stack.delete).to be false
      end
    end

    describe "#deploy" do

      let(:template) { "stack template" }

      context "successful" do

        let(:describe_stacks_responses) do
          super() + [
            stack_description("CREATE_IN_PROGRESS"),
            stack_description("CREATE_COMPLETE")
          ]
        end

        let!(:return_value) do
          stack.deploy(template)
        end

        it "calls :create_stack" do
          expect(cf_client).to have_received(:create_stack)
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

        let!(:return_value) { stack.delete }

        it "calls delete_stack" do
          expect(cf_client).to have_received(:delete_stack)
            .with(hash_including(:stack_name => stack_name))
        end

        it "returns true" do
          expect(return_value).to be true
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

  end

  # before do
  #   allow(Aws::CloudFormation::Client).to receive(:new).and_return(cf_client)
  #   allow(Aws::CloudFormation::Stack).to receive(:new).and_return(cf_stack)
  #   allow(cf_stack).to receive(:events).and_return([])
  # end
  #
  # describe "#create" do
  #
  #   subject(:created) { stack.create(template, parameters) }
  #
  #   before do
  #     allow(cf_client).to receive(:create_stack).and_return(response)
  #   end
  #
  #   context "when stack gets successfully created" do
  #     before do
  #       allow(stack).to receive(:wait_for_events).and_return("CREATE_COMPLETE")
  #     end
  #     it { expect(created).to be true }
  #   end
  #
  #   context "when stack creation fails" do
  #     before do
  #       allow(stack).to receive(:wait_for_events).and_return("CREATE_FAILED")
  #     end
  #     it { expect{ created }.to raise_error Stackup::StackUpdateError }
  #   end
  #
  # end
  #
  # describe "#update" do
  #   subject(:updated) { stack.update(template, parameters) }
  #
  #   context "when there is no existing stack" do
  #     before do
  #       allow(stack).to receive(:exists?).and_return(false)
  #     end
  #     it { expect(updated).to be false }
  #   end
  #
  #   context "when there is an existing stack" do
  #     before do
  #       allow(stack).to receive(:exists?).and_return(true)
  #       allow(cf_client).to receive(:update_stack).and_return(response)
  #       allow(stack).to receive(:wait_for_events).and_return("UPDATE_COMPLETE")
  #     end
  #
  #     context "in a successfully deployed state" do
  #       before do
  #         allow(cf_stack).to receive(:stack_status).and_return("CREATE_COMPLETE")
  #       end
  #
  #       context "when stack gets successfully updated" do
  #         it { expect(updated).to be true }
  #       end
  #
  #       context "when stack update fails" do
  #         before do
  #           allow(stack).to receive(:wait_for_events).and_return("UPDATE_FAILED")
  #         end
  #         it { expect{ updated }.to raise_error Stackup::StackUpdateError }
  #       end
  #     end
  #
  #     context "in a ROLLBACK_COMPLETE state" do
  #       before do
  #         allow(cf_stack).to receive(:stack_status).and_return("ROLLBACK_COMPLETE")
  #       end
  #
  #       context "when deleting existing stack succeeds" do
  #
  #         it "deletes the existing stack" do
  #           allow(response).to receive(:[]).with(:stack_id).and_return("1")
  #           expect(stack).to receive(:delete).and_return(true)
  #           stack.update(template, parameters)
  #         end
  #
  #         context "when stack gets successfully updated" do
  #           before do
  #             allow(response).to receive(:[]).with(:stack_id).and_return("1")
  #             allow(stack).to receive(:delete).and_return(true)
  #           end
  #           it { expect(updated).to be true }
  #         end
  #
  #         context "when stack update fails" do
  #           before do
  #             allow(response).to receive(:[]).with(:stack_id).and_return("1")
  #             allow(stack).to receive(:delete).and_return(false)
  #           end
  #           it { expect(updated).to be false }
  #         end
  #       end
  #
  #       context "when deleting existing stack fails" do
  #         before do
  #           allow(stack).to receive(:delete).and_return(false)
  #         end
  #         it { expect(updated).to be false }
  #       end
  #     end
  #
  #     context "in a CREATE_FAILED state" do
  #       before do
  #         allow(cf_stack).to receive(:stack_status).and_return("CREATE_FAILED")
  #       end
  #
  #       it "does not try to delete the existing stack" do
  #         allow(response).to receive(:[]).with(:stack_id).and_return("1")
  #         expect(stack).not_to receive(:delete)
  #         stack.update(template, parameters)
  #       end
  #
  #       it "does not try to delete the existing stack" do
  #         allow(response).to receive(:[]).with(:stack_id).and_return("1")
  #         expect(cf_client).not_to receive(:delete_stack)
  #         expect(updated).to be false
  #       end
  #     end
  #   end
  # end
  #
  # describe "#deploy" do
  #
  #   subject(:deploy) { stack.deploy(template, parameters) }
  #
  #   context "when stack already exists" do
  #
  #     before do
  #       allow(stack).to receive(:exists?).and_return(true)
  #       allow(cf_stack).to receive(:stack_status).and_return("CREATE_COMPLETE")
  #       allow(cf_client).to receive(:update_stack).and_return({ stack_id: "stack-name" })
  #     end
  #
  #     it "updates the stack" do
  #       expect(stack).to receive(:update)
  #       deploy
  #     end
  #   end
  #
  #   context "when stack does not exist" do
  #
  #     before do
  #       allow(stack).to receive(:exists?).and_return(false)
  #       allow(cf_client).to receive(:create_stack).and_return({ stack_id: "stack-name" })
  #     end
  #
  #     it "creates a new stack" do
  #       expect(stack).to receive(:create)
  #       deploy
  #     end
  #   end
  # end
  #
  #
  # describe "#delete" do
  #
  #   subject(:deleted) { stack.delete }
  #
  #   context "there is an existing stack" do
  #     before do
  #       allow(stack).to receive(:exists?).and_return true
  #       allow(cf_client).to receive(:delete_stack)
  #     end
  #
  #     context "deleting the stack succeeds" do
  #       before do
  #         allow(stack).to receive(:wait_for_events).and_return("DELETE_COMPLETE")
  #       end
  #       it { expect(deleted).to be true }
  #     end
  #
  #     context "deleting the stack fails" do
  #       before do
  #         allow(stack).to receive(:wait_for_events).and_return("DELETE_FAILED")
  #       end
  #       it { expect{ deleted }.to raise_error(Stackup::StackUpdateError) }
  #     end
  #   end
  # end
  #
  #
  # context "validate" do
  #   it "should be valid if cf validate say so" do
  #     allow(cf_client).to receive(:validate_template).and_return({})
  #     expect(stack.valid?(template)).to be true
  #   end
  #
  #   it "should be invalid if cf validate say so" do
  #     allow(cf_client).to receive(:validate_template).and_return(:code => "404")
  #     expect(stack.valid?(template)).to be false
  #   end
  #
  # end

end
