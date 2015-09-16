require "spec_helper"

describe Stackup::Stack do
  let(:stack) { Stackup::Stack.new("stack_name") }
  let(:template) { double(String) }
  let(:cf_stack) { double(Aws::CloudFormation::Stack) }
  let(:cf) { double(Aws::CloudFormation::Client) }

  before do
    allow(Aws::CloudFormation::Client).to receive(:new).and_return(cf)
    allow(Aws::CloudFormation::Stack).to receive(:new).and_return(cf_stack)
  end

  context "update" do
    it 'should allow stack update' do
      allow(cf_stack).to receive(:stack_status).and_return('1')
      response = Seahorse::Client::Http::Response.new
      allow(response).to receive(:[]).with(:stack_id).and_return("1")
      allow(cf).to receive(:update_stack).and_return(response)
      allow(cf_stack).to receive(:wait_until).and_return(true)
      expect(stack.update(template)).to be true
    end

    it 'should not update if the stack is not deployed' do
      allow(cf_stack).to receive(:stack_status).and_raise(Aws::CloudFormation::Errors::ValidationError.new("1", "2"))
      expect(stack.update(template)).to be false
    end
  end

  context "delete" do
    it "should delete the stack if it exists?" do
      response = double(Struct)
      allow(cf).to receive(:delete_stack).and_return(response)
      allow(cf_stack).to receive(:wait_until).and_return(response)
      expect(stack.delete).to be response
    end
  end

  context "create" do
    let(:response) { Seahorse::Client::Http::Response.new }
    it "should create stack if all is well" do
      allow(response).to receive(:[]).with(:stack_id).and_return("1")
      allow(cf).to receive(:create_stack).and_return(response)
      allow(cf_stack).to receive(:wait_until).and_return(true)
      expect(stack.create(template)).to be true
    end

    it "should return nil if stack was not created" do
      allow(response).to receive(:[]).with(:stack_id).and_return(nil)
      allow(cf).to receive(:create_stack).and_return(response)
      allow(cf_stack).to receive(:wait_until).and_return(false)
      expect(stack.create(template)).to be false
    end
  end

  context "validate" do
    it "should be valid if cf validate say so" do
      allow(cf).to receive(:validate_template).and_return({})
      expect(stack.valid?(template)).to be true
    end

    it "should be invalid if cf validate say so" do
      allow(cf).to receive(:validate_template).and_return(:code => "404")
      expect(stack.valid?(template)).to be false
    end

  end

  context "deployed" do
    it "should be true if it is already deployed" do
      allow(cf_stack).to receive(:stack_status).and_return("CREATE_COMPLETE")
      expect(stack.deployed?).to be true
    end

    it "should be false if it is not deployed" do
      allow(cf_stack).to receive(:stack_status).and_raise(Aws::CloudFormation::Errors::ValidationError.new("1", "2"))
      expect(stack.deployed?).to be false
    end
  end
end
