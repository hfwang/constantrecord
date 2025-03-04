require File.expand_path 'helper', File.dirname(__FILE__)

class SimpleClass < ConstantRecord::Base
  data 'Lithuania', 'Latvia', 'Estonia'
end

class SimpleHashyClass < ConstantRecord::Base
  data({:name => 'Lithuania'},
       {:name => 'Latvia'},
       {'name' => 'Estonia'})
end

class SimpleClass2 < ConstantRecord::Base
  columns :album
  data 'Sgt. Pepper', 'Magical Mystery Tour', 'Abbey Road'
end

class MultiColumnClass < ConstantRecord::Base
  columns :short, :description
  data ['EUR', 'Euro'],
       ['USD', 'US Dollar'],
       ['CAD', 'Canadian Dollar'],
       ['GBP', 'British Pound sterling'],
       ['CHF', 'Swiss franc']
end

class HashyMultiColumnClass < ConstantRecord::Base
  columns :short, :description
  data({:short => 'EUR', :description => 'Euro'},
       {:short => 'USD', :description => 'US Dollar'},
       {:short => 'CAD', :description => 'Canadian Dollar'},
       {:short => 'GBP', :description => 'British Pound sterling'},
       {:short => 'CHF', :description => 'Swiss franc'})
end

# A table/class that makes no sense, but has integers and booleans
class MultiColumnClassNotString < ConstantRecord::Base
  columns :prime, :bool
  data [11, false],
       [13, false],
       [17, true],
       [19, false]
end

class ForValidation < ConstantRecord::Base
  columns :name, :value
  data ['normal', 1],
       ['gift',   2],
       ['friend', 3]
end

class BadColumnNames < ConstantRecord::Base
#  columns :instance_method, :class_variable
#  data ['foo', 'bar']
end

class WithConstants < ConstantRecord::Base
  self.create_constants = true
  columns :name, :value
  data ['john',   1],
       ['paul',   2],
       ['george', 3],
       ['ringo',  4]
end

