require 'rspec'
require 'spec_helper'

describe 'NLSL variable reference' do
  include NLSL::SpecHelper

  it 'should parse array access' do
    r = parse("foo[10]", 'varref')
    r.should_not be_nil
    r.array.should eq 10
  end

  it 'should parse vector components' do
    %w( x y z w xy xyz ).each do |c|
      r = parse("foo.#{c}", 'varref')
      r.should_not be_nil
      r.component.should eq c
    end
  end

end