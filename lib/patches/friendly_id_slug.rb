# Patch the slug model provided by the friendly_id gem so that it has a default scope
# which hides slugs from other data generations and creates new slugs as belonging to this
# data generation

class Slug < ::ActiveRecord::Base
  default_scope :conditions => [ "#{quoted_table_name}.generation_low <= ? 
                                  AND #{quoted_table_name}.generation_high >= ?", 
                                  CURRENT_GENERATION, CURRENT_GENERATION ]
  before_create :set_generations
  
  def set_generations
    self.generation_low = CURRENT_GENERATION if self.generation_low.nil?
    self.generation_high = CURRENT_GENERATION if self.generation_high.nil?
  end
  
end