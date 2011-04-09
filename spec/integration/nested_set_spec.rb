require 'spec_helper'

# id | lft| rgt| title
#========================================
# 1  | 1  | 20 | - Electronics
# 2  | 2  | 9  |   - Televisions
# 3  | 3  | 4  |     - Tube
# 4  | 5  | 6  |     - LCD
# 5  | 7  | 8  |     - Plasma
# 6  | 10 | 19 |   - Portable Electronics
# 7  | 11 | 14 |     - MP3 Players
# 8  | 12 | 13 |       - Flash
# 9  | 15 | 16 |     - CD Players
# 10 | 17 | 18 |     - 2 Way Radios

# |  |  |      |  |     |  |        |  |  |  |  |           |  |  |            |  |              |  |  |
# 1  2  3      4  5     6  7        8  9  10 11 12  Flash  13 14  15          16  17            18 19 20
# |  |  | Tube |  | LCD |  | Plasma |  |  |  |  |___________|  |  | CD Players |  | 2 Way Radios |  |  |
# |  |  |______|  |_____|  |________|  |  |  |                 |  |____________|  |______________|  |  |
# |  |                                 |  |  |   MP3 Players   |                                    |  |
# |  |          Televisions            |  |  |_________________|       Portable Electronics         |  |
# |  |_________________________________|  |_________________________________________________________|  |
# |                                                                                                    |
# |                                       Electronics                                                  |
# |____________________________________________________________________________________________________|

