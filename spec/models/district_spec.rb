# == Schema Information
# Schema version: 20100707152350
#
# Table name: districts
#
#  id                    :integer         not null, primary key
#  code                  :string(255)
#  name                  :text
#  admin_area_id         :integer
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :string(255)
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#

require 'spec_helper'

describe District do
  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :name => "value for name",
      :admin_area_id => 1,
      :creation_datetime => Time.now,
      :modification_datetime => Time.now,
      :revision_number => "value for revision_number",
      :modification => "value for modification"
    }
  end

  it "should create a new instance given valid attributes" do
    District.create!(@valid_attributes)
  end
  
  describe 'find all by name' do 
  
    it 'should find areas with their admin area, supplied as a comma-delimited string' do 
      expected_conditions = ["LOWER(districts.name) = ? AND LOWER(admin_areas.name) = ?", 
                             "bromley", "greater london"]
      District.should_receive(:find).with(:all, :conditions => expected_conditions, 
                                                :include => [:localities, :admin_area]).and_return([])
      District.find_all_by_full_name('Bromley, Greater London')
    end
    
    it 'should not return districts without localities' do 
      district_no_localities = mock_model(District, :localities => [])
      district_with_localities = mock_model(District, :localities => [mock_model(Locality)])
      District.stub!(:find).and_return([district_with_localities, district_no_localities])
      District.find_all_by_full_name('London')
    end
    
  end
  
end
