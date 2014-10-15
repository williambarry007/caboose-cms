module Caboose
  class TaxCalculator
    def self.tax_rate(address)
      ap '--HOOK calculate tax'
      return 0 if address.state.downcase != 'al'
      city = address.city.downcase
      rate = 0.00
      rate = rate + 0.05 if city == 'brookwood'  
      rate = rate + 0.05 if city == 'coaling'    
      rate = rate + 0.05 if city == 'coker'      
      rate = rate + 0.05 if city == 'holt'       
      rate = rate + 0.05 if city == 'holt CDP'   
      rate = rate + 0.05 if city == 'lake View'  
      rate = rate + 0.05 if city == 'moundville' 
      rate = rate + 0.05 if city == 'northport'  
      rate = rate + 0.05 if city == 'tuscaloosa' 
      rate = rate + 0.05 if city == 'vance'      
      rate = rate + 0.05 if city == 'woodstock'  
      rate = rate + 0.04 if address.state.downcase == 'al' || address.state.downcase == 'alabama'        
      return rate.round(2)
    end
  end
end
