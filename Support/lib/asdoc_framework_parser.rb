require "rexml/document"
require "#{ENV['TM_SUPPORT_PATH']}/lib/escape"
require "#{ENV['TM_BUNDLE_SUPPORT']}/lib/asdoc_tidy"

# This class takes the asdoc generated all-classes.html file and 
# parses into object that can be outputted for use within TextMate's
# Bundle system, and for further finer grained parsing (see the
# AsdocClassParser)
class AsdocFrameworkParser
    
    LINK_X_PATH = "html/body/table/tr/td/a"
    NAME_X_PATH = "html/head/title"
    
    private
    
    def initialize
        @class_path_list = []
        @doc_path_list = []
        @framework_name = "unknown"
        @package_filter = /^/
		@logging_enabled = false
    end
    
    public
    
    # Getter/Setters
    
    def class_path_list
        @class_path_list
    end

	def doc_path_list
		@doc_path_list
	end

	def package_filter=(rg)
		@package_filter = rg
	end
	
	def logging_enabled=(boo)
		@logging_enabled = boo
	end
    
    # Commands
    
    # Load the all-classes.html document and create
    # a list of it's contents.    
    def load_framework all_classes_html

        @base_uri = File.dirname all_classes_html

        html = AsdocTidy.clean_for_rexml(all_classes_html)        

        class_doc = REXML::Document.new html

        # TODO: Class path level filtering.
        class_doc.elements.each( LINK_X_PATH ) do |tag|
            class_href = tag.attributes['href'].to_s
            if class_href =~ @package_filter
                @class_path_list.push( @base_uri+"/"+class_href )
                @doc_path_list.push( tag.to_s.gsub( /\<\/?i\>/, '' ) )
                log( "Adding Class " + File.basename( class_href ) )
            end
        end

        class_doc.elements.each( NAME_X_PATH ) do |tag|            
            begin
                # All Classes - ActionScript 3.0 Language and Components Reference
                # All Classes \- \b(\w+)\b API Documentation
                title_match = /All Classes \- \b(\w+)\b/            
                @framework_name = title_match.match( tag[0].to_s )[1].downcase                
            rescue Exception => e
                puts e.to_s
            end
        end
                
    end
    
    # Generates an asdoc dictionary list file this can be used
    # by asdoc.rb search script.
    def asdoc_dictionary
        
        return nil if @class_path_list.empty?
        
        xml =  '<?xml version="1.0" encoding="UTF-8"?>'
        xml += "\n<dict>\n"

        #TODO: Refactor to use single path array by reconstructing original 
		#path here.
        @doc_path_list.each do |tag|
            xml += "\t"+tag+"\n"
        end

        xml += '</dict>'
        
    end
    
    # The name of the framework as parsed from the html title.
    def framework_name
        @framework_name
    end
	
	# Log output.
	def log( message )
		if @logging_enabled
			require 'syslog'

      Syslog.open('as3-bundle-gen')
      Syslog.crit(message)
      Syslog.close()			
		end
	end

end