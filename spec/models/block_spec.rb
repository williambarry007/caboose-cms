
describe Caboose::Block do
  it "has a valid factory" do
    expect(FactoryGirl.create(:caboose_block)).to be_valid
  end
  
  def reload_blocks
    @b0.reload
    @b1.reload
    @b2.reload
    @b3.reload
    @b4.reload
  end
  
  def print_blocks
    puts "------------------------------"    
    puts "#{@b0.id} #{@b0.sort_order}"
    puts "#{@b1.id} #{@b1.sort_order}"
    puts "#{@b2.id} #{@b2.sort_order}"
    puts "#{@b3.id} #{@b3.sort_order}"
    puts "#{@b4.id} #{@b4.sort_order}"
    puts "------------------------------"
  end
      
  describe "sorts correctly" do
    before(:all) do
      @b0 = FactoryGirl.create(:caboose_block, :parent_id => 1, :sort_order => 0)
      @b1 = FactoryGirl.create(:caboose_block, :parent_id => 1, :sort_order => 1)
      @b2 = FactoryGirl.create(:caboose_block, :parent_id => 1, :sort_order => 2)
      @b3 = FactoryGirl.create(:caboose_block, :parent_id => 1, :sort_order => 3)
      @b4 = FactoryGirl.create(:caboose_block, :parent_id => 1, :sort_order => 4)
    end
    before(:each) do
      @b0.update_attribute(:sort_order, 0)
      @b1.update_attribute(:sort_order, 1)
      @b2.update_attribute(:sort_order, 2)
      @b3.update_attribute(:sort_order, 3)
      @b4.update_attribute(:sort_order, 4)
      reload_blocks      
    end
    
    it "moves up when not at the top" do        
      @b2.move_up
      reload_blocks          
      expect(@b0.sort_order).to eql(0)
      expect(@b1.sort_order).to eql(2)
      expect(@b2.sort_order).to eql(1)
      expect(@b3.sort_order).to eql(3)
      expect(@b4.sort_order).to eql(4)
    end
    
    it "doesn't move up when already at the top" do      
      @b0.move_up
      reload_blocks      
      expect(@b0.sort_order).to eql(0)
      expect(@b1.sort_order).to eql(1)
      expect(@b2.sort_order).to eql(2)
      expect(@b3.sort_order).to eql(3)
      expect(@b4.sort_order).to eql(4)
    end
        
    it "moves down when not at the bottom" do
      @b2.move_down
      reload_blocks          
      expect(@b0.sort_order).to eql(0)
      expect(@b1.sort_order).to eql(1)
      expect(@b2.sort_order).to eql(3)
      expect(@b3.sort_order).to eql(2)
      expect(@b4.sort_order).to eql(4)
    end
    
    it "doesn't move down when already at the bottom" do
      @b4.move_down
      reload_blocks          
      expect(@b0.sort_order).to eql(0)
      expect(@b1.sort_order).to eql(1)
      expect(@b2.sort_order).to eql(2)
      expect(@b3.sort_order).to eql(3)
      expect(@b4.sort_order).to eql(4)
    end
    
    it "resets the sort order when sort order is not continuous" do
      @b0.update_attribute(:sort_order, 0)
      @b1.update_attribute(:sort_order, 1)
      @b2.update_attribute(:sort_order, 17)
      @b3.update_attribute(:sort_order, 18)
      @b4.update_attribute(:sort_order, 19)
      reload_blocks      
      @b2.move_up
      reload_blocks          
      expect(@b0.sort_order).to eql(0)
      expect(@b1.sort_order).to eql(2)
      expect(@b2.sort_order).to eql(1)
      expect(@b3.sort_order).to eql(3)
      expect(@b4.sort_order).to eql(4)
      
      @b0.update_attribute(:sort_order, 0)
      @b1.update_attribute(:sort_order, 1)
      @b2.update_attribute(:sort_order, 17)
      @b3.update_attribute(:sort_order, 18)
      @b4.update_attribute(:sort_order, 19)
      reload_blocks      
      @b2.move_down
      reload_blocks          
      expect(@b0.sort_order).to eql(0)
      expect(@b1.sort_order).to eql(1)
      expect(@b2.sort_order).to eql(3)
      expect(@b3.sort_order).to eql(2)
      expect(@b4.sort_order).to eql(4)
    end
    
  end

end
