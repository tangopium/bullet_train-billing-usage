module Billing::Limiter::Base
  extend ActiveSupport::Concern
  include ActiveModel::Model

  def initialize(parent)
    @parent = parent
  end

  def broken_hard_limits_for(action, model, count: 1)
    broken_limits_for(action, model, enforcement: "hard", count: count)
  end

  def broken_soft_limits_for(action, model, count: 1)
    broken_limits_for(action, model, enforcement: "soft", count: count)
  end

  def can?(action, model, count: 1)
    return true unless billing_enabled?
    broken_hard_limits_for(action, model, count: count).empty?
  end

  def current_products
    Billing::Usage::ProductCatalog.new(@parent).current_products
  end

  def exhausted?(model, enforcement = "hard")
    return false unless billing_enabled?

    broken_limits_for(:have, model, enforcement: enforcement.to_s, count: 1).any?
  end

  def hard_limits_for(action, model)
    limits_for(action, model).select { |limit| limit["enforcement"] == "hard" }
  end

  def limits_for(action, model)
    # Collect any relevant limits from all active products.
    current_products.map do |product|
      limits = product.respond_to?(:limits) && product.limits.present? ? (product.limits[model.name.underscore.pluralize] || {}) : {}
      limits.each do |action, limit|
        limit["product_id"] = product.id
      end
      limits
    end.compact.map do |limits_by_action|
      limits_by_action[action.to_s]
    end.compact
  end

  private

  def broken_limits_for(action, model, enforcement:, count: 1)
    limits = enforced_limits_for(action, model, enforcement: enforcement).map do |limit|
      if (exhausted_usage = exhausted_usage_for(limit, action, model, count: count))
        # We notate the action here because `:create` ends up aggregating broken limits for both `:create` and `:have`.
        {action: action, usage: exhausted_usage, limit: limit}
      end
    end.compact

    # If we're checking whether we can create something, we also need to check if it can exist.
    if action == :create
      limits += broken_limits_for(:have, model, enforcement: enforcement, count: count)
    end

    limits
  end

  def collection_for(model)
    model.name.underscore.tr("/", "_").pluralize.underscore.to_sym
  end

  def enforced_limits_for(action, model, enforcement:)
    limits_for(action, model).select { |limit| limit["enforcement"].to_s == enforcement.to_s }
  end

  def exists_count_for(model)
    @parent.send(collection_for(model)).billable.count
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

  def usage_for(action, model, duration, interval)
    @parent.billing_usage_trackers.current.detect do |tracker|
      tracker.duration == duration && tracker.interval == interval
    end&.usage&.dig(model.name, action.to_s.verb.conjugate(tense: :past))
  end
end
