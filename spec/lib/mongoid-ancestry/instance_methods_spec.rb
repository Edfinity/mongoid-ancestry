require 'spec_helper'

describe MongoidAncestry do

  subject { MongoidAncestry }

  it "has tree navigation" do
    subject.with_model :depth => 3, :width => 3 do |model, roots|
      roots.each do |lvl0_node, lvl0_children|
        # Ancestors assertions
        expect(lvl0_node.ancestor_ids).to eq([])
        expect(lvl0_node.ancestors.to_a).to eq([])
        expect(lvl0_node.path_ids).to eq([lvl0_node.id])
        expect(lvl0_node.path.to_a).to eq([lvl0_node])
        expect(lvl0_node.depth).to eq(0)
        # Parent assertions
        expect(lvl0_node.parent_id).to be nil
        expect(lvl0_node.parent).to be nil
        # Root assertions
        expect(lvl0_node.root_id).to eq(lvl0_node.id)
        expect(lvl0_node.root).to eq(lvl0_node)
        expect(lvl0_node.is_root?).to be true
        # Children assertions
        expect(lvl0_node.child_ids).to eq(lvl0_children.map(&:first).map(&:id))
        expect(lvl0_node.children.to_a).to eq(lvl0_children.map(&:first))
        expect(lvl0_node.has_children?).to be true
        expect(lvl0_node.is_childless?).to be false
        # Siblings assertions
        expect(lvl0_node.sibling_ids).to eq(roots.map(&:first).map(&:id))
        expect(lvl0_node.siblings.to_a).to eq(roots.map(&:first))
        expect(lvl0_node.has_siblings?).to be true
        expect(lvl0_node.is_only_child?).to be false
        # Descendants assertions
        descendants = model.all.find_all do |node|
          node.ancestor_ids.include?(lvl0_node.id)
        end
        expect(lvl0_node.descendant_ids).to eq(descendants.map(&:id))
        expect(lvl0_node.descendants.to_a).to eq(descendants)
        expect(lvl0_node.subtree.to_a).to eq([lvl0_node] + descendants)

        lvl0_children.each do |lvl1_node, lvl1_children|
          # Ancestors assertions
          expect(lvl1_node.ancestor_ids).to eq([lvl0_node.id])
          expect(lvl1_node.ancestors.to_a).to eq([lvl0_node])
          expect(lvl1_node.path_ids).to eq([lvl0_node.id, lvl1_node.id])
          expect(lvl1_node.path.to_a).to eq([lvl0_node, lvl1_node])
          expect(lvl1_node.depth).to eq(1)
          # Parent assertions
          expect(lvl1_node.parent_id).to eq(lvl0_node.id)
          expect(lvl1_node.parent).to eq(lvl0_node)
          # Root assertions
          expect(lvl1_node.root_id).to eq(lvl0_node.id)
          expect(lvl1_node.root).to eq(lvl0_node)
          expect(lvl1_node.is_root?).to be false
          # Children assertions
          expect(lvl1_node.child_ids).to eq(lvl1_children.map(&:first).map(&:id))
          expect(lvl1_node.children.to_a).to eq(lvl1_children.map(&:first))
          expect(lvl1_node.has_children?).to be true
          expect(lvl1_node.is_childless?).to be false
          # Siblings assertions
          expect(lvl1_node.sibling_ids).to eq(lvl0_children.map(&:first).map(&:id))
          expect(lvl1_node.siblings.to_a).to eq(lvl0_children.map(&:first))
          expect(lvl1_node.has_siblings?).to be true
          expect(lvl1_node.is_only_child?).to be false
          # Descendants assertions
          descendants = model.all.find_all do |node|
            node.ancestor_ids.include? lvl1_node.id
          end

          expect(lvl1_node.descendant_ids).to eq(descendants.map(&:id))
          expect(lvl1_node.descendants.to_a).to eq(descendants)
          expect(lvl1_node.subtree.to_a).to eq([lvl1_node] + descendants)

          lvl1_children.each do |lvl2_node, lvl2_children|
            # Ancestors assertions
            expect(lvl2_node.ancestor_ids).to eq([lvl0_node.id, lvl1_node.id])
            expect(lvl2_node.ancestors.to_a).to eq([lvl0_node, lvl1_node])
            expect(lvl2_node.path_ids).to eq([lvl0_node.id, lvl1_node.id, lvl2_node.id])
            expect(lvl2_node.path.to_a).to eq([lvl0_node, lvl1_node, lvl2_node])
            expect(lvl2_node.depth).to eq(2)
            # Parent assertions
            expect(lvl2_node.parent_id).to eq(lvl1_node.id)
            expect(lvl2_node.parent).to eq(lvl1_node)
            # Root assertions
            expect(lvl2_node.root_id).to eq(lvl0_node.id)
            expect(lvl2_node.root).to eq(lvl0_node)
            expect(lvl2_node.is_root?).to be false
            # Children assertions
            expect(lvl2_node.child_ids).to eq([])
            expect(lvl2_node.children.to_a).to eq([])
            expect(lvl2_node.has_children?).to be false
            expect(lvl2_node.is_childless?).to be true
            # Siblings assertions
            expect(lvl2_node.sibling_ids).to eq(lvl1_children.map(&:first).map(&:id))
            expect(lvl2_node.siblings.to_a).to eq(lvl1_children.map(&:first))
            expect(lvl2_node.has_siblings?).to be true
            expect(lvl2_node.is_only_child?).to be false
            # Descendants assertions
            descendants = model.all.find_all do |node|
              node.ancestor_ids.include? lvl2_node.id
            end
            expect(lvl2_node.descendant_ids).to eq(descendants.map(&:id))
            expect(lvl2_node.descendants.to_a).to eq(descendants)
            expect(lvl2_node.subtree.to_a).to eq([lvl2_node] + descendants)
          end
        end
      end
    end
  end

  it "validates ancestry field" do
    subject.with_model do |model|
      node = model.create
      ['3', '10/2', '1/4/30', nil].each do |value|
        node.send :write_attribute, model.ancestry_field, value
        expect(node).to be_valid
        expect(node.errors[model.ancestry_field].blank?).to be true
      end
      ['1/3/', '/2/3', 'A/b', '-34', '/54'].each do |value|
        node.send :write_attribute, model.ancestry_field, value
        expect(node).not_to be_valid
        expect(node.errors[model.ancestry_field].blank?).to be false
      end
    end
  end

  it "moves descendants with node" do
    subject.with_model :depth => 3, :width => 3 do |model, roots|
      root1, root2, root3 = roots.map(&:first)

      descendants = root1.descendants.asc(:_id).map(&:to_param)
      expect {
        root1.parent = root2
        root1.save!
        expect(root1.descendants.asc(:_id).map(&:to_param)).to eq(descendants)
      }.to change(root2.descendants, 'count').by(root1.subtree.count)

      descendants = root2.descendants.asc(:_id).map(&:to_param)
      expect {
        root2.parent = root3
        root2.save!
        expect(root2.descendants.asc(:_id).map(&:to_param)).to eq(descendants)
      }.to change(root3.descendants, 'count').by(root2.subtree.count)

      descendants = root1.descendants.asc(:_id).map(&:to_param)
      expect {
        expect {
          root1.parent = nil
          root1.save!
          expect(root1.descendants.asc(:_id).map(&:to_param)).to eq(descendants)
        }.to change(root3.descendants, 'count').by(-root1.subtree.count)
      }.to change(root2.descendants, 'count').by(-root1.subtree.count)
    end
  end

  it "validates ancestry exclude self" do
    subject.with_model do |model|
      parent = model.create!
      child = parent.children.create
      expect { parent.update_attributes! :parent => child }.to raise_error(Mongoid::Errors::Validations)
    end
  end

  it "has depth caching" do
    subject.with_model :depth => 3, :width => 3, :cache_depth => true, :depth_cache_field => :depth_cache do |model, roots|
      roots.each do |lvl0_node, lvl0_children|
        expect(lvl0_node.depth_cache).to eq(0)
        lvl0_children.each do |lvl1_node, lvl1_children|
          expect(lvl1_node.depth_cache).to eq(1)
          lvl1_children.each do |lvl2_node, lvl2_children|
            expect(lvl2_node.depth_cache).to eq(2)
          end
        end
      end
    end
  end

  it "has descendants with depth constraints" do
    subject.with_model :depth => 4, :width => 4, :cache_depth => true do |model, roots|
      expect(model.roots.first.descendants(:before_depth => 2).count).to eq(4)
      expect(model.roots.first.descendants(:to_depth => 2).count).to eq(20)
      expect(model.roots.first.descendants(:at_depth => 2).count).to eq(16)
      expect(model.roots.first.descendants(:from_depth => 2).count).to eq(80)
      expect(model.roots.first.descendants(:after_depth => 2).count).to eq(64)
    end
  end

  it "has subtree with depth constraints" do
    subject.with_model :depth => 4, :width => 4, :cache_depth => true do |model, roots|
      expect(model.roots.first.subtree(:before_depth => 2).count).to eq(5)
      expect(model.roots.first.subtree(:to_depth => 2).count).to eq(21)
      expect(model.roots.first.subtree(:at_depth => 2).count).to eq(16)
      expect(model.roots.first.subtree(:from_depth => 2).count).to eq(80)
      expect(model.roots.first.subtree(:after_depth => 2).count).to eq(64)
    end
  end

  it "has ancestors with depth constraints" do
    subject.with_model :cache_depth => true do |model|
      node1 = model.create!
      node2 = node1.children.create
      node3 = node2.children.create
      node4 = node3.children.create
      node5 = node4.children.create
      leaf  = node5.children.create

      expect(leaf.ancestors(:before_depth => -2).to_a).to eq([node1, node2, node3])
      expect(leaf.ancestors(:to_depth => -2).to_a).to eq([node1, node2, node3, node4])
      expect(leaf.ancestors(:at_depth => -2).to_a).to eq([node4])
      expect(leaf.ancestors(:from_depth => -2).to_a).to eq([node4, node5])
      expect(leaf.ancestors(:after_depth => -2).to_a).to eq([node5])
    end
  end

  it "has path with depth constraints" do
    subject.with_model :cache_depth => true do |model|
      node1 = model.create!
      node2 = node1.children.create
      node3 = node2.children.create
      node4 = node3.children.create
      node5 = node4.children.create
      leaf  = node5.children.create

      expect(leaf.path(:before_depth => -2).to_a).to eq([node1, node2, node3])
      expect(leaf.path(:to_depth => -2).to_a).to eq([node1, node2, node3, node4])
      expect(leaf.path(:at_depth => -2).to_a).to eq([node4])
      expect(leaf.path(:from_depth => -2).to_a).to eq([node4, node5, leaf])
      expect(leaf.path(:after_depth => -2).to_a).to eq([node5, leaf])
    end
  end

  it "raises exception on unknown depth field" do
    subject.with_model :cache_depth => true do |model|
      expect {
        model.create!.subtree(:this_is_not_a_valid_depth_option => 42)
      }.to raise_error(Mongoid::Ancestry::Error)
    end
  end

  it "does not call touch on parent" do
    subject.with_model do |model|
      root = model.create!
      expect{ root.children.create!  }.to_not change{ root.reload.updated_at }
    end
  end

  it "calls touch on parent" do
    subject.with_model touchable: true do |model|
      root = model.create!
      expect{ root.children.create!  }.to change{ root.reload.updated_at }
    end
  end

end
