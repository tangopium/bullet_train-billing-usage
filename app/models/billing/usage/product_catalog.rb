class Billing::Usage::ProductCatalog
  def initialize(parent)
    @parent = parent
  end

  def self.all_products
    Billing::Product.all
  end

  def current_products
    products = parent.team.billing_subscriptions.active.map(&:included_prices).flatten.map(&:price).compact.map(&:product)
    products = parent.team.billing_subscriptions.active.map(&:product) if products.empty?
    products.any? ? products : free_products
  end

  # e.g. [[1, "day"], [5, "minutes"]]
  def cycles
    self.class.all_products
      .map(&:limits).compact.flatten
      .map(&:values).flatten # get the limits without the relationships
      .map(&:values).flatten # get the limites without the verbs
      .select { |limit| limit.key?("duration") }.map { |limit| [limit["duration"], limit["interval"]] }
      .uniq
  end

  def free_products
    [Billing::Product.find(:free)]
  end

  protected

  attr_reader :parent
end
