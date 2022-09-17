class Billing::Limiter
  include ActiveModel::Model

  def initialize(team)
    @team = team
  end

  def current_products
    products = @team.billing_subscriptions.active.map(&:included_prices).flatten.map(&:price).map(&:product)
    products.any? ? products : [Billing::Product.find(:free)]
  end

  def collection_for(model)
    model.name.underscore.tr("/", "_").pluralize.underscore.to_sym
  end

  def exists_count_for(model)
    @team.send(collection_for(model)).billable.count
  end

  def usage_for(action, model, duration, interval)
    @team.current_billing_usage_trackers.detect do |tracker|
      tracker.duration == duration && tracker.interval == interval
    end&.usage&.dig(model.name, action.to_s.verb.conjugate(tense: :past))
  end

  def exhausted_usage_for(limit, action, model, count: 0)
    current_count = if action == :have
      exists_count_for(model)
    else
      usage_for(action, model, limit["duration"], limit["interval"])
    end

    return nil unless current_count

    current_count + count > limit["count"] ? current_count : nil
  end

  def limits_for(action, model)
    # Collect any relevant limits from all active products.
    current_products.map do |product|
      limits = product.limits[model.name.underscore.pluralize]
      limits.each do |action, limit|
        limit["product_id"] = product.id
      end
      limits
    end.compact.map do |limits_by_action|
      limits_by_action[action.to_s]
    end.compact
  end

  def hard_limits_for(action, model)
    limits_for(action, model).select { |limit| limit["enforcement"] == "hard" }
  end

  # Returns a copy of any limits that would be broken by an action (and the current usage).
  def broken_hard_limits_for(action, model, count: 1)
    hard_limits = hard_limits_for(action, model).map do |limit|
      if (exhausted_usage = exhausted_usage_for(limit, action, model, count: count))
        # We notate the action here because `:create` ends up aggregating broken limits for both `:create` and `:have`.
        {action: action, usage: exhausted_usage, limit: limit}
      end
    end.compact

    # If we're checking whether we can create something, we also need to check if it can exist.
    if action == :create
      hard_limits += broken_hard_limits_for(:have, model, count: count)
    end

    hard_limits
  end

  def can?(action, model, count: 1)
    return true unless billing_enabled?
    broken_hard_limits_for(action, model, count: count).empty?
  end

  def exhausted?(model)
    return false unless billing_enabled?
    broken_hard_limits_for(:have, model, count: 0).any?
  end
end
