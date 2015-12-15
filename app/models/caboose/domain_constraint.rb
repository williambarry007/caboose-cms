class Caboose::DomainConstraint
  def initialize(domain)
    @domains = [domain].flatten
  end

  def matches?(request)
    return @domains.include?(request.host)        
  end
end
