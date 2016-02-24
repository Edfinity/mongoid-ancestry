require 'spec_helper'
require 'mongoid-ancestry/exceptions'

describe MongoidAncestry do

  subject { MongoidAncestry }

  it "has ancestry fields" do
    subject.with_model do |model|
      expect(model.fields['ancestry'].options[:type]).to eq(String)
    end
  end

  it "has non default ancestry field" do
    subject.with_model :ancestry_field => :alternative_ancestry do |model|
      expect(model.ancestry_field).to eq(:alternative_ancestry)
    end
  end

  it "sets ancestry field" do
    subject.with_model do |model|
      model.ancestry_field = :ancestors
      expect(model.ancestry_field).to eq(:ancestors)
      model.ancestry_field = :ancestry
      expect(model.ancestry_field).to eq(:ancestry)
    end
  end

  it "has default orphan strategy" do
    subject.with_model do |model|
      expect(model.orphan_strategy).to eq(:destroy)
    end
  end

  it "has default touchable value" do
    subject.with_model do |model|
      expect(model.ancestry_touchable).to be false
    end
  end

  it "sets touchable value" do
    subject.with_model touchable: true do |model|
      expect(model.ancestry_touchable).to be true
    end
  end

  it "has non default orphan strategy" do
    subject.with_model :orphan_strategy => :rootify do |model|
      expect(model.orphan_strategy).to eq(:rootify)
    end
  end

  it "sets orphan strategy" do
    subject.with_model do |model|
      model.orphan_strategy = :rootify
      expect(model.orphan_strategy).to eq(:rootify)
      model.orphan_strategy = :destroy
      expect(model.orphan_strategy).to eq(:destroy)
    end
  end

  it "does not set invalid orphan strategy" do
    subject.with_model do |model|
      expect {
        model.orphan_strategy = :non_existent_orphan_strategy
      }.to raise_error Mongoid::Ancestry::Error
    end
  end

  it "setups test nodes" do
    subject.with_model :depth => 3, :width => 3 do |model, roots|
      expect(roots.class).to eq(Array)
      expect(roots.length).to eq(3)
      roots.each do |node, children|
        expect(node.class).to eq(model)
        expect(children.class).to eq(Array)
        expect(children.length).to eq(3)
        children.each do |node, children|
          expect(node.class).to eq(model)
          expect(children.class).to eq(Array)
          expect(children.length).to eq(3)
          children.each do |node, children|
            expect(node.class).to eq(model)
            expect(children.class).to eq(Array)
            expect(children.length).to eq(0)
          end
        end
      end
    end
  end

  it "has STI support" do
    subject.with_model :extra_columns => {:type => 'String'} do |model|
      subclass1 = Object.const_set 'Subclass1', Class.new(model)
      (class << subclass1; self; end).send(:define_method, :model_name) do
      Struct.new(:human, :underscore).new 'Subclass1', 'subclass1'
      end
      subclass2 = Object.const_set 'Subclass2', Class.new(model)
      (class << subclass2; self; end).send(:define_method, :model_name) do
      Struct.new(:human, :underscore).new 'Subclass1', 'subclass1'
      end

      node1 = subclass1.create
      node2 = subclass2.create :parent => node1
      node3 = subclass1.create :parent => node2
      node4 = subclass2.create :parent => node3
      node5 = subclass1.create :parent => node4

      model.all.each do |node|
        expect([subclass1, subclass2].include?(node.class)).to be true
      end

      expect(node1.descendants.map(&:id)).to eq([node2.id, node3.id, node4.id, node5.id])
      expect(node1.subtree.map(&:id)).to eq([node1.id, node2.id, node3.id, node4.id, node5.id])
      expect(node5.ancestors.map(&:id)).to eq([node1.id, node2.id, node3.id, node4.id])
      expect(node5.path.map(&:id)).to eq([node1.id, node2.id, node3.id, node4.id, node5.id])
    end
  end

end
