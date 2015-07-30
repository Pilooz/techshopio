# coding: utf-8
require 'sqlite3'

# Database stuff
class Db
  attr_accessor :db
  def initialize
    @db = SQLite3::Database.new DB_FILENAME
    #create_scheme
  end

  # Create a table
  def create_scheme
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

  # select data
  def select(sql)
    @db.execute( sql )
  end

  def read(code)
    @db.execute 'select * from items where code = ?', code
    # r = @db.execute "select * from items where code = '1234'"
    # puts "#{r}"
  end

  # see if this item exists in database
  def exists?(code)
    item = read code
    !item.empty?
  end

  # Is item checked out ?
  def checkout?(code)
    if exists? code
      item['checkout']
    else
      false
    end
  end

  # Adds an itme
  def add_item(code, name, desc, image_link)
    @db.execute 'INSERT INTO items (code, name, desc,
      image_link) VALUES (?, ?, ?, ?)', [code, name, desc, image_link]
  end

  # deletes an itme
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
end

# Intaciate once.
DB = Db.new
