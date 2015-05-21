require 'rails_helper'

RSpec.describe Video, type: :model do
  it '.accept_upload?' do
    Video.accept_upload?('1.avi').should == true
    Video.accept_upload?('1.bin').should == false
  end
end
