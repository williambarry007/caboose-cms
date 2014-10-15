require 'json'

module Caboose
  class SearchFilter < ActiveRecord::Base
    self.table_name = 'store_search_filters'
    
    attr_accessible :id,
      :url,
      :title_like,
      :search_like,
      :category_id,
      :category,
      :vendors,
      :option1,
      :option2,
      :option3,
      :prices
      
    before_save :json_encode
    after_initialize :json_decode
    
    def json_encode
      self.category = self.category.to_json if not self.category.nil?
      self.vendors  = self.vendors.to_json  if not self.vendors.nil?
      self.option1  = self.option1.to_json  if not self.option1.nil?
      self.option2  = self.option2.to_json  if not self.option2.nil?
      self.option3  = self.option3.to_json  if not self.option3.nil?
      self.prices   = self.prices.to_json   if not self.prices.nil?
    end
    
    def json_decode
      self.category = JSON.parse(self.category) if not self.category.nil?
      self.vendors  = JSON.parse(self.vendors)  if not self.vendors.nil?
      self.option1  = JSON.parse(self.option1)  if not self.option1.nil?
      self.option2  = JSON.parse(self.option2)  if not self.option2.nil?
      self.option3  = JSON.parse(self.option3)  if not self.option3.nil?
      self.prices   = JSON.parse(self.prices)   if not self.prices.nil?
    end
    
    def self.exclude_params_from_url(url, exclude_params = nil)
      return url if exclude_params.nil? || exclude_params.count == 0
      
      url2 = "#{url}"
      url2[0] = '' if url2.starts_with?('/')
      
      if Caboose.use_url_params
        arr = url2.split('/')
        arr2 = []
        i = arr.count - 1
        while i >= 1 do
          k = arr[i-1]
          v = arr[i]
          arr2 << "#{k}/#{v}" if !exclude_params.include?(k)
          i = i - 2
        end
        arr2 << arr[0] if i == 0
        url2 = arr2.reverse.join('/')
      else
        # TODO: Handle removing parameters from the querystring
      end        
      
      url2 = "/#{url2}" if !url2.starts_with?('/')
      return url2
    end
    
    def self.find_from_url(url, pager, exclude_params=nil)
      
      # Filter any specified parameters from the url
      filtered_url = self.exclude_params_from_url(url, exclude_params)
      
      # If the search filter already exists pass it back
      # return SearchFilter.where(url: pager.options['base_url']) if SearchFilter.exists?(url: pager.options['base_url'])
      
      # Create a new search filter
      search_filter     = SearchFilter.new
      search_filter.url = filtered_url
      
      search_filter.category_id = if pager.params['category_id'].kind_of?(Array)
        pager.params['category_id'].first
      else
        pager.params['category_id']
      end
      
      # Grab the category NOTE: A category id is required
      category = Category.find(search_filter.category_id)
      
      # Define the category info
      search_filter.category         = Hash.new
      search_filter.category['id']   = category.id
      search_filter.category['name'] = category.name
      
      # Define children categories info
      search_filter.category['children'] = category.children.collect do |child_category|
        child         = Hash.new
        child['id']   = child_category.id
        child['name'] = child_category.name
        child['url']  = child_category.url
        
        child
      end
      
      # Initialize option hashes
      option1 = { 'name' => [], 'values' => [] }
      option2 = { 'name' => [], 'values' => [] }
      option3 = { 'name' => [], 'values' => [] }
      
      # Default min an max values
      min = 0.0
      max = 1000000.0
      
      # Set price ranges
      price_ranges = [
        [    1,    10],
        [   10,    25],
        [   25,    50],
        [   50,    75],
        [   75,   100],
        [  100,   150],
        [  150,   200],
        [  200,   250],
        [  250,   300],
        [  300,   400],
        [  400,   500],
        [  500,  1000],
        [ 1000,  2000],
        [ 2000,  3000],
        [ 4000,  5000],
        [ 7000,  7500],
        [ 7500, 10000],
        [10000, 50000]
      ]
      
      # Create an array of the same length as the price ranges to hold a match count
      price_range_matches = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
      
      # Array to hold all relevant vendor IDs
      vendor_ids = []
      
      # Iterate over pager results for product and variant info
      pager.all_items.each do |product|
        option1['name'] << product.option1
        option2['name'] << product.option2
        option3['name'] << product.option3
        
        product.variants.each do |variant|
          option1['values'] << variant.option1.strip if !variant.option1.nil?
          option2['values'] << variant.option2.strip if !variant.option2.nil?
          option3['values'] << variant.option3.strip if !variant.option3.nil?
          
          # Iterate over price ranges
          price_ranges.each_with_index do |price_range, index|
            min = price_range.first
            max = price_range.last
            
            # Skip to next variant if the price isnt defined or is less than $1
            next if variant.price.nil? || variant.price < 1
            
            # Increment price count at index if the varaint is within the price range
            if variant.price > min and variant.price < max
              price_range_matches[index] += 1
              vendor_ids << product.vendor_id
            end
          end
        end
      end
      
      # Grab all active vendors
      search_filter.vendors = Vendor.where('id IN (?) AND status = ?', vendor_ids.uniq, 'Active')
      
      # Remove nil and duplicate values from option name arrays
      option1['name'] = option1['name'].compact.uniq
      option2['name'] = option2['name'].compact.uniq
      option3['name'] = option3['name'].compact.uniq
      
      # ?? If option name array have exactly 1 value then set the search filter's option values
      search_filter.option1 = if option1['name'].count == 1 then { 'name' => option1['name'][0], 'values' => option1['values'].compact.uniq.sort } else nil end
      search_filter.option2 = if option2['name'].count == 1 then { 'name' => option2['name'][0], 'values' => option2['values'].compact.uniq.sort } else nil end
      search_filter.option3 = if option3['name'].count == 1 then { 'name' => option3['name'][0], 'values' => option3['values'].compact.uniq.sort } else nil end
      
      # Get all price ranges that have matches
      search_filter.prices = price_range_matches.collect.with_index { |matches, index| price_ranges[index] if matches > 0 }.compact
      
      # Inject the search filter into the database
      # search_filter.save
      
      # Finally, return the filter; NOTE: find out of the database so the hashes get serialized correctly
      # SearchFilter.find(search_filter.id)
      return search_filter
    end
  end
end
