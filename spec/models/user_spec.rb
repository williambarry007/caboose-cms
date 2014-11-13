
describe Caboose::User do
  it "has a valid factory" do
    expect(FactoryGirl.create(:caboose_user)).to be_valid
  end  
  it "is invalid without an email" do
    expect(FactoryGirl.build(:caboose_user, :email => nil)).to_not be_valid
  end    
end
