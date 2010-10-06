require 'test/unit'
require '../lib/drop.rb'
require 'fileutils'

class BasicNilTest < Test::Unit::TestCase
  def setup
    @drop = Drop.new(nil)
  end
  
  def test_next_tag
    11.times do |n|
      @drop.write("n=#{n}" => 'x' * n, n => n, "n" => n, :symbol => n)
    end
    assert_equal(@drop.next_tag(), 'n')
    assert_equal(@drop.next_tag(nil), 'n')
    assert_equal(@drop.next_tag('n='), 'n=0')
    assert_equal(@drop.next_tag('n=0'), 'n=1')
    assert_equal(@drop.next_tag('n=0', 3), ['n=1', 'n=10', 'n=2'])
    assert_equal(@drop.tags, ["n",
                              "n=0", "n=1", "n=10", "n=2", "n=3",
                              "n=4", "n=5", "n=6", "n=7", "n=8", "n=9"])
    # tags with prefix
    assert_equal(@drop.tags("n="), %w(0 1 10 2 3 4 5 6 7 8 9))
  end
  
  def test_symbol_is_not_tag
    @drop.write(:symbol => :symbol, 'string' => :string)
    assert_equal(@drop.tags, ['string'])
    oid, value = @drop.older(@drop.time_to_key(Time.now))
    assert_equal(value, {:symbol => :symbol, 'string' => :string})
  end

  def test_number_is_not_tag
    @drop.write(5 => :five, 'string' => :string)
    assert_equal(@drop.tags, ['string'])
  end
  
  def test_older_now_is_newest
    @drop.write('age' => 1)
    @drop.write('age' => 2)
    @drop.write('age' => 3)
    oid, value = @drop.older(nil)
    assert_equal(value, 'age' => 3)
    oid, value = @drop.older(@drop.time_to_key(Time.now))
    assert_equal(value, 'age' => 3)

    # newer(past)
    assert_equal(@drop.newer(0)[1], 'age' => 1)
    assert_equal(@drop.newer(0)[1], 'age' => 1)
  end

  def test_time_travel
    @drop.write('age' => 1)
    @drop.write('age' => 2)
    @drop.write('age' => 3)
    oid, value = @drop.older(nil)
    assert_equal(value, 'age' => 3)
    oid, value = @drop.older(oid)
    assert_equal(value, 'age' => 2)
    oid, value = @drop.older(oid)
    assert_equal(value, 'age' => 1)
    oid, value = @drop.older(oid)
    assert_equal(oid, nil)
    assert_equal(value, nil)
    
    oid, value = @drop.newer(0)
    assert_equal(value, 'age' => 1)
    oid, value = @drop.newer(oid)
    assert_equal(value, 'age' => 2)
    oid, value = @drop.newer(oid)
    assert_equal(value, 'age' => 3)
    oid, value = @drop.newer(oid)
    assert_equal(oid, nil)
    assert_equal(value, nil)
    
    latest ,= @drop.older(nil)
    @drop._forget(latest)

    oid, value = @drop.newer(0)
    assert_equal(value, 'age' => 1)
    oid, value = @drop.newer(oid)
    assert_equal(value, 'age' => 2)
    oid, value = @drop.newer(oid)
    assert_equal(value, 'age' => 3)
    oid, value = @drop.newer(oid)
    assert_equal(oid, nil)
    assert_equal(value, nil)
  end
end

class BasicTest < BasicNilTest
  def remove_drop(dir='test_db')
    FileUtils.rm_r(dir, :force => true)
  end

  def setup
    remove_drop
    @drop = Drop.new('test_db')
  end

  def teardown
    remove_drop
  end
end