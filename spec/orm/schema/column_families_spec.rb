require 'spec_helper'

describe MassiveRecord::ORM::Schema::ColumnFamilies do
  before do
    @column_families = MassiveRecord::ORM::Schema::ColumnFamilies.new
  end

  it "should be a kind of set" do
    @column_families.should be_a_kind_of Set
  end

  it "should be possible to add column families" do
    family = MassiveRecord::ORM::Schema::ColumnFamily.new(:name => :info)
    @column_families << family
    @column_families.first.should == family
  end

  describe "add column families to the set" do
    it "should not be possible to add two column families with the same name" do
      family_1 = MassiveRecord::ORM::Schema::ColumnFamily.new(:name => :info)
      family_2 = MassiveRecord::ORM::Schema::ColumnFamily.new(:name => :info)
      @column_families << family_1
      @column_families.add?(family_2).should be_nil
    end

    it "should add self to column_family when familiy is added" do
      family = MassiveRecord::ORM::Schema::ColumnFamily.new(:name => :info)
      @column_families << family
      family.column_families.should == @column_families
    end

    it "should add self to column_family when familiy is added with a question" do
      family = MassiveRecord::ORM::Schema::ColumnFamily.new(:name => :info)
      @column_families.add? family
      family.column_families.should == @column_families
    end

    it "should raise error if invalid column familiy is added" do
      invalid_family = MassiveRecord::ORM::Schema::ColumnFamily.new
      lambda { @column_families << invalid_family }.should raise_error MassiveRecord::ORM::Schema::InvalidColumnFamily
    end
  end

  describe "#to_hash" do
    before do
      @column_families = MassiveRecord::ORM::Schema::ColumnFamilies.new
      @column_family_info = MassiveRecord::ORM::Schema::ColumnFamily.new :name => :info
      @column_family_misc = MassiveRecord::ORM::Schema::ColumnFamily.new :name => :misc

      @column_families << @column_family_info << @column_family_misc

      @name_field = MassiveRecord::ORM::Schema::Field.new(:name => :name)
      @phone_field = MassiveRecord::ORM::Schema::Field.new(:name => :phone)
      @column_family_info << @name_field << @phone_field

      @misc_field = MassiveRecord::ORM::Schema::Field.new(:name => :misc)
      @other_field = MassiveRecord::ORM::Schema::Field.new(:name => :other)
      @column_family_misc << @misc_field << @other_field
    end

    it "should return nil if no fields are added" do
      @column_families.clear
      @column_families.to_hash.should == {}
    end

    it "should contain added fields from info" do
      @column_families.to_hash.should include("name" => @name_field)
      @column_families.to_hash.should include("phone" => @phone_field)
    end

    it "should contain added fields from misc" do
      @column_families.to_hash.should include("misc" => @misc_field)
      @column_families.to_hash.should include("other" => @other_field)
    end
  end
end
