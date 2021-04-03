# MAINTAINER WANTED

As of 2019 I haven't used Oracle or this library for many years. I would like
to turn it over to someone who is. If you are interested please contact me,
and we can discuss transferring the repository.

## Description
A library for generating an ActiveRecord model from an existing Oracle table.
This will install an "omg" executable that you can use from the command line.

## Synopsis
Using the command line tool:

`omg -d your_database -t locations -u some_user -p some_password`

The above command results in a file called "location.rb". This is an
ActiveRecord model declaration, with all validations, primary keys,
table name and belongs_to relationships defined.

If your LOCATIONS table looks like this:

```sql
create table locations(
  location_id number(4,0) primary key,
  street_address varchar2(40), 
  postal_code varchar2(12),
  city varchar2(30) not null
  state_province varchar2(25),
  country_id CHAR(2),
  constraint "LOC_C_ID_FK" FOREIGN KEY (country_id)
    references COUNTRIES (country_id)
)
```

The omg library will generate this:

```ruby
class Location < ActiveRecord::Base
  set_table_name :locations
  set_primary_key :location_id

  # Table relationships

  belongs_to :countries

  # Validations
  
  validates :location_id, :presence => true, :numericality => {
    :less_than_or_equal_to => 9999, 
    :greater_than_or_equal_to => -9999,
    :only_integer => true
  }

  validates :street_address, :length => {:maximum => 40}
  validates :postal_code, :length => {:maximum => 12}
  validates :city, :length => {:maximum => 30}, :presence => true
  validates :state_province, :length => {:maximum => 25}
  validates :country_id, :length => {:maximum => 2}
end
```

It will also generate a corresponding test file using test-unit 2 by default.
For the above example you will see some tests like this:

```ruby
class TC_Location < Test::Unit::TestCase
  def setup
    @location = Location.new
  end

  test 'table name is locations' do
    assert_equal('locations', Location.table_name)
  end

  test 'primary key is location_id' do
    assert_equal('location_id', Location.primary_key)
  end

  test 'location_id basic functionality' do
    assert_respond_to(@location, :location_id)
    assert_nothing_raised{ @location.location_id }
    assert_kind_of(Numeric, @location.location_id)
  end

  test 'location_id must be a number' do
    @location.location_id = 'test_string'
    assert_false(@location.valid?)
    assert_true(@location.errors[:location_id].include?('is not a number'))
  end

  test 'location_id cannot exceed the value 9999' do
    @location.location_id = 10000
    assert_false(@location.valid?)
    assert_true(@location.errors[:location_id].include?('must be less than or equal to 9999'))
  end

  # ... and so on.
end
```

## Requirements
* ruby-oci8
* getopt

## Optional Libraries
If you want to be able to avoid specifying a username and password on the
command line then you will need the `dbi-dbrc` library.

If you want your models to support multiple primary keys, then you will
need to install the `composite_primary_keys` library.

If you want date format validations, then you will need to install the
`validates_timeliness` library.

## What this library doesn't do
I do not attempt to set `has_many` or `has_one` relationships. There's no good
way to determine that relationship (one or many?). Besides, in practice I
find that most people set custom has_xxx relationships that go over and
above what's set in the Oracle database anyway for purposes of their
application.

I also do not go out of my way to get the model name correct with regards
to singular vs plural. I do a simple guess that covers most cases, but
complex cases will break it. It's much easier for you to rename a class or
file name than it is for me to get this 100% correct.

As of 0.3.1 there's also the `--class` option that let's you explicitly
set it if you like.

## Author's Comments
I chose not to patch the `legacy_data` library because I have no interest in
supporting other vendors other than Oracle with this library. By focusing only
on Oracle I could take advantage of ruby-oci8 features. In addition, I have no
interest in making this a Rails plugin, and I needed the support of multiple
primary keys.

## Future Plans (originally)
* Add support for views.
* Add automatic test suite generation for rspec.
* Explicitly set :foreign_key if using CPK in belongs_to relationships.
* The output could use a little formatting love.

## Acknowlegements
Thanks go to Daniel Luna for his --class patch.

## Known Issues
None known. If you find any issues, please report them on the github project
page at http://www.github.com/djberg96/oracle-model-generator.

## Warranty
This package is provided "as is" and without any express or
implied warranties, including, without limitation, the implied
warranties of merchantability and fitness for a particular purpose.

## Copyright
(C) 2010-2021 Daniel J. Berger
All Rights Reserved

## License
Artistic-2.0

## Author
Daniel J. Berger
