
module Caboose
  class RichTextBlockParser
    
    def self.parse(block, html, domain)
      
      html = html.strip
      page = Nokogiri::HTML("<div>#{html}</div>")
      if page.css('div').children.count == 1
        block.value = html
        block.save
        return block
      end
      
      nodes = []
      page.css('div').children.each do |node|
        case node.name.downcase
          when 'h1'    then nodes << node           
          when 'h2'    then nodes << node
          when 'h3'    then nodes << node
          when 'h4'    then nodes << node
          when 'h5'    then nodes << node
          when 'h6'    then nodes << node
          when 'p'     then
            str = node.inner_html.strip
            nodes << node if str.length > 0 && str != "&#160;" && str != "&nbsp;"
          when 'ul'    then nodes << node
          when 'div'   then nodes << node
          when 'a'     then nodes << node
          when 'img'   then nodes << node
          when 'table' then nodes << node
        end                    
      end
      
      # Increment the sort order of any blocks after the current one                
      sort_order = block.sort_order + nodes.count                
      block.parent.children.where('sort_order > ?', block.sort_order).reorder(:sort_order).all.each do |b2|
        b2.sort_order = sort_order
        b2.save
        sort_order = sort_order + 1                  
      end
      
      # Now add all the new blocks
      sort_order = block.sort_order
      new_first_block_id = false
      paragraphs = []
      nodes.each do |node|
        b = Block.create(   
          :page_id       => block.page_id,              
          :parent_id     => block.parent_id,
          :sort_order    => sort_order
        )
        if sort_order == block.sort_order
          new_first_block_id = b.id
        end
        
        case node.name.downcase
          when 'h1'
            b.block_type_id = BlockType.where(:name => 'heading').first.id
            b.save            
            b.create_children            
            b.child('size').update_attribute(:value, 1)                        
            b.child('text').update_attribute(:value, node.inner_html)            
          when 'h2'
            b.block_type_id = BlockType.where(:name => 'heading').first.id
            b.save            
            b.create_children            
            b.child('size').update_attribute(:value, 2)                        
            b.child('text').update_attribute(:value, node.inner_html)
          when 'h3'
            b.block_type_id = BlockType.where(:name => 'heading').first.id
            b.save            
            b.create_children            
            b.child('size').update_attribute(:value, 3)                        
            b.child('text').update_attribute(:value, node.inner_html)
          when 'h4'
            b.block_type_id = BlockType.where(:name => 'heading').first.id
            b.save            
            b.create_children            
            b.child('size').update_attribute(:value, 4)                        
            b.child('text').update_attribute(:value, node.inner_html)
          when 'h5'
            b.block_type_id = BlockType.where(:name => 'heading').first.id
            b.save            
            b.create_children            
            b.child('size').update_attribute(:value, 5)                        
            b.child('text').update_attribute(:value, node.inner_html)
          when 'h6'
            b.block_type_id = BlockType.where(:name => 'heading').first.id
            b.save            
            b.create_children            
            b.child('size').update_attribute(:value, 6)                        
            b.child('text').update_attribute(:value, node.inner_html)
          when 'p'
            b.block_type_id = BlockType.where(:name => 'richtext').first.id
            b.value = node.to_s                        
            b.save
            paragraphs << b
          when 'ul'
            b.block_type_id = BlockType.where(:name => 'richtext').first.id
            b.value = node.to_s                        
            b.save
          when 'div'
            b.block_type_id = BlockType.where(:name => 'richtext').first.id
            b.value = node.to_s                        
            b.save
          when 'a'
            b.block_type_id = BlockType.where(:name => 'richtext').first.id
            b.value = "<p>#{node.to_s}</p>"                        
            b.save
          when 'img'
            b.block_type_id = BlockType.where(:name => 'richtext').first.id
            b.value = node.to_s                        
            b.save
          when 'table'
            b.block_type_id = BlockType.where(:name => 'richtext').first.id
            b.value = node.to_s                        
            b.save            
        end                    
        sort_order = sort_order + 1
      end
      
      paragraphs.each do |p|
        self.parse_paragraph(p, domain)
      end
      
      # Now delete the original block      
      block.destroy
      block = Block.find(new_first_block_id)
      return block

    end
    
    def self.parse_paragraph(block, domain)
            
      page = Nokogiri::HTML(block.value)
      return if page.css('img').count == 0
      
      image_count = page.css('img').count
      sort_order = block.sort_order
      
      # Increment the sort order of any blocks after and including the current one      
      i = 0
      block.parent.children.where('sort_order >= ?', block.sort_order).reorder(:sort_order).all.each do |b2|
        b2.sort_order = sort_order + image_count + i
        b2.save
        i = i + 1                  
      end
      
      # Create blocks for each image
      i = 0
      image_block_type_id = BlockType.where("name = ? and parent_id is null", 'image').first.id
      page.css('img').each do |node|
        b = Block.create(          
          :page_id       => block.page_id,              
          :parent_id     => block.parent_id,
          :block_type_id => image_block_type_id,
          :sort_order    => sort_order + i
        )
        b.create_children
        
        # Set the alignment
        if node['align'] && node['align'].length > 0
          align = node['align']
          align[0] = align[0].capitalize
          b.child('align').update_attribute(:value, align)
        end
        
        # Download the image
        src = node['src']
        src = "http://#{domain}#{src}" if src.starts_with?('/')        
        img = b.child('image_src')
        img.image = URI.parse(src)
        img.save
        
        #b.child('image_style'   ).update_attribute(:value, )
        #b.child('link'          ).update_attribute(:value, )
        #b.child('width'         ).update_attribute(:value, )
        #b.child('height'        ).update_attribute(:value, )
        #b.child('margin_top'    ).update_attribute(:value, )
        #b.child('margin_bottom' ).update_attribute(:value, )
        #b.child('margin_right'  ).update_attribute(:value, )
        #b.child('margin_left'   ).update_attribute(:value, )
                     
        i = i + 1        
      end
      
      # Now remove any images from the paragraph
      page.search('.//img').remove
      block.value = page.to_s
      block.save
      
    end
  end
end
