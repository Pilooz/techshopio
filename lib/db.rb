# coding: utf-8
require 'sqlite3'

# Database stuff
class Db
  attr_accessor :db
  OUT = 1
  IN = 0
  def initialize
    @db = SQLite3::Database.new DB_FILENAME
    @db.results_as_hash = true
    # TODO : Puts these two script in a Rake Task ?
    create_schema unless schema?
    synchronize_image!
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
        chkout_date timestamp,
        chkin_date timestamp
      );"
    puts "  Creating table tags..."
    @db.execute 'create table tags (
        id integer,
        tag varchar(255),
        color varchar(50),
        firstname varchar(255) default null,
        lastname varchar(255) default null,
        email varchar(255) default null
        );'
    puts "  Creating table tags_items..."
    @db.execute 'create table tags_items (
        item_code varchar(50),
        tag_id integer
        );'
    puts "  Creating table items_log..."
    @db.execute 'create table items_log (
        item_code varchar(50),
        tag_id integer,
        move integer,
        move_date timestamp
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

  # True if database is supposed empty
  def empty_DB?
    r = @db.execute "select count(1) as cnt from Items" 
    return r[0]["cnt"] == 0
  end

  # Synchronize image with DB
  def synchronize_image!
    imgs = {}

    # 1. Unlink from DB all unfound images
    puts "  Synchronizing images with DB..."
    r = select_all_items
    r.each { |i|
      unless i['image_link'].empty?
        # Hash with all used images
        imgs[i['image_link']] = i['code']
        unless  File::exists? "#{APP_ROOT}/public/pictures/#{i['image_link']}"
          puts "unlinking #{i['image_link']} from item ##{i['code']}"
          update_item_image_link i['code'], ''
        end
      end
    }

    # 2. Delete all unreferenced image from directory
    Dir.entries("#{APP_ROOT}/public/pictures/")
      .reject { |f| f == '.' || f == '..'  }
      .reject { |f| f[0..4]  == 'thumb'}
      .each { |f| 
        unless imgs.has_key? f
          File::unlink "#{APP_ROOT}/public/pictures/#{f}" if File::exists? "#{APP_ROOT}/public/pictures/#{f}"
          File::unlink "#{APP_ROOT}/public/pictures/thumb-#{f}" if File::exists? "#{APP_ROOT}/public/pictures/thumb-#{f}"
        end
    }

  end


    # Get the highest id from a table
    # Can't work with a varchar column.
  def lastid(table_name, col='code')
    last = 0
    r = @db.get_first_row 'select ' + col + ' as max from ' + table_name + ' order by cast(' + col + ' As Int) desc'
    unless r.nil?
      last = r['max']
    end
    puts "selecting lastid from #{table_name}.#{col} : #{last}"
    last
  end

  def empty_row
    [{'code' => '', 'name' => '', 'description' => '',  'image_link' => '', 'checkout' => ''}]
  end

  # select data
  def select_all_items(extract_tag=true)
    res = @db.execute "select * from items order by name"
    res.each { |row|
      taglist = select_tags_for_item(row[0]).flatten
      row['taglist'] = taglist
    } if extract_tag
    res
  end

  def read(code)
    code = code.upcase unless code.nil?
    r = @db.execute 'select * from items where upper(code) = ?', code
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

  def checkout(code, chkout_date, chkin_date)
    @db.execute "update items set checkout = 'O', chkout_date = '" + chkout_date.to_s + "'" +
                ", chkin_date = '" + chkin_date.to_s + "' where upper(code) = ?", code.upcase
  end

  def checkin(code)
    @db.execute "update items set checkout = 'N', chkout_date = '' " + 
                ", chkin_date = '' where upper(code) = ?", code.upcase
  end

  # Adds an item
  def add_item(code, name, desc, image_link, checkout, chkout_date, chkin_date)
    @db.execute 'INSERT INTO items (code, name, 
        description, image_link, checkout, chkout_date, chkin_date) VALUES (?, ?, ?, ?, ?, ?, ?)', 
        [code.to_s.upcase, name.to_s, desc.to_s, image_link.to_s, checkout.to_s, chkout_date, chkin_date]
  end

  # update an item
  def update_item(code, name, desc, image_link)
    @db.execute 'update items  set name = ?, description = ?, image_link = ?
        where upper(code) = ?', [name.to_s, desc.to_s, image_link.to_s, code.to_s.upcase]
  end

  # Updates an item image_link
  def update_item_image_link(code, image_link)
    @db.execute 'update items set image_link = ? where upper(code) = ?', [image_link.to_s, code.to_s.upcase]
  end

  def add_serveral_items (data)
    n = 0
    data.reject! { |k, v| k == 'code' }
    .reject! { | row | exists? row[0] }
    
    data.each { |row|
      puts "adding #{row[1]} ##{row[0]}"
      add_item(row[0], row[1], row[2], row[3], row[4] || "N", row[5], row[6]) unless row[0].empty?
      n = n + 1
    }
    puts "#{n} inserted rows"
  end

  # deletes an item
  def delete_item(code)
    unlink_item code
    @db.execute "delete from items where upper(code) = ?", code.upcase
  end

  #
  # Tags routines
  #
  def select_all_tags
    @db.execute "select t.id, t.tag, t.color, t.firstname, t.lastname, t.email, count(ti.item_code) count_items
                 from tags t left join tags_items ti
                 on t.id = ti.tag_id
                 group by t.id, t.tag, t.color, t.firstname, t.lastname, t.email
                 order by t.tag"
  end

  def select_tags_for_item(code)
    @db.execute "select t.id, t.tag, t.color
                 from tags t, tags_items ti
                 where t.id = ti.tag_id
                   and upper(item_code) = ?
                 order by t.tag", code.upcase
  end

  def select_available_tags_for_item(code)
    t1 = @db.execute "select t.id, t.tag, t.color
                 from tags t, tags_items ti
                 where t.id = ti.tag_id
                   and upper(item_code) = ?", code.upcase
    t2 = @db.execute "select t.id, t.tag, t.color
                 from tags t 
                 order by t.tag"
    t2 - t1
  end

  def select_items_for_tag(id)
    @db.execute "select t.tag, t.color, i.code, i.name, i.description, i.image_link, i.checkout
                 from tags t, tags_items ti, items i
                 where t.id = ti.tag_id
                   and upper(item_code) = upper(i.code)
                   and t.id = ?
                 order by i.name", id
  end

  def select_tag(id)
    @db.execute "select t.id, t.tag, t.color, t.firstname, t.lastname, t.email
                 from tags t
                 where t.id = ?", id
  end

  def select_tags
    @db.execute "select t.id, t.tag, t.color, t.firstname, t.lastname, t.email from tags t order by t.tag"
  end


  # add tag
  def add_tag(tag, color, firstname, lastname, email)
    unless tag.empty?
      newid = lastid('tags', col='id')
      newid = newid + 1
      @db.execute "insert into tags values ( ?, ?, ?, ?, ?, ?)", [newid, tag, color, firstname, lastname, email]
    end
  end

  # add tag
  def add_contact_to_tag(id, firstname, lastname, email)
    unless id.empty?
      @db.execute "update tags set firstname = ?, lastname = ?, email = ? where id = ?", 
                  [firstname.to_s, lastname.to_s, email.to_s, id]
    end
  end

  # adding several tags (for DB restore routine)
  def add_serveral_tags (data)
    n = 0
    data.reject! { 
      |k, v| k == 'id' 
    }.each { |row|
      puts "adding #{row[1]} ##{row[0]}"
      @db.execute "insert into tags values ( ?, ?, ?, ?, ?, ?)", 
                  [row[0], row[1], row[2], row[3], row[4], row[5]] unless row[0].empty?
      n = n + 1
    }
    puts "#{n} inserted rows"
  end

  # delete one tag
  def delete_tag(id)
    # Checkin all items 
      items = select_items_for_tag id
      items.each { |i|
        puts "checking in item ##{i['code']}"
        checkin i['code']
      } 
    # unlink tag from items
    unlink_tag id
    @db.execute "delete from tags where id = ?", id
  end

  #
  # Link / unlink tags : table tags_items
  #
  def select_all_tags_items
    @db.execute "select item_code, tag_id from tags_items order by item_code"
  end

  def link_tag(code, id)
    @db.execute "insert into tags_items values (?, ?)", [code.upcase, id]
    log_item code, id, OUT
  end

  def unlink_tag(id)
    @db.execute "delete from tags_items where tag_id = ?", id
  end

  def unlink_tag_from_item(code, id)
    @db.execute "delete from tags_items where upper(item_code) = ? and tag_id = ?", [code.upcase, id]
    log_item code, id, IN
  end

  def unlink_item(code)
    tags = select_tags_for_item code
    @db.execute "delete from tags_items where upper(item_code) = ?", code.upcase
    tags.each { |t|
      log_item code, t['id'], IN
    }
  end

  # Adding several links between items and tags (for db restore)
  def add_serveral_tags_items(data)
    n = 0
    data.reject! { 
      |k, v| k == 'item_code' 
    }.each { |row|
      puts "adding #{row[1]} ##{row[0]}"
      link_tag(row[0], row[1]) unless row[0].empty?
      n = n + 1
    }
    puts "#{n} inserted rows"
  end

  #
  # Logging item move (in/out) => move
  #
  def log_item(code, tag_id, move)
    @db.execute "insert into items_log values (?, ?, ?, ?)", [code.upcase, tag_id, move, Time.now.to_s]
  end

  def delete_items_log
    @db.execute "delete from items_log"
  end

  def select_all_items_log
    @db.execute "select item_code, tag_id, move, move_date from items_log order by move_date"
  end

  def select_checkin_out_by_hour(dir)
    @db.execute "select count(l.move) as move, substr(l.move_date,1,13) as move_date 
                from items i, items_log l, tags t 
                where t.id = l.tag_id 
                  and i.code = l.item_code
                  and l.move = " + dir + "
                group by substr(l.move_date,1,13)
                order by move_date"
  end

  # Adding several links between items and tags (for db restore)
  def add_serveral_items_log(data)
    n = 0
    data.reject! { 
      |k, v| k == 'item_code' 
    }.each { |row|
      puts "adding #{row[1]} ##{row[0]}, #{row[3]}"
      @db.execute "insert into items_log values (?, ?, ?, ?)", [row[0], row[1], row[2], row[3]]
      n = n + 1
    }
    puts "#{n} inserted rows"
  end


end

# Intaciate once.
DB = Db.new
