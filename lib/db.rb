# coding: utf-8
require 'sqlite3'

# Database stuff
class Db
  attr_accessor :db
  def initialize
    @db = SQLite3::Database.new DB_FILENAME
    @db.results_as_hash = true
    create_schema unless schema?
    @item = empty_row
  end

  # Create a table
  def create_schema
    puts "  Creating db schema..."
    puts "  Creating table items..."
    @db.execute "
      create table items (
        code varchar(50) PRIMARY KEY,
        name varchar(255),
        description varchar(2000),
        image_link varchar2(2000),
        checkout varchar(1) default 'N',
        tags varchar2(2000)
      );"
    puts "  Creating table tags..."
    @db.execute 'create table tags (
        id integer,
        tag varchar(255),
        color varchar(50)
        );'
    puts "  Creating table tags_items..."
    @db.execute 'create table tags_items (
        item_code varchar(50),
        tag_id integer
        );'
  end

  #Is the db schema exists ?
  def schema?
    begin
      r = db.prepare "select * from Items"
      true
    rescue
      false
    end
  end

    # Get the highest id from a table
  def lastid(table_name, col='code')
    r = @db.get_first_row 'select max('+col+') as max from ' + table_name
    if r['max'].nil?
      r['max'] = "0"
    end 
    r['max'] 
  end

  def empty_row
    [{'code' => '', 'name' => '', 'description' => '',  'image_link' => '', 'checkout' => '', 'tags' => ''}]
  end

  # select data
  def select_all_items
    res = @db.execute "select * from items order by name"
    res.each { |row|
      taglist = select_tags_for_item(row[0]).flatten
      row['taglist'] = taglist
    }
    res
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
      return @item[0]['checkout'] == 'O'
    end
    false
  end

  def checkout(code)
    @db.execute "update items set checkout = 'O' where code = ?", code
  end

  def checkin(code)
    @db.execute "update items set checkout = 'N' where code = ?", code
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
    unlink_item code
    @db.execute "delete from items where code = ?", code
  end

  #
  # Tags routines
  #
  def select_all_tags
    @db.execute "select t.id, t.tag, t.color, count(ti.item_code) count_items
                 from tags t left join tags_items ti
                 on t.id = ti.tag_id
                 group by t.id, t.tag, t.color
                 order by t.tag"
  end

  def select_tags_for_item(code)
    @db.execute "select t.tag, t.color
                 from tags t, tags_items ti
                 where t.id = ti.tag_id
                   and item_code = ?
                 order by t.tag", code
  end

  def select_items_for_tag(id)
    @db.execute "select t.tag, t.color, i.code, i.name, i.description, i.image_link, i.checkout
                 from tags t, tags_items ti, items i
                 where t.id = ti.tag_id
                   and item_code = i.code
                   and t.id = ?
                 order by i.name", id
  end


  # add tag
  def add_tag(tag, color)
    unless tag.empty?
      newid = lastid('tags', col='id').to_i + 1
      @db.execute "insert into tags values ( ?, ?, ?)", [newid, tag, color]
    end
  end

  # delete one tag
  def delete_tag(id)
    unlink_tag id
    @db.execute "delete from tags where id = ?", id
  end

  #
  # Link / unlink tags
  #
  def link_tag(code, id)
    @db.execute "insert into tags_items values (?, ?)", [code, id]
  end

  def unlink_tag(id)
    @db.execute "delete from tags_items where tag_id = ?", id
  end

  def unlink_item(code)
    @db.execute "delete from tags_items where item_code = ?", code
  end


end

# Intaciate once.
DB = Db.new
