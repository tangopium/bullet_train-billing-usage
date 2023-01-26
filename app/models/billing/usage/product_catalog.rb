class Billing::Usage::ProductCatalog
  def initialize(parent)
    @parent = parent
  end

  def current_products
    products = parent.team.billing_subscriptions.active.map(&:included_prices).flatten.map(&:price).map(&:product)
    products.any? ? products : free_products
  end

  def free_products
    [Billing::Product.find(:free)]
  end

  protected

  def parent
    @parent
  end
end
