class Caboose::DomainConstraint
  def initialize(domains)
    @domains = domains.is_a?(Array) ? domains.flatten : [domains].flatten
  end

  def matches?(request)
    m = false
    @domains.each do |d|
      if request.host =~ /#{d.gsub("\\","\\\\")}/
        m = true
        break
      end
    end
    return m              
    #return @domains.include?(request.host)     
  end
end