class TestConstantRecord < Test::Unit::TestCase
  def test_simple_finder
    assert_equal 'Estonia', SimpleClass.find(3).name
    assert_equal 3, SimpleClass.find(3).id
    assert_nil SimpleClass.find(4)
    assert_nil SimpleClass.find(0)
    assert_nil SimpleClass.find(nil)
    assert_equal 'Estonia', SimpleClass.find_by_name('Estonia').name
    assert_equal 3, SimpleClass.find_by_name('Estonia').id
    assert_raise (RuntimeError) { SimpleClass.find_by_foo('bar') }
    assert_equal [ 'Lithuania', 'Latvia', 'Estonia' ], SimpleClass.find(:all).collect{|o| o.name}
    assert_equal [ 1, 2, 3 ], SimpleClass.find(:all).collect{|o| o.id}
    assert_equal [ 1, 2, 3 ], SimpleClass.find(:all, :ignored => 'blah').collect{|o| o.id}
    assert_equal [ 1, 2, 3 ], SimpleClass.all.collect{|o| o.id}
    assert_equal [ 1, 2, 3 ], SimpleClass.all(:ignored => 'blah').collect{|o| o.id}
    assert_equal 3, SimpleClass.count
    assert_equal 'Lithuania', SimpleClass.find(:first).name
    assert_equal 'Lithuania', SimpleClass.first.name
    assert_equal 'Estonia', SimpleClass.first(:conditions => {:name => "Estonia"}).name
    assert_equal 'Estonia', SimpleClass.find(:last).name
    assert_equal 'Estonia', SimpleClass.last.name
  end

  def test_hashy_class_parsing
    assert_equal 'Lithuania', SimpleHashyClass.find(:first).name
    assert_equal 'Estonia', SimpleHashyClass.find_by_name('Estonia').name
    assert_equal 'USD', HashyMultiColumnClass.find_by_short('USD').short
    assert_equal 'US Dollar', HashyMultiColumnClass.find_by_short('USD').description
    all = HashyMultiColumnClass.find(:all, :conditions => {})
    chf = all[4]
    assert 5 == chf.id && chf.short && 'Swiss franc' == chf.description
  end

  def test_simple_finder_with_custom_column_name
    assert_equal 'Abbey Road', SimpleClass2.find(3).album
    assert_equal 3, SimpleClass2.find(3).id
    assert_nil SimpleClass2.find(4)
    assert_nil SimpleClass2.find(0)
    assert_nil SimpleClass2.find(nil)
    assert_equal 'Sgt. Pepper', SimpleClass2.find_by_album('Sgt. Pepper').album
    assert_equal 1, SimpleClass2.find_by_album('Sgt. Pepper').id
    assert_raise (RuntimeError) { SimpleClass2.find_by_name('Sgt. Pepper') }
    assert_raise (NoMethodError) { SimpleClass2.find(1).name }
    assert_equal [ 'Sgt. Pepper', 'Magical Mystery Tour', 'Abbey Road' ], SimpleClass2.find(:all).collect{|o| o.album}
    assert_equal [ 1, 2, 3 ], SimpleClass2.find(:all).collect{|o| o.id}
    assert_equal 3, SimpleClass2.count
  end

  def test_multi_column_finder
    all = MultiColumnClass.find(:all, :conditions => {})
    chf = all[4]
    assert 5 == chf.id && chf.short && 'Swiss franc' == chf.description

    assert_equal 'Canadian Dollar', MultiColumnClass.find_by_short('CAD').description
    assert_equal 3, MultiColumnClass.find_by_short('CAD').id

    assert_nil MultiColumnClass.find(6)
    assert_nil MultiColumnClass.find(0)
    assert_nil MultiColumnClass.find(nil)
    assert_raise (RuntimeError) { MultiColumnClass.find_by_name('EUR') }
    assert_equal [ 'EUR', 'USD', 'CAD', 'GBP', 'CHF' ], MultiColumnClass.find(:all).collect{|o| o.short}
    assert_equal [ 1, 2, 3, 4, 5 ], MultiColumnClass.find(:all).collect{|o| o.id}
    assert_equal 5, MultiColumnClass.count

    assert_equal 'Euro', MultiColumnClass['EUR']
    assert_equal 'US Dollar', MultiColumnClass['USD']
    assert_raise (ConstantRecord::ConstantNotFound) { MultiColumnClass['BadValue'] }
  end

  def test_multi_column_not_string_finder
    assert_equal 4, MultiColumnClassNotString.find_by_prime(19).id
    assert_equal 4, MultiColumnClassNotString.find_by_prime('19').id
    assert_equal 3, MultiColumnClassNotString.find_by_bool(true).id
  end

  def test_options_for_select
    assert_equal [['Lithuania', 1], ['Latvia', 2], ['Estonia', 3]], SimpleClass.options_for_select
    assert_equal [['n/a', 0], ['Lithuania', 1], ['Latvia', 2], ['Estonia', 3]],
      SimpleClass.options_for_select(:include_null => true, :null_text => 'n/a')
    assert_equal [['-', nil], ['Lithuania', 1], ['Latvia', 2], ['Estonia', 3]],
      SimpleClass.options_for_select(:include_null => true, :null_value => nil)
    assert_equal [['Euro', 1], ['US Dollar', 2], ['Canadian Dollar', 3],
      ['British Pound sterling', 4], ['Swiss franc', 5]],
      MultiColumnClass.options_for_select(:display => :description)
    assert_equal [['-', "nothn'"], ['Euro', 'EUR'], ['US Dollar', 'USD'],
      ['Canadian Dollar', 'CAD'], ['British Pound sterling', 'GBP'], ['Swiss franc', 'CHF']],
      MultiColumnClass.options_for_select(:display => :description, :value => :short,
        :include_null => true, :null_value => "nothn'")
    assert_equal [['*Sgt. Pepper*', 1], ['*Magical Mystery Tour*', 2], ['*Abbey Road*', 3]],
      SimpleClass2.options_for_select(:display => Proc.new{|obj| "*#{obj.album}*"})
  end

  def test_all_shortcut
    assert_equal SimpleClass.find(:all).collect{|o| o.name}, SimpleClass.all.collect{|o| o.name}
  end

  def test_validation_methods
    # validates_inclusion_of :thingy, :in => ForValidation.names
    assert_equal ['normal','gift','friend'], ForValidation.names
    assert_equal [1,2,3], ForValidation.values
    assert_equal [1,2,3,4,5], MultiColumnClass.ids
    assert_equal ['Sgt. Pepper', 'Magical Mystery Tour', 'Abbey Road'], SimpleClass2.albums
    assert_equal %w{EUR USD CAD GBP CHF}, MultiColumnClass.shorts
    assert_raise (NoMethodError) { MultiColumnClass.names }
    assert_raise (NoMethodError) { MultiColumnClass.values }
  end

  def test_logger
    assert_nothing_raised { ConstantRecord::Base.logger = MyTestLogger.new }
    assert_nothing_raised { SimpleClass.respond_to?(:asdfghjkl) }
    assert_nothing_raised { MultiColumnClass.find(1).respond_to?(:asdfghjkl) }
  end

  def test_bad_colum_names
    warnings_count = ConstantRecord::Base.logger.warn_count
    BadColumnNames.columns :instance_method, :class_variable    #  must log 2 warnings
    assert_equal ConstantRecord::Base.logger.warn_count - warnings_count, 2
  end

  def test_attribute_accessors
    # TODO!
  end

  def test_constant_creation
    assert_equal 1, WithConstants::JOHN
    assert_equal 2, WithConstants::PAUL
    assert_equal 3, WithConstants::GEORGE
    assert_equal 4, WithConstants::RINGO
    assert_raise (NameError) { WithConstants::NICK }
    assert_raise (NameError) { ForValidation::JOHN }
  end
end
