class Billing::Limiter
  include Billing::Limiter::Base

  def current_products
    products = @parent.team.billing_subscriptions.active.map(&:included_prices).flatten.map(&:price).map(&:product)
    products.any? ? products : [Billing::Product.find(:free)]
  end
end
