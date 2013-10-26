# encoding: utf-8
# The above is a 'magic encoding' that ensures support for special characters
# like umlauts in strings contained in this file.

module Jekyll
  module Tags
    class QuickManTag < Liquid::Tag
      
      def initialize(tag_name, section_page_provider, tokens)
        @section, @page, @provider = section_page_provider.split
        @provider = @provider || ''
        super
      end

      def render(context)
        generate_anchor(context.registers[:site].config['man'])
      end
      
      def generate_anchor(man)
        description = determine_description(man)
        title = "#{@provider} Manpage zu#{determine_type} '#{@page}#{description}'"
        
        href = determine_url
        
        "<a title=\"#{title}\" href=\"#{href}\">#{@page}(#{@section})</a>"
      end

			def determine_description_via_whatis
				man_path = "--manpath=`manpath --quiet --global`"
				section = @section ? "--section #{@section}" : ''
				# locale = "--locale=de"
				thats_it = `whatis #{man_path} #{section} --long --systems=#{@provider},man #{@page} 2> /dev/null`

				if thats_it
					description = " - #{thats_it.split(/\) +-+ +/).last}"
					description.gsub!(/\n\Z/,'')
				end

				description || nil
			end
      
      def determine_description_via_config(man)
        if man
			    man_page = man[@page]
					
					if man_page
						if man_page.is_a?(Hash) && man_page.has_key?(@section.to_i)
							# support for yaml paths like man.termios.4
							description = " - #{man_page[@section.to_i]}"
						else
							# support for yaml paths like man.ssh
							description = " - #{man_page}"
						end
					else
					  p "WARNING: Missing man page for '#{@page}'. Links will be generated without man descriptions."
					end

				else
					p 'WARNING: Zero man pages defined in config file. Links will be generated without man descriptions.'
				end
        
        description || ''
			end

      def determine_description(man)
			  description = determine_description_via_whatis

				unless description
					p "whatis failed to find a descripton for #{@page}. Trying config file as a fall back ..."
					description = determine_description_via_config(man)
				end

				description || ''
			end


      def determine_type
        if @provider.downcase.eql? 'ubuntu'
          get_type_linux
        else
          get_type_bsd
        end
      end
      
      def get_type_linux
        case @section.to_i
          when 1
            'm Befehl'
          when 2
            'm Systemaufruf'
          when 3
            'm Bibliotheksaufruf'
          when 4
            'r Spezialdatei'
          when 5
            'm Dateiformat/zur Konvention'
          when 6
            'm Spiel'
          when 8
            'm Systemverwaltungsbefehl'
          when 9
            'r Kernel-Routine'
        else
            # 7 Verschiedenes (einschließlich Makropaketen und Konventionen), z. B. man(7), groff(7)
            ''
        end
      end
      
      def get_type_bsd
        case @section.to_i
          when 1
            'm Benutzerkommando'
          when 2
            'Systemaufruf oder Fehlernummer'
          when 3
            'm Bibliotheksaufruf'
          when 4
            ' Gerätetreiber'
          when 5
            'm Dateiformat/zur Konvention'
          when 6
            'm Spiel'
          when 8
            'm Systemverwaltungskommando'
          when 9
            'r Kernel-Entwicklerhilfe'
        else
          # 7 Verschiedene Informationen
          ''
        end
      end
      
      def determine_url
        case @provider.downcase
          when 'ubuntu'
            "http://manpages.ubuntu.com/manpages/#{@page}.#{@section}"
          else
            "http://www.freebsd.org/cgi/man.cgi?query=#{@page}&apropos=0&sektion=#{@section}&arch=default&format=latin1"
        end
      end
      
    end
  end
end

Liquid::Template.register_tag('man', Jekyll::Tags::QuickManTag)
