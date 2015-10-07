require "spec_helper"

describe Stackup::Stack do

  let(:stack) { described_class.new("stack_name") }

  let(:cf_stack) { instance_double("Aws::CloudFormation::Stack",
                                  :stack_status => stack_status) }
  let(:cf_client) { instance_double("Aws::CloudFormation::Client") }

  let(:template) { double(String) }
  let(:parameters) { [] }
  let(:stack_status) { nil }

  let(:response) { Seahorse::Client::Http::Response.new }

  before do
    allow(Aws::CloudFormation::Client).to receive(:new).and_return(cf_client)
    allow(Aws::CloudFormation::Stack).to receive(:new).and_return(cf_stack)
    allow(cf_stack).to receive(:events).and_return([])
  end

  def stack_does_not_exist
    Aws::CloudFormation::Errors::ValidationError.new("test", "stack does not exist")
  end

  describe "#update" do
    subject(:updated) { stack.update(template, parameters) }

    context "when there is an existing stack" do

      before do
        allow(cf_client).to receive(:update_stack).and_return(response)
        allow(stack).to receive(:wait_until_stable).and_return("UPDATE_COMPLETE")
      end

      context "in a ROLLBACK_COMPLETE state" do
        before do
          allow(cf_stack).to receive(:stack_status).and_return("ROLLBACK_COMPLETE")
        end

        context "when deleting existing stack succeeds" do

          it "deletes the existing stack" do
            allow(response).to receive(:[]).with(:stack_id).and_return("1")
            expect(stack).to receive(:delete).and_return(true)
            stack.update(template, parameters)
          end

          context "when stack gets successfully updated" do
            before do
              allow(response).to receive(:[]).with(:stack_id).and_return("1")
              allow(stack).to receive(:delete).and_return(true)
            end
            it { expect(updated).to be :updated }
          end

          context "when stack update fails" do
            before do
              allow(response).to receive(:[]).with(:stack_id).and_return("1")
              allow(stack).to receive(:delete).and_return(false)
            end
            it { expect(updated).to be false }
          end
        end

        context "when deleting existing stack fails" do
          before do
            allow(stack).to receive(:delete).and_return(false)
          end
          it { expect(updated).to be false }
        end
      end

      context "in a CREATE_FAILED state" do
        before do
          allow(cf_stack).to receive(:stack_status).and_return("CREATE_FAILED")
        end

        it "does not try to delete the existing stack" do
          allow(response).to receive(:[]).with(:stack_id).and_return("1")
          expect(stack).not_to receive(:delete)
          stack.update(template, parameters)
        end

        it "does not try to delete the existing stack" do
          allow(response).to receive(:[]).with(:stack_id).and_return("1")
          expect(cf_client).not_to receive(:delete_stack)
          expect(updated).to be false
        end
      end
    end
  end

end
