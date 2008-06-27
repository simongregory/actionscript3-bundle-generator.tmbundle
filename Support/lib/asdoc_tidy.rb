#Simple wrapper to Run tidy over asdoc generated html.
require "#{ENV['TM_SUPPORT_PATH']}/lib/escape"

module AsdocTidy
    class << self

          # Cleans the HTML generated by the 
          # asdoc tool by fixing any html errors using tidy.
          def clean(file)

              result = `tidy -f /tmp/tm_tidy_errors \
                             -iq -utf8 \
                             -wrap 0 --tab-size 4 --indent-spaces 4 \
                             --indent yes \
                             -asxhtml --output-xhtml yes \
                             --show-body-only no \
                             --enclose-text yes \
                             --doctype strict \
              		         --indent-attributes yes \
                             --tidy-mark no \
                             #{e_sh(file)}`
                           
          end
          
          # As clean() but additionally removes the namespace 
          # that's injected by tidy as REXML has a bug in it 
          # and our XPath expressions fail (Ruby 1.8.6)
          def clean_for_rexml(path)
               result = clean(path).sub( 'xmlns="http://www.w3.org/1999/xhtml"', '' )
          end
    end
end