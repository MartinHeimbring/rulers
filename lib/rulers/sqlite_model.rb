require "sqlite3"
require "rulers/util"

# create a new sqlite3 database
DB = SQLite3::Database.new "test.db"

module Rulers
  module Model
    class SQLite

      # create table name from respective class (-instance) name
      def self.table
        Rulers.to_underscore name
      end

      # call table_info to get the schema
      # Returns information about +table+. Yields each row of table information if a block is provided.
      # for each row in the schema
      # I'll store the "name" as key and the "type" as value of the @schema hash and return the hash at the end
      def self.schema
        return @schema if @schema
        @schema = {}
        DB.table_info(table) do |row|
          @schema[row["name"]] = row["type"]
        end
        # Since those are self methods defined on the class object, @schema is actually an instance variable of the class itself,
        # not on an instance -- so we’ll only have one for each class or subclass, not one for each instance variable.
        @schema
      end

      # we initialize a new SQLite class everytime we create a new record in the db
      # so we can access the instance using ["key"] to get value
      def initialize(data = nil)
        @hash = data
      end

      # helper method to convert user input into sql (if possible)
      # and raise an error if input format is not compatible with sql
      def self.to_sql(val)
        case val
          when Numeric
            val.to_s
          when String
            "'#{val}'"
          else
            raise "Can't change #{val.class} to SQL!"
        end
      end


      # create new record in DB
      # In SQLite the INTEGER PRIMARY KEY field we made, called “id”, will automatically increment to the next unused ID.
      def self.create(values)
        # that's why we'll delete any given "id" key from the values hash
        values.delete "id"
        # and exclude "id" from the keys in our schema
        # instead of schema.keys - ["id"] I could've also used schema.keys.delete "id"
        keys = schema.keys - ["id"]
        # iterate over all keys (except "id") in the schema and set the values for each key equal to the values for each key in the input hash (values)
        # call .to_sql as safety precaution
        vals = keys.map{ |key| values[key] ? to_sql(values[key]) : "null" }
        # insert keys and respective values into table
        insert_values = "INSERT INTO #{table} (#{keys.join ","}) VALUES (#{vals.join ","});"
        DB.execute(insert_values)
        # create data hash from keys and values, kind of to "unite" those two arrays
        data = Hash[keys.zip vals]
        # finally - in a separate sql command we select the rowid of the last insertion (the one on line 61)
        select_id = "SELECT last_insert_rowid();"
        # and set the "id" in the hash to rowid
        data["id"] = DB.execute(select_id)[0][0]
        # pass the created hash to the initializer
        self.new data
      end


      # count how many objects / rows exist in the db
      def self.count
        sql = "SELECT COUNT(*) FROM #{table}"
        DB.execute(sql)[0][0]
      end


      # find record in db by id
      def self.find(id)
        # select all keys of the schema hash from the db table
        # where the id matches the input id
        find_record = "select #{schema.keys.join ","} from #{table} where id = #{id};"
        row = DB.execute find_record
        # take two arrays: schema.keys and row[0] and shuffle them together into a hash (zip FTW!)
        data = Hash[schema.keys.zip row[0]]
        # instantiate a new SQLite object with that hash so we can access it
        self.new data
      end

      # access the content of a database row (represented as the @hash) via its key using square brackets
      def [](name)
        @hash[name.to_s]
      end

      # respective setter method for Update action
      def []=(name, value)
        @hash[name.to_s] = value
      end


      # used for update action
      def save!
        # check if the object we want to save! is in the database by checking if @hash["id"] is set
        unless @hash["id"]
          # create a new record if @hash["id"] is nil (= record doesn't exist yet)
          self.create
          # early return from this method after creating new record
          return true
        end

        # iterate over each key value pair in @hash
        fields = @hash.map do |k, v|
          # and get them into the right sql format
          "#{k}=#{self.class.to_sql(v)}"
        end.join ","
        # update fields for record with @hash["id"]
        update_table = "UPDATE #{self.class.table} SET #{fields} WHERE id = #{@hash["id"]}"
        DB.execute update_table
        true
      end

      def save
        # ruby has "same-line rescue":
        # the difference between save and save! is that save doesn't raise an exception
        # if saving fails, that's why we simply return "false" if an error occurs
        self.save! rescue false
      end
    end
  end
end