describe DataMapper::Is::NestedSet do
  before :all do
    class ::User
      include DataMapper::Resource

      property :id,   Serial
      property :name, String

      has n, :categories
    end

    class ::Category
      include DataMapper::Resource

      property :id,   Serial
      property :name, String
      property :type, Discriminator

      belongs_to :user

      is :nested_set, :scope => [ :user_id ]

      def pos; [lft,rgt] end # convenience method only for speccing.
    end
  end

  supported_by :sqlite, :mysql, :postgres do
    before do
      DataMapper.repository do
        @user  = User.create(:name => 'paul')
        @other = User.create(:name => 'john')

        electronics          = @user.categories.create(                                 :name => 'Electronics')
        televisions          = @user.categories.create(:parent => electronics,          :name => 'Televisions')
        tube                 = @user.categories.create(:parent => televisions,          :name => 'Tube')
        lcd                  = @user.categories.create(:parent => televisions,          :name => 'LCD')
        plasma               = @user.categories.create(:parent => televisions,          :name => 'Plasma')
        portable_electronics = @user.categories.create(:parent => electronics,          :name => 'Portable Electronics')
        mp3_players          = @user.categories.create(:parent => portable_electronics, :name => 'MP3 Players')
        flash                = @user.categories.create(:parent => mp3_players,          :name => 'Flash')
        cd_players           = @user.categories.create(:parent => portable_electronics, :name => 'CD Players')
        two_way_radios       = @user.categories.create(:parent => portable_electronics, :name => '2 Way Radios')
      end
    end

    describe 'Class#rebuild_tree_from_set' do
      it 'should reset all parent_ids correctly' do
        DataMapper.repository do
          plasma = Category.first(:name => 'Plasma')
          plasma.parent_id.should == 2
          plasma.ancestor.id.should == 2
          plasma.pos.should == [7,8]
          plasma.parent_id = nil
          Category.rebuild_tree_from_set
          plasma.parent_id.should == 2
        end
      end
    end

    describe 'Class#root and #root' do
      it 'should return the toplevel node' do
        Category.root.name.should == 'Electronics'
      end
    end

    describe 'Class#leaves and #leaves' do
      it 'should return all nodes without descendants' do
        DataMapper.repository do
          Category.leaves.length.should == 6

          r = Category.root
          r.leaves.length.should == 6
          r.children[1].leaves.length.should == 3
        end
      end
    end

    describe '#ancestor, #ancestors and #self_and_ancestors' do
      it 'should return ancestors in an array' do
        DataMapper.repository do
          c8 = Category.first(:name => 'Flash')
          c8.ancestor.should == Category.first(:name => 'MP3 Players')
          c8.ancestor.should == c8.parent

          c8.ancestors.map{|a|a.name}.should == ['Electronics','Portable Electronics','MP3 Players']
          c8.self_and_ancestors.map{|a|a.name}.should == ['Electronics','Portable Electronics','MP3 Players','Flash']
        end
      end
    end

    describe '#children' do
      it 'should return children of node' do
        DataMapper.repository do
          r = Category.root
          r.children.length.should == 2

          t = r.children.first
          t.children.length.should == 3
          t.children.first.name.should == 'Tube'
          t.children[2].name.should == 'Plasma'
        end
      end
    end

    describe '#descendants and #self_and_descendants' do
      it 'should return all subnodes of node' do
        DataMapper.repository do
          r = Category.first(:name => 'Electronics')
          r.self_and_descendants.length.should == 10
          r.descendants.length.should == 9
          r.name.should == 'Electronics'
          t = r.children[1]
          t.name.should == 'Portable Electronics'
          t.descendants.length.should == 4
          t.descendants.map{|a|a.name}.should == ['MP3 Players','Flash','CD Players','2 Way Radios']
        end
      end
    end

    describe '#siblings and #self_and_siblings' do
      it 'should return all siblings of node' do
        DataMapper.repository do
          r = Category.root
          r.self_and_siblings.length.should == 1
          r.descendants.length.should == 9

          televisions = r.children[0]
          televisions.siblings.length.should == 1
          televisions.siblings.map{|a|a.name}.should == ['Portable Electronics']
        end
      end
    end

    describe '#move' do

      # Outset:
      # id | lft| rgt| title
      #========================================
      # 1  | 1  | 20 | - Electronics
      # 2  | 2  | 9  |   - Televisions
      # 3  | 3  | 4  |     - Tube
      # 4  | 5  | 6  |     - LCD
      # 5  | 7  | 8  |     - Plasma
      # 6  | 10 | 19 |   - Portable Electronics
      # 7  | 11 | 14 |     - MP3 Players
      # 8  | 12 | 13 |       - Flash
      # 9  | 15 | 16 |     - CD Players
      # 10 | 17 | 18 |     - 2 Way Radios

      it 'should move items correctly with :higher / :highest / :lower / :lowest' do
        DataMapper.repository do

          Category.first(:name => 'LCD').pos.should == [5,6]

          Category.first(:name => 'LCD').move(:above => Category.first(:name => 'Tube'))
          Category.first(:name => 'LCD').pos.should == [3,4]

          Category.first(:name => 'LCD').move(:higher).should == false
          Category.first(:name => 'LCD').pos.should == [3,4]
          Category.first(:name => 'Tube').pos.should == [5,6]
          Category.first(:name => 'LCD').right_sibling.should == Category.first(:name => 'Tube')

          Category.first(:name => 'LCD').move(:lower)
          Category.first(:name => 'LCD').pos.should == [5,6]
          Category.first(:name => 'LCD').left_sibling.should == Category.first(:name => 'Tube')
          Category.first(:name => 'LCD').right_sibling.should == Category.first(:name => 'Plasma')

          Category.first(:name => 'LCD').move(:highest)
          Category.first(:name => 'LCD').pos.should == [3,4]
          Category.first(:name => 'LCD').move(:higher).should == false

          Category.first(:name => 'LCD').move(:lowest)
          Category.first(:name => 'LCD').pos.should == [7,8]
          Category.first(:name => 'LCD').left_sibling.should == Category.first(:name => 'Plasma')

          Category.first(:name => 'LCD').move(:higher) # should reset the tree to how it was

        end
      end

      it 'should move items correctly with :indent / :outdent' do
        DataMapper.repository do

          mp3_players = Category.first(:name => 'MP3 Players')

          portable_electronics = Category.first(:name => 'Portable Electronics')
          televisions = Category.first(:name => 'Televisions')

          mp3_players.pos.should == [11,14]
          #mp3_players.descendants.length.should == 1

          # The category is at the top of its parent, should not be able to indent.
          mp3_players.move(:indent).should == false

          mp3_players.move(:outdent)

          mp3_players.pos.should == [16,19]
          mp3_players.left_sibling.should == portable_electronics

          mp3_players.move(:higher) # Move up above Portable Electronics

          mp3_players.pos.should == [10,13]
          mp3_players.left_sibling.should == televisions
        end
      end
    end

    describe 'moving objects with #move_* #and place_node_at' do
      it 'should set left/right when choosing a parent' do
        DataMapper.repository do
          Category.auto_migrate!

          c1 = @user.categories.create(:name => 'New Electronics')

          c2 = @user.categories.create(:name => 'OLED TVs')

          c1.pos.should == [1,4]
          c1.root.should == c1
          c2.pos.should == [2,3]

          c3 = @user.categories.create(:name => 'Portable Electronics')
          c3.parent=c1
          c3.save

          c1.pos.should == [1,6]
          c2.pos.should == [2,3]
          c3.pos.should == [4,5]

          c3.parent=c2
          c3.save

          c1.pos.should == [1,6]
          c2.pos.should == [2,5]
          c3.pos.should == [3,4]

          c3.parent=c1
          c3.move(:into => c2)

          c1.pos.should == [1,6]
          c2.pos.should == [2,5]
          c3.pos.should == [3,4]

          c4 = @user.categories.create(:name => 'Tube',      :parent => c2)
          c5 = @user.categories.create(:name => 'Flatpanel', :parent => c2)

          c1.pos.should == [1,10]
          c2.pos.should == [2,9]
          c3.pos.should == [3,4]
          c4.pos.should == [5,6]
          c5.pos.should == [7,8]

          c5.move(:above => c3)
          c3.pos.should == [5,6]
          c4.pos.should == [7,8]
          c5.pos.should == [3,4]

        end
      end
    end

    describe 'scoping' do
      it 'should detach from list when changing scope' do
        DataMapper.repository do
          plasma = Category.first(:name => 'Plasma')
          plasma.pos.should == [7,8]
          plasma.update(:user => @other)
          plasma.pos.should == [1,2]
        end
      end
    end

    describe 'integrity' do
      it 'should detach object from list when deleted' do
        DataMapper.repository do
          lcd = Category.first(:name => 'LCD')
          lcd.pos.should == [5,6]
          Category.first(:name => 'Tube').destroy
          lcd.pos.should == [3,4]
        end
      end
    end

  end

end
