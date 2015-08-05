# coding: utf-8
require 'sqlite3'

# Database stuff
class Db
  attr_accessor :db
  def initialize
    # begin
      @db = SQLite3::Database.new DB_FILENAME
      @db.results_as_hash = true
    # rescue SQLite3::Exception => e 
    #     puts "Exception occurred"
    #     puts e
    # ensure
    #   @db.close if @db
    # end
    create_schema unless schema?
    @item = empty_row
  end

  # Create a table
  def create_schema
    @db.execute '
      create table items (
        code varchar(50),
        name varchar(255),
        description varchar(2000),
        image_link varchar2(2000),
        checkout boolean default false,
        tags varchar2(2000)
      );'
  end

  #Is the db schema exists ?
  def schema?
    begin
      r = db.prepare "select * from Items"
      true
    rescue
      puts "need to create db schema..."
      false
    end
  end

  def empty_row
    [{'code' => '', 'name' => '', 'description' => '',  'image_link' => '', 'checkout' => '', 'tags' => ''}]
  end

  # select data
  def select_all_items
    @db.execute "select * from items order by name"
  end

  def read(code)
    r = @db.execute 'select * from items where code = ?', code
    if r[0].nil?
      return empty_row
    end
    r
  end

  # see if this item exists in database
  def exists?(code)
    @item = empty_row
    @item = read code
    !@item[0]['code'].empty?
  end

  # Is item checked out ?
  def checkout?(code)
    if exists? code
      return @item[0]['checkout']
    end
    false
  end

  # Adds an item
  def add_item(code, name, desc, image_link, tags)
    @db.execute 'INSERT INTO items (code, name, description,
      image_link, tags) VALUES (?, ?, ?, ?, ?)', [code.to_s, name.to_s, desc.to_s, image_link.to_s, tags.to_s]
  end

  def add_serveral_items (data)
    n = 0
    data.reject! { 
      |k, v| k == 'code' 
    }.each { |row|
      puts "adding #{row[1]} ##{row[0]}"
      add_item(row[0], row[1], row[2], '', row[3]) unless row[0].empty?
      n = n + 1
    }
    puts "#{n} inserted rows"
  end

  # deletes an item
  def delete_item(code)
    @db.execute "delete from items where code = '?'", code
  end

  # add tags
  def add_tag(code, tag)
    item = read code
    newtags = item['tags'] + ', ' + tag
    @db.execute "update items set tags = '?' where code = '?'", [newtags, code]
  end

  # delete one tag
  def delete_tag(code, tag)
    item = read code
    newtags = item['tags'].split(',').reject { |t| t == tag }.join(',')
    @db.execute "update items set tags = '?' where code = '?'", [newtags, code]
  end

  # Delete all tags
  def delete_tags(code)
    @db.execute "update items set tags = '' where code = '?'", code
  end

  # Get the highest id from db
  def lastid
    r = @db.get_first_row 'select max(code) as max from items'
    if r['max'].nil?
      r['max'] = "0"
    end 
    r['max'] 
  end
end

# Intaciate once.
DB = Db.new
