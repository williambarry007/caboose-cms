require 'nokogiri'
require 'nokogiri-styles'

module Caboose
  class BlockTypeParser
    
    def BlockTypeParser.parse_html(str, tags, children = nil)

      doc = Nokogiri::HTML.fragment(str)            
      doc.children.first.set_attribute('id', "block_<%= block.id %>")

      count = 0
      rf_header = []
      rf_body = "#{doc.to_html}"      
      new_children = []
      tags.each do |tag|        
        case tag
          when 'heading'
            
            headings = doc.search('h1') + doc.search('h2') + doc.search('h3') + doc.search('h4') + doc.search('h5') + doc.search('h6')            
            headings.each_with_index do |h, i|
              
              info = children ? (children[count] ? children[count] : (children[count.to_s] ? children[count.to_s] : nil)) : nil
              description = info && info['description'] ? info['description'] : "#{(i+1).ordinalize} Heading"
              name        = info && info['name']        ? info['name']        : description.downcase.gsub(' ', '_')
              
              cv = StdClass.new
              cv.heading_text = h.text	                
	            cv.size          = h.name.gsub('h','').to_i
              cv.align         = h.attributes['align'].to_s if h.attributes['align']
              cv.extra_classes = h.attributes['class'].to_s if h.attributes['class']
              if h['style']
                cv.align         = h.styles['text-align'] if h.styles['text-align']
	              cv.color         = h.styles['color']      if h.styles['color']
	              cv.margin_bottom = h.styles['margin-bottom'] if h.styles['margin-bottom']
	              cv.margin_top    = h.styles['margin-top']    if h.styles['margin-top']
	              cv.underline     = true if h.styles['text-decoration']
	            end

              v = StdClass.new({              
                :name         => name,
                :description  => description,
                :field_type   => 'heading',
                :child_values => cv
              })
                            
              rf_body.gsub!(h.to_s, "<%= block.render('#{name}') %>")              
              new_children << v              
                              
              count = count + 1              
            end
            
          when 'link'
            
            links = doc.search('a')            
            links.each_with_index do |link, i|
              
              info = children ? (children[count] ? children[count] : (children[count.to_s] ? children[count.to_s] : nil)) : nil
              description = info && info['description'] ? info['description'] : "#{(i+1).ordinalize} Link"
              name        = info && info['name']        ? info['name']        : description.downcase.gsub(' ', '_')

              cv = StdClass.new
              cv.text          = link.text
              cv.align         = link.attributes['align'  ].to_s if link.attributes['align'  ]
              cv.target        = link.attributes['target' ].to_s if link.attributes['target' ]
              cv.url           = link.attributes['href'   ].to_s if link.attributes['href'   ]
	            cv.extra_classes = link.attributes['class'  ].to_s if link.attributes['class'  ]
	            if link['style']
                cv.align         = link.styles['text-align'   ] if link.styles['text-align'    ]
	              cv.color         = link.styles['color'        ] if link.styles['color'         ]
	              cv.margin        = link.styles['margin'       ] if link.styles['margin-bottom' ]
	              cv.margin_top    = link.styles['margin-top'   ] if link.styles['margin-top'    ]
	              cv.margin_bottom = link.styles['margin-bottom'] if link.styles['margin-bottom' ]	              
	              cv.margin_left   = link.styles['margin-left'  ] if link.styles['margin-left'   ]
	              cv.margin_right  = link.styles['margin-right' ] if link.styles['margin-right'  ]	              
	            end

              v = StdClass.new({              
                :name         => name,
                :description  => description,
                :field_type   => 'button',
                :child_values => cv
              })
                            
              rf_body.gsub!(link.to_s, "<%= block.render('#{name}') %>")              
              new_children << v              
                              
              count = count + 1              
            end

          when 'richtext'
            
            paragraphs = doc.search('p')            
            paragraphs.each_with_index do |p, i|
              
              info = children ? (children[count] ? children[count] : (children[count.to_s] ? children[count.to_s] : nil)) : nil
              description = info && info['description'] ? info['description'] : "#{(i+1).ordinalize} Richtext"
              name        = info && info['name']        ? info['name']        : description.downcase.gsub(' ', '_')

              v = StdClass.new({              
                :name         => name,
                :description  => description,
                :field_type   => 'richtext',
                :default      => p.text                
              })
                            
              rf_body.gsub!(p.to_s, "<%= block.render('#{name}') %>")              
              new_children << v              
                              
              count = count + 1              
            end
                        
          when 'img'
            
            images = doc.search('img')            
            images.each_with_index do |img, i|
              
              info = children ? (children[count] ? children[count] : (children[count.to_s] ? children[count.to_s] : nil)) : nil
              description = info && info['description'] ? info['description'] : "#{(i+1).ordinalize} Image"
              name        = info && info['name']        ? info['name']        : description.downcase.gsub(' ', '_')
              
              cv = StdClass.new              
	            cv.image_src	    = img.attributes['src'    ].to_s
	            cv.alt_text	      = img.attributes['alt'    ].to_s if img.attributes['alt'    ]
	            cv.width	        = img.attributes['width'  ].to_s if img.attributes['width'  ]
	            cv.height	        = img.attributes['height' ].to_s if img.attributes['height' ]	            
	            cv.width          = img.styles['width'         ] if img.styles['width'         ]
	            cv.height         = img.styles['height'        ] if img.styles['height'        ]	            
	            cv.align          = img.styles['float'         ] if img.styles['float'         ]
	            cv.margin_bottom  = img.styles['margin-bottom' ] if img.styles['margin-bottom' ]
	            cv.margin_left    = img.styles['margin-left'   ] if img.styles['margin-left'   ]
	            cv.margin_right   = img.styles['margin-right'  ] if img.styles['margin-right'  ]
	            cv.margin_top     = img.styles['margin-top'    ] if img.styles['margin-top'    ]
	            
	            Caboose.log(cv)

              v = StdClass.new({              
                :name         => name,
                :description  => description,
                :field_type   => 'image2',
                :child_values => cv
              })
                            
              rf_body.gsub!(img.to_s, "<%= block.render('#{name}') %>")              
              new_children << v              
                              
              count = count + 1              
            end
            
        end
      end

      render_function = ""
      render_function << "<%\n#{rf_header.join("\n")}\n%>\n" if rf_header.count > 0
      render_function << rf_body
      
      return {
        :original_html => str,
        :render_function => render_function,
        :children => new_children
      }                                    
    end
    
    def BlockTypeParser.parse(str)
      
      vars = {}
      pattern = /<%= \|(.*?)\| %>/
      new_lines = []
      lines = str.split("\n")
      lines.each do |line|        
        matches = line.to_enum(:scan, pattern).map{$&}
        if matches
          matches.each do |match|
            next if match.nil? || match.length == 0                        
            arr = match[5..-5].split('|')
                        
            name        = arr.count > 0 ? arr[0] : nil
            description = arr.count > 1 ? arr[1] : nil
            field_type  = arr.count > 2 ? arr[2] : nil
            default     = arr.count > 3 ? arr[3] : nil
            default = default && ((default.starts_with?('"') && default.ends_with?('"')) || (default.starts_with?("'") && default.ends_with?("'"))) ? default[1..-2] : nil 
            
            if vars[name.to_sym].nil?
              vars[name.to_sym] = StdClass.new({
                :name        => name        ,        
                :description => description ,
                :field_type  => field_type  ,
                :default     => default
              })            
            end
            line.gsub!(match, "<%= #{name} %>")          
          end
        end
        new_lines << line
      end
      
      str2 = "<%\n"
      vars.each do |k,var|
        str2 << "#{var.name} = block.child_value('#{var.name}')\n"                        
      end
      str2 << "\n"
      vars.each do |k,var|                
        str2 << "#{var.name} = \"#{var.default.gsub('"', '\"')}\" if #{var.name}.nil? || #{var.name}.length == 0\n" if var.default        
      end
      str2 << "%>\n"
      str2 << new_lines.join("\n")      
      return str2                  
    end
    
  end
end
