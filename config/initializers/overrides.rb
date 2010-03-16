require 'UniversalDetector'
class String

  def to_url
    str = strip
    # replace whitespace with `-'
    str.gsub!(/(\s+|\_)/, '-')
    str.downcase!
    search_replace = {
                  'Å' => 'a',
                  'Ä' => 'a',
                  'Ö' => 'o',
                  'Ø' => 'o',
                  'Æ' => 'ae',
                  'å' => 'a',
                  'ä' => 'a',
                  'ö' => 'o',
                  'ø' => 'o',
                  'æ' => 'ae',
                  'é' => 'e',
                  'ü' => 'u'}
    search_replace.each{|key, value| str.gsub!( eval( "/" + key + "/") ,value ) }

    # strip all other characters
    str.gsub!(/[^a-z\-0-9]+/, '')
    
    str.gsub!(/\-$/, '')
    str.gsub!(/^\-/, '')
    str.gsub!(/--/,'-')
    str
  end
  
  def to_url!
    replace to_url
  end
  
  def escape_for_sphinx
    self.gsub(/(:|@|-|!|~|&|"|\(|\)|\\|\|)/) { "\\#{$1}" }
  end

  require 'iconv'  
  def to_utf8(from_charset = 'ISO-8859-1')
    c = Iconv.new('UTF-8', from_charset)  
    c.iconv(self) rescue self
  end
  
  def to_latin1(from_charset = 'UTF-8')
    c = Iconv.new('ISO-8859-1', from_charset)  
    c.iconv(self) rescue self
  end

  def to_win_ansi(from_charset = 'UTF-8')
    c = Iconv.new('Windows-1252', from_charset)  
    c.iconv(self)  
  end

end

class Time
  class << self
    # Used for getting multifield attributes like those generated by a 
    # select_datetime into a new Time object. For example if you have 
    # following <tt>params={:meetup=>{:"time(1i)=>..."}}</tt> just do 
    # following:
    #
    # <tt>Time.parse_from_attributes(params[:meetup], :time)</tt>
    def parse_from_attributes(attrs, field, method=:gm)
      attrs = attrs.keys.sort.grep(/^#{field.to_s}\(.+\)$/).map { |k| attrs[k] }
      attrs.any? ? Time.send(method, *attrs) : nil
    end
  end

  def to_delta(delta_type = :day)
    case delta_type
      when :year then self.class.delta(year)
      when :month then self.class.delta(year, month)
      else self.class.delta(year, month, day)
    end
  end
      
  def self.delta(year, month = nil, day = nil)
    from = Time.local(year, month || 1, day || 1)
    to   = if !day.blank?
      from.advance :days => 1
    elsif !month.blank?
      from.advance :months => 1
    else
      from.advance :years => 1
    end
    return [from.midnight, to.midnight-1]
  end
end

class File
  class << self
    # this will not work on unix with windows paths uploaded
    def sanitize_filename(file_name)
      # get only the filename, not the whole path (from IE)
      just_filename = File.basename(file_name) 
      # replace all none alphanumeric, underscore or perioids with underscore
      just_filename.gsub(/[^\w\.\_]/,'_') 
    end
  end
end


# Overides the money gem's format method to accept :prefix and :precision rules
class Money
  # Creates a new money object. 
  #  Money.new(100) 
  # 
  # Alternativly you can use the convinience methods like 
  # Money.ca_dollar and Money.us_dollar 
  def initialize(cents, currency = Money.default_currency)
    @cents    = cents.to_f.round
    @currency = currency
  end

  def to_f
    (cents.to_f / 100.00).to_f
  end

  def awesome_format(*rules)
    rules = rules.flatten
    if rules.include?(:no_cents)
      formatted = sprintf("%d", cents.to_f / 100  )          
    else
      formatted = sprintf("%.2f", cents.to_f / 100  )      
    end

    if rules.include?(:with_currency)
      formatted << " "
      formatted << '<span class="currency">' if rules.include?(:html)
      formatted << currency
      formatted << '</span>' if rules.include?(:html)
    end
    formatted
  end

  def round
    to_f.round.to_money
  end
end

class Array
  def in_groups_by
    # Group elements into individual array's by the result of a block
    # Similar to the in_groups_of function.
    # NOTE: assumes array is already ordered/sorted by group !!
    curr=nil.class 
    result=[]
    each do |element|
       group=yield(element) # Get grouping value
       result << [] if curr != group # if not same, start a new array
       curr = group
       result[-1] << element
    end
    result
  end
end

module ActionView
  module Helpers
    module TextHelper      
      # this b ugly hack
      def awesome_cycle(first_value, *values)
        values = values.first if values.first.is_a? Array
        if (values.last.instance_of? Hash)
          params = values.pop
          name = params[:name]
        else
          name = "default"
        end
        values.unshift(first_value)

        cycle = get_cycle(name)
        if (cycle.nil? || cycle.values != values)
          cycle = set_cycle(name, Cycle.new(*values))
        end
        return cycle.to_s
      end
    end
  end
end

module Ultrasphinx
  class Configure  
    class << self

      include Associations
  
      # Force all the indexed models to load and register in the MODEL_CONFIGURATION hash.
      def load_constants
        [PORTHOS_ROOT, "#{RAILS_ROOT}/app/models/"].each do |path|
          Dir.chdir path do
            Dir["**/*.rb"].each do |filename|
              open(filename) do |file| 
                begin
                  if file.grep(/is_indexed/).any?
                    filename = filename[0..-4]
                    begin                
                      File.basename(filename).camelize.constantize
                    rescue NameError => e
                      filename.camelize.constantize
                    end
                  end
                rescue Object => e
                  say "warning: possibly critical autoload error on #{filename}"
                  say e.inspect
                end
              end 
            end
          end
        end
        # Build the field-to-type mappings.
        Fields.instance.configure(MODEL_CONFIGURATION)
      end
    end
  end
end

# override to not make acts_as_defensio submit articles
# not sure if this is good, override needed to be able to to create new pages
module Defensio
  module ActsAs
    module ClassMethods
      def acts_as_defensio(type, options={})
        return unless ENV['RAILS_ENV']
        include InstanceMethods
        
        case type
        when :comment
          after_create :audit_comment
        end
        
        @defensio_type = type
        self.defensio_options = options
        @defensio = Defensio::Client.new(@defensio_options)
        
        unless defensio_options.has_key?(:validate_key) && !defensio_options[:validate_key]
          begin
            @defensio.validate_key.success?
          rescue
            RAILS_DEFAULT_LOGGER.info "\n** Unable to validate defensio key, #{$!}\n"
          end
        end      end
      def defensio_fields(field)
        if @defensio_options and @defensio_options[:fields] and @defensio_options[:fields][field]
          @defensio_options[:fields][field]
        else
          field
        end
      end
    end
  end
end

module MiniMagick
  class Image
    def initialize(input_path, tempfile=nil)
      ENV['PATH'] = "/usr/local/bin:/usr/bin:/bin:/opt/bin"
      @path = input_path
      @tempfile = tempfile 
      run_command("identify", @path)
    end
    
    def write(output_path)
      FileUtils.move @path, output_path
      run_command "identify", output_path # Verify that we have a good image
    end
    
    def destroy
      File.unlink(@path) if File.exists?(@path)
      @tempfile = nil
    end
  end
end