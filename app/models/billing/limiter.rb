class Billing::Limiter
  include Billing::Limiter::Base

  def current_products
    Billing::Usage::ProductCatalog.new(@parent).current_products
  end
end
