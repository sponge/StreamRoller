require 'sequel'

class Sequel::Dataset
  def to_json
    naked.all.to_json
  end
end

class Sequel::Model
  def self.to_json
    dataset.to_json
  end
end
