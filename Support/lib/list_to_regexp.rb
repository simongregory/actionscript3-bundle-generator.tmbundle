#!/usr/bin/env ruby

module ListToRegexp
    class << self
	
		#  process_list
		#  Created by Allan Odgaard on 2005-11-28.
		#  http://macromates.com/svn/Bundles/trunk/Bundles/Objective-C.tmbundle/Support/list_to_regexp.rb
		#
		#  Read list and output a compact regexp
		#  which will match any of the elements in the list
		#  Modified by Ciarån Walsh to accept a plain string array
		def process_list(list)
		  buckets = { }
		  optional = false

		  list.map! { |term| term.unpack('C*') }

		  list.each do |str|
		    if str.empty? then
		      optional = true
		    else
		      ch = str.shift
		      buckets[ch] = (buckets[ch] or []).push(str)
		    end
		  end

		  unless buckets.empty? then
		    ptrns = buckets.collect do |key, value|
		      [key].pack('C') + process_list(value.map{|item| item.pack('C*') }).to_s
		    end

		    if optional == true then
		      "(" + ptrns.join("|") + ")?"
		    elsif ptrns.length > 1 then
		      "(" + ptrns.join("|") + ")"
		    else
		      ptrns
		    end
		  end
		end
          
    end
end


