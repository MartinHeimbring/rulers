require "multi_json"

module Rulers
  module Model
    class FileModel

      # reader method for @id
      attr_reader :id

      def initialize(filename)
        @filename = filename
        # Split the given string into a directory and a file component and returns them in a two-element array
        # works both for Mac/Unix slashes and Windows backslashes
        basename = File.split(filename)[-1]
        # File.basename returns the last component of the filename
        # If suffix is ".*", any extension will be removed.
        @id = File.basename(basename, ".json").to_i
        # if filename is "dir/37.json", @id is 37

        # store content of file in obj var
        obj = File.read(filename)
        # MultiJason encodes json file to ruby hash
        @hash = MultiJson.load(obj)
      end

      # square bracket methods are here so we can access the object like a hash
      def [](name)
        @hash[name.to_s]
      end

      def []=(name,value)
        @hash[name.to_s] = value
      end


      # class method to lookup json file in "db" and instantiate a new FileModel object with the file's content as a ruby hash
      def self.find(id)
        begin
          FileModel.new("db/quotes/#{id}.json")
        rescue # from FileNotFound exception
          # return nil if json file can't be found
          return nil
        end
      end


      # return all files as objects
      def self.all
        # store all filenames inside the db/quotes directory that end on .json in the files var
        files = Dir["db/quotes/*.json"]
        # map takes a list (in this case of file names)
        # and replaces them with the result of the block (in this case: FileModel objects)
        files.map{|f| FileModel.new f}
      end


      # add a new file to the "db"
      def self.create(attrs)

        ####### STORE USER INPUT IN HASH #######
          hash = {}
          # store attributes of new quote inside a hash
          hash["submitter"] = attrs["submitter"] ||= ""
          hash["quote"] = attrs["quote"] ||= ""
          hash["attribution"] = attrs["attribution"] ||= ""

        ####### FIND OUT HIGHEST FILE NUMBER AND SET ID OF NEW FILE TO HIGHEST + 1 #######
          # get all files inside quotes directory
          files = Dir["db/quotes/*.json"]
          # split files at "/" and return only the last part (i.e. filename itself: e.g. "1.json")
          names = files.map{|f| f.split("/")[-1]}
          # go over all json file names and keep only the number of each file
          # (.to_i returns only the integer in the string --> "1.json".to_i => 1)
          # and return the highest integer in that collection (.max)
          highest = names.map{|b| b.to_i}.max
          # increment the highest file number by 1
          id = highest + 1

        ####### CREATE & OPEN A NEW FILE WITH THE ID AND FILL IN THE USER INPUT #######
          File.open("db/quotes/#{id}.json", "w") do |f|
            f.write <<TEMPLATE
{
 "submitter":"#{hash["submitter"]}",
 "quote":"#{hash["quote"]}",
 "attribution":"#{hash["attribution"]}"
}
TEMPLATE
          end # finish writing file

        # return a new FileModel instance containing a ruby hash of the file we just created
        FileModel.new "db/quotes/#{id}.json"
      end

    end
  end
end