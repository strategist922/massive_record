# Massive Record

HBase API and ORM using the HBase Thrift API.

The Thrift library used has been tested with hbase-0.89.20100924.
  
See introduction to HBase model architecture :  
http://wiki.apache.org/hadoop/Hbase/HbaseArchitecture  
Understanding terminology of Table / Row / Column family / Column / Cell :  
http://jimbojw.com/wiki/index.php?title=Understanding_Hbase_and_BigTable


## Installation

### IRB

Install the Ruby thrift library :

    gem install thrift
    
Checkout the massive_record project and install it as a Gem :

    git clone git://github.com/CompanyBook/massive_record.git
    cd massive_record/
    rake install massive_record.gemspec
    
Then in IRB :

    require 'rubygems'
    require 'massive_record'
    
    conn = MassiveRecord::Connection.new(:host => 'localhost', :port => 9090)
    
### Ruby on Rails
    
Add the following Gems in your Gemfile :
    
    gem 'thrift', '0.5.0'
    gem 'massive_record', :git => 'git://github.com/CompanyBook/massive_record.git'

Create an config/hbase.yml file with the following content :
  
    defaults: &defaults
      host: somewhere.compute.amazonaws.com # No 'http', it's a Thrift connection
      port: 9090

    development:
      <<: *defaults

    test:
      <<: *defaults
      <<: *development

    production:
      <<: *defaults


## Thrift API

Ruby Library using the HBase Thrift API.
http://wiki.apache.org/hadoop/Hbase/ThriftApi

The generated Ruby files can be found under lib/massive_record/thrift/  
The whole API (CRUD and more) is present in the Client object (Apache::Hadoop::Hbase::Thrift::Hbase::Client).  
The client can be easily initialized using the MassiveRecord connection :

    conn = MassiveRecord::Connection.new(:host => 'localhost', :port => 9090)
    conn.open
    
    client = conn.client
    # Do whatever you want with the client object
    

## Ruby API

Thrift API wrapper (See spec/ folder for more examples) :
  
    # Init a new connection with HBase
    conn = MassiveRecord::Connection.new(:host => 'localhost', :port => 9090)
    conn.open
    
    # OR init a connection using the config/hbase.yml file with Rails
    conn = MassiveRecord::Base.connection
  
    # Fetch tables name
    conn.tables # => ["companies", "news", "webpages"]
  
    # Init a table
    table = MassiveRecord::Table.new(conn, :people)
  
    # Add a column family
    column = MassiveRecord::ColumnFamily.new(:info)
    table.column_families.push(column)
  
    # Or bulk add column families
    table.create_column_families([:friends, :misc])
    
    # Create the table
    table.save # will raise an exception if the table already exists
  
    # Fetch column families from the database
    table.fetch_column_families # => [ColumnFamily#RTY4424, ColumnFamily#R475424, ColumnFamily#GHJ9424]
    table.column_families.collect(&:name) # => ["info", "friends", "misc"]
  
    # Add a new row
    row = MassiveRecord::Row.new
    row.id = "my_unique_id"
    row.values = { :info => { :first_name => "H", :last_name => "Base", :email => "h@base.com" } }
    row.table = table
    row.save
  
    # Fetch rows
    table.first # => MassiveRecord#ID1
    table.all(:limit => 10) # => [MassiveRecord#ID1, MassiveRecord#ID2, ...]
    table.find("ID2") # => MassiveRecord#ID2
    table.find(["ID1", "ID2"]) # => [MassiveRecord#ID1, MassiveRecord#ID2]
    table.all(:limit => 3, :start => "ID2") # => [MassiveRecord#ID2, MassiveRecord#ID3, MassiveRecord#ID4]
    
    # Manipulate rows
    table.first.destroy # => true
    
    # Remove the table
    table.destroy
  
  
## ORM - In progress

    class Person < MassiveRecord::Base.table
      
      validates_presence_of :first_name, :last_name, :email
      validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
      
      select :light, :info
      select :full, [:info, :addresses, :friends, :misc]
      select :manage, [:addresses, :friends]
      
      column_family :info do
        field :first_name
        field :last_name
        field :email
        field :phone_number
        field :date_of_birth, Date
        field :newsletter, Boolean, :default => false
        timestamps # created_at, updated_at are automatically managed on field update
      end
      
      column_family :addresses do
        has_many :post_addresses, Address, :type => :post
        has_many :street_addresses, Address, :type => :street
      end
      
      column_family :friends do
        has_many :friends, Friend, :friend => self
      end
      
      column_family :misc do
        field :status, Integer, :column => :st
        field :websites, Hash # { :facebook_page => "XYZ", :blog => "XYZ" }
      end
    
      def name
        "#{self.first_name} #{self.last_name}"
      end
      
      def active?
        self.status == 1
      end
      
    end
  
    class Address < MassiveRecord::Base.column
      
      validates_format_of :zip_code, :with => /\[0-9]{6})\Z/i
      
      field :address
      field :city
      field :county
      field :zip_code
      field :country, Country
      
      timestamps
      
      belongs_to :person
    
      def simple_format
        "#{self.person.name} - #{address}, #{city}, #{country}"
      end
    
    end
  
    class Friend < Person
      
      belongs_to :friend
      
      def is_cool?
        self.first_name == "Bob"
      end
      
    end
    
    # New record
    p = Person.new
    p.first_name = "John"
    p.email = "hbase@companybook.no"
    p.address = Address.new(address: "Philip Pedersensver 1", city: "Oslo", country: "Norway")
    p.save
  
    # Find
    p = Person.find("my_person_id")
    p.first_name # => John
    p.address # => Address#s5645645
    p.address.simple_format # => "John - Philip Pedersensver 1, Oslo, Norway"
    
    # Delete
    p.destroy


## Q&A

How to add a new column family to an existing table?
    
    # Connect to the HBase console on the server itself and enter the following code :
    disable 'status'
    alter 'companies', { NAME => 'new_collumn_familiy' }
    enable 'status'


Copyright (c) 2010 Companybook, released under the MIT license