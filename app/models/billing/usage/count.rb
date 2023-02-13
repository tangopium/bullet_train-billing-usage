class Billing::Usage::Count < BulletTrain::Billing::Usage.base_class.constantize
  belongs_to :tracker
end
