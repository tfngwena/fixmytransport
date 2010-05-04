# == Schema Information
# Schema version: 20100420165342
#
# Table name: problems
#
#  id                :integer         not null, primary key
#  subject           :text
#  description       :text
#  created_at        :datetime
#  updated_at        :datetime
#  reporter_id       :integer
#  stop_area_id      :integer
#  location_id       :integer
#  location_type     :string(255)
#  transport_mode_id :integer
#

class Problem < ActiveRecord::Base
  validates_presence_of :transport_mode_id, :location, :location_type
  has_one :reporter, :class_name => 'User'
  accepts_nested_attributes_for :reporter
  belongs_to :location, :polymorphic => true
  belongs_to :transport_mode
  attr_accessor :location_attributes, :locations
  before_validation_on_create :location_from_attributes
  
  
  def location_from_attributes
    self.locations = []
    return unless location_attributes
    location_attributes[:transport_mode_id] = transport_mode_id
    if location_type == 'Stop' or location_type == 'StopArea'
      stops = Stop.find_from_attributes(location_attributes)
      if stops.size == 1  
        self.location = stops.first
        return
      end
      if stops.size > 1
        if stop_area = Stop.common_root_area(stops)
          self.location = stop_area
          return 
        end
      end
      self.locations = stops
      return
    else
      routes = Route.find_from_attributes(location_attributes)
      if routes.size == 1
        self.location = routes.first
        return
      end
      self.locations = routes
    end
  end
  
 
end